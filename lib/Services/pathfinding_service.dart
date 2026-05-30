import 'dart:math';
import '../Data/building_graph.dart';

//  Result model returned to the caller
class EvacuationPath {
  final List<String> nodeIds; // ordered node IDs from start → exit
  final double totalCost; // total weighted cost
  final int hazardScore; // sum of hazard levels along path
  final String exitNodeId; // which exit was chosen

  const EvacuationPath({
    required this.nodeIds,
    required this.totalCost,
    required this.hazardScore,
    required this.exitNodeId,
  });
}

//  Location input from evacuee form
//  floor    → "Ground" | "First" | "Second"
//  areaType → "room" | "corridor" | "stairs" | "door"
//  roomNumber → "R1", "R2", "C3", "STAIRS" etc.

class EvacueeLocation {
  final String floor;
  final String areaType;
  final String roomNumber;

  const EvacueeLocation({
    required this.floor,
    required this.areaType,
    required this.roomNumber,
  });
}

//  Internal A* node used during search

class _AStarNode implements Comparable<_AStarNode> {
  final String id;
  final double g; // cost from start
  final double h; // heuristic to goal
  final String? parent;

  double get f => g + h;

  const _AStarNode({
    required this.id,
    required this.g,
    required this.h,
    this.parent,
  });

  @override
  int compareTo(_AStarNode other) => f.compareTo(other.f);
}

//  PathfindingService

class PathfindingService {
  final BuildingGraph graph;

  // Hazard config
  static const int _hazardBlockThreshold = 2; // hazardLevel >= this → skip edge
  static const double _hazardWeightMultiplier = 3.0; // penalty per hazard level
  static const double _crowdWeightMultiplier =
      1.5; // penalty/bonus per crowd unit

  // Runtime state (updated via alerts / ARCore)
  final Set<String> _blockedNodes = {}; // node IDs marked blocked
  final Map<String, double> _crowdPressure = {}; // nodeId → crowd count

  // Adjacency cache: nodeId → list of (neighbourId, edge)
  late final Map<String, List<MapEntry<String, GraphEdge>>> _adj;

  // Node lookup cache
  late final Map<String, GraphNode> _nodeMap;

  PathfindingService(this.graph) {
    _buildCaches();
  }

  // ── Cache building ───────────────────────────
  void _buildCaches() {
    _nodeMap = {for (final n in graph.nodes) n.id: n};

    _adj = {};
    for (final n in graph.nodes) {
      _adj[n.id] = [];
    }

    for (final edge in graph.edges) {
      // Graph is treated as undirected (walk both ways)
      _adj[edge.from]?.add(MapEntry(edge.to, edge));
      _adj[edge.to]?.add(MapEntry(edge.from, edge));
    }
  }

  //  Floor prefix mapping
  //  Form input  →  Node ID prefix
  //  "Ground"    →  "G"
  //  "First"     →  "F1"
  //  "Second"    →  "F2"
  
  String _floorPrefix(String floor) {
    switch (floor.trim().toLowerCase()) {
      case 'ground':
        return 'G';
      case 'first':
        return 'F1';
      case 'second':
        return 'F2';
      default:
        return floor.trim().toUpperCase();
    }
  }

  // ─────────────────────────────────────────────
  //  Area type → graph node type mapping
  //  Form dropdown value  →  GraphNode.type value
  // ─────────────────────────────────────────────
  String _nodeType(String areaType) {
    switch (areaType.trim().toLowerCase()) {
      case 'room':
        return 'room_center';
      case 'corridor':
        return 'corridor';
      case 'stairs':
        return 'stairs';
      case 'door':
        return 'door';
      default:
        return areaType.trim().toLowerCase();
    }
  }

  //  PUBLIC: Resolve evacuee form input → node ID
  
  //  How node ID is built from form data:
  
  //  │ Floor    │ Area Type  │ Room No.   │ Expected Node ID     │
  
  //  │ Ground   │ room       │ R1         │ G_R1_C               │
  
  //  Strategy:
  //  1. Build candidate node ID from floor prefix + room number
  //  2. If room → append "_C" suffix (room_center convention)
  //  3. Search _nodeMap for exact match
  //  4. If not found → fuzzy search: floor match + type match + roomNumber in ID
  //  5. Returns null if no match found
  
  
  //  PUBLIC: Resolve evacuee form input → node ID
  

  //  Smart concatenation logic:
  //  User sirf number likhta hai → code baaki banata hai
  //
  //  Floor prefix map:
  //    "Ground" → "G"
  //    "First"  → "F1"
  //    "Second" → "F2"
  //
  //  Area type + number → node ID:

  //  │ Area Type │ Input  │ Result                          │

  //  │ room      │ "4"    │ G_R4_C / F1_R4_C / F2_R4_C      │
  //  │ corridor  │ "3"    │ G_C3   / F1_C3   / F2_C3        │ 
  //  │ stairs    │ (any)  │ G_STAIRS / F1_STAIRS / F2_STAIRS│
  //  │ door      │ "1"    │ G_R1_D1 / F1_R1_D1              │

  String? resolveNodeId(EvacueeLocation location) {
    final prefix = _floorPrefix(location.floor);
    final rawInput = location.roomNumber.trim();
    // Strip leading zeros: "04" → "4", "004" → "4", "4" → "4"
    final number = rawInput.replaceAll(RegExp(r'^0+'), '');
    final targetType = _nodeType(location.areaType);

    // ── Build candidate ID from floor + area type + number ──
    String candidateId;

    switch (targetType) {
      case 'room_center':
        // User types: "4" → F1_R4_C
        candidateId = '${prefix}_R${number}_C';
        break;

      case 'corridor':
        // User types: "3" → F1_C3
        candidateId = '${prefix}_C$number';
        break;

      case 'stairs':
        // Stairs have no number — always same pattern
        candidateId = '${prefix}_STAIRS';
        break;

      case 'door':
        // User types: "1" → F1_R1_D1 (try D1 first, fallback to D2)
        candidateId = '${prefix}_R${number}_D1';
        break;

      default:
        candidateId = '${prefix}_${number.toUpperCase()}';
    }

    // ── Direct match ──
    if (_nodeMap.containsKey(candidateId)) {
      return candidateId;
    }

    // ── Door fallback: try D2 if D1 not found ──
    if (targetType == 'door') {
      final d2 = '${prefix}_R${number}_D2';
      if (_nodeMap.containsKey(d2)) return d2;
    }

    // ── Last resort: fuzzy search ──
    // floor match + type match + number in ID
    if (number.isNotEmpty) {
      final fuzzy = graph.nodes.where((node) {
        final floorOk =
            node.floor.toLowerCase() == location.floor.trim().toLowerCase();
        final typeOk = node.type == targetType;
        final hasNumber =
            node.id.contains('_R$number') ||
            node.id.contains('_C$number') ||
            node.id.endsWith(number);
        return floorOk && typeOk && hasNumber;
      }).toList();

      if (fuzzy.isNotEmpty) {
        fuzzy.sort((a, b) => a.id.length.compareTo(b.id.length));
        return fuzzy.first.id;
      }
    }

    return null; // no match
  }

  //  PUBLIC: Resolve form input → run pathfinding
  //  One-call convenience method for the UI layer

  //  Returns EvacuationPath if route found
  //  Returns null if node cannot be resolved OR no path exists
  EvacuationPath? findPathFromFormInput(EvacueeLocation location) {
    final startNodeId = resolveNodeId(location);
    if (startNodeId == null) return null;
    return findBestEvacuationPath(startNodeId);
  }

  //  PUBLIC: Employee sends a hazard alert
  //  → that node + its direct neighbours are blocked
  void applyHazardAlert(String alertNodeId) {
    _blockedNodes.add(alertNodeId);

    // Block immediate neighbours too (danger zone radius = 1 hop)
    for (final entry in (_adj[alertNodeId] ?? [])) {
      _blockedNodes.add(entry.key);
    }
  }

  // Remove a previously set alert (hazard cleared)
  void clearHazardAlert(String alertNodeId) {
    _blockedNodes.remove(alertNodeId);

    // Only unblock a neighbour if it has no other blocked neighbour
    for (final entry in (_adj[alertNodeId] ?? [])) {
      final neighbourId = entry.key;
      if (neighbourId == alertNodeId) continue;

      final stillDangerous = (_adj[neighbourId] ?? []).any(
        (e) => _blockedNodes.contains(e.key),
      );

      if (!stillDangerous) {
        _blockedNodes.remove(neighbourId);
      }
    }
  }

  //  PUBLIC: ARCore SLAM sends crowd coordinates
  //  positions: list of {'x': ..., 'y': ...} from ARCore
  void updateCrowdFromARCore(List<Map<String, double>> positions) {
    _crowdPressure.clear();

    for (final pos in positions) {
      final double px = pos['x'] ?? 0;
      final double py = pos['y'] ?? 0;

      // Map each ARCore coordinate → nearest graph node
      String? nearestId;
      double nearestDist = double.infinity;

      for (final node in graph.nodes) {
        final d = _euclidean(px, py, node.x, node.y);
        if (d < nearestDist) {
          nearestDist = d;
          nearestId = node.id;
        }
      }

      if (nearestId != null) {
        _crowdPressure[nearestId] = (_crowdPressure[nearestId] ?? 0) + 1.0;
      }
    }
  }

  //  PUBLIC: Find best evacuation path
  //  startNodeId → where the evacuee currently is
  //  Returns top-1 safest path, or null if no path exists
  EvacuationPath? findBestEvacuationPath(String startNodeId) {
    // Exit nodes — marked as is_exit: true in building_graph.json
    final List<GraphNode> exits = graph.nodes.where((n) => n.isExit).toList();
    if (exits.isEmpty) return null;

    // Run A* toward every exit → collect all reachable paths
    final List<EvacuationPath> candidates = [];
    for (final exit in exits) {
      final path = _aStar(startNodeId, exit.id);
      if (path != null) candidates.add(path);
    }

    if (candidates.isEmpty) return null;

    // Sort by total cost (cost already encodes hazard + crowd adjustments)
    candidates.sort((a, b) => a.totalCost.compareTo(b.totalCost));

    // Top-3 computed internally; expose only best 1
    return candidates.first;
  }

  //  PRIVATE: A* search from startId → goalId
  EvacuationPath? _aStar(String startId, String goalId) {
    final goalNode = _nodeMap[goalId];
    if (goalNode == null) return null;

    final List<_AStarNode> open = [];
    final Map<String, double> gScore = {startId: 0};
    final Map<String, String?> cameFrom = {startId: null};
    final Set<String> closed = {};

    open.add(_AStarNode(id: startId, g: 0, h: _heuristic(startId, goalNode)));

    while (open.isNotEmpty) {
      open.sort();
      final current = open.removeAt(0);

      if (current.id == goalId) {
        return _reconstructPath(cameFrom, goalId, gScore[goalId]!);
      }

      if (closed.contains(current.id)) continue;
      closed.add(current.id);

      for (final entry in (_adj[current.id] ?? [])) {
        final neighbourId = entry.key;
        final edge = entry.value;

        if (closed.contains(neighbourId)) continue;
        if (_isEdgeImpassable(edge, neighbourId)) continue;

        final double edgeCost = _computeEdgeCost(edge, neighbourId);
        final double tentativeG =
            (gScore[current.id] ?? double.infinity) + edgeCost;

        if (tentativeG < (gScore[neighbourId] ?? double.infinity)) {
          gScore[neighbourId] = tentativeG;
          cameFrom[neighbourId] = current.id;

          open.add(
            _AStarNode(
              id: neighbourId,
              g: tentativeG,
              h: _heuristic(neighbourId, goalNode),
              parent: current.id,
            ),
          );
        }
      }
    }

    return null;
  }

  //  Edge passability check
  bool _isEdgeImpassable(GraphEdge edge, String neighbourId) {
    // 1. Edge explicitly blocked
    if (edge.blocked) return true;

    // 2. Edge hazard too high
    if (edge.hazardLevel >= _hazardBlockThreshold) return true;

    // 3. Destination node flagged by hazard alert
    if (_blockedNodes.contains(neighbourId)) return true;

    return false;
  }

  //  Edge cost = currentWeight + hazard penalty + crowd adjustment

  //  Crowd logic:
  //  │ Neighbour is EXIT    │ Crowd = good signal (log nikal rahy hain)│
  //  │                      │ → REDUCE cost (prefer this exit)         │
  //  │ Neighbour is non-exit│ Crowd = congestion (rasta jam gaya)      │
  //  │ (corridor/room/stair)│ → INCREASE cost (avoid this node)        │

  double _computeEdgeCost(GraphEdge edge, String neighbourId) {
    double cost = edge.currentWeight;

    // Hazard penalty
    if (edge.hazardLevel > 0) {
      cost += edge.hazardLevel * _hazardWeightMultiplier * edge.baseWeight;
    }

    // Crowd adjustment
    final crowd = _crowdPressure[neighbourId] ?? 0.0;
    if (crowd > 0) {
      final neighbourNode = _nodeMap[neighbourId];
      final isExit = neighbourNode?.isExit ?? false;

      if (isExit) {
        // People exiting safely → attractive route → lower cost
        // Clamp: cost never goes below 10% of baseWeight
        final discount = crowd * _crowdWeightMultiplier * edge.baseWeight;
        cost = (cost - discount).clamp(edge.baseWeight * 0.1, double.infinity);
      } else {
        // Corridor/stair congested → penalise → steer away
        cost += crowd * _crowdWeightMultiplier * edge.baseWeight;
      }
    }

    return cost;
  }

  //  Heuristic: Euclidean distance to goal (A* admissible)
  double _heuristic(String nodeId, GraphNode goal) {
    final node = _nodeMap[nodeId];
    if (node == null) return double.infinity;
    return _euclidean(node.x, node.y, goal.x, goal.y);
  }

  double _euclidean(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }

  //  Reconstruct ordered path from cameFrom map
  EvacuationPath _reconstructPath(
    Map<String, String?> cameFrom,
    String goalId,
    double totalCost,
  ) {
    final List<String> path = [];
    String? current = goalId;

    while (current != null) {
      path.add(current);
      current = cameFrom[current];
    }

    final orderedPath = path.reversed.toList();

    // Sum hazard levels across all edges in the path
    int hazardScore = 0;
    for (int i = 0; i < orderedPath.length - 1; i++) {
      final edge = _getEdge(orderedPath[i], orderedPath[i + 1]);
      if (edge != null) hazardScore += edge.hazardLevel;
    }

    return EvacuationPath(
      nodeIds: orderedPath,
      totalCost: totalCost,
      hazardScore: hazardScore,
      exitNodeId: goalId,
    );
  }

  // Helper: get edge between two adjacent nodes
  GraphEdge? _getEdge(String fromId, String toId) {
    for (final entry in (_adj[fromId] ?? [])) {
      if (entry.key == toId) return entry.value;
    }
    return null;
  }

  //  DEBUG helpers
  Set<String> get currentlyBlockedNodes => Set.unmodifiable(_blockedNodes);
  Map<String, double> get currentCrowdPressure =>
      Map.unmodifiable(_crowdPressure);
}
