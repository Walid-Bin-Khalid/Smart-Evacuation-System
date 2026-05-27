import 'dart:convert';

BuildingGraph buildingGraphFromJson(String str) {
  return BuildingGraph.fromJson(json.decode(str));
}

class BuildingGraph {
  final String buildingName;
  final int totalNodes;
  final int totalEdges;
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  BuildingGraph({
    required this.buildingName,
    required this.totalNodes,
    required this.totalEdges,
    required this.nodes,
    required this.edges,
  });

  factory BuildingGraph.fromJson(Map<String, dynamic> json) {
    return BuildingGraph(
      // ✅ building_name nahi → system_meta try karo → default
      buildingName:
          json['building_name'] ??
          json['system_meta'] ??
          'Smart Evacuation Building',
      totalNodes: json['total_nodes'] ?? 0,
      totalEdges: json['total_edges'] ?? 0,
      nodes: List<GraphNode>.from(
        json['nodes'].map((x) => GraphNode.fromJson(x)),
      ),
      edges: List<GraphEdge>.from(
        json['edges'].map((x) => GraphEdge.fromJson(x)),
      ),
    );
  }
}

class GraphNode {
  final String id;
  final double x;
  final double y;
  final String floor;
  final String type;
  final bool isExit;

  GraphNode({
    required this.id,
    required this.x,
    required this.y,
    required this.floor,
    required this.type,
    required this.isExit,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;

    // ✅ floor field nahi → ID prefix se derive karo
    String floor;
    if (json['floor'] != null) {
      floor = json['floor'];
    } else if (id.startsWith('F2_')) {
      floor = 'Second';
    } else if (id.startsWith('F1_')) {
      floor = 'First';
    } else {
      floor = 'Ground';
    }

    return GraphNode(
      id: id,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      floor: floor,
      type: json['type'] ?? 'generic',
      // ✅ is_exit nahi → type == 'exit' check karo
      isExit: json['is_exit'] ?? (json['type'] == 'exit'),
    );
  }
}

class GraphEdge {
  final String from;
  final String to;
  final double baseWeight;
  double currentWeight;
  final int hazardLevel;
  final bool blocked;
  final bool isDynamic;
  final String type;

  GraphEdge({
    required this.from,
    required this.to,
    required this.baseWeight,
    required this.currentWeight,
    required this.hazardLevel,
    required this.blocked,
    required this.isDynamic,
    required this.type,
  });

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    // ✅ base_weight nahi → weight try karo → default 1.0
    final weight = (json['base_weight'] ?? json['weight'] ?? 1.0) as num;

    return GraphEdge(
      from: json['from'],
      to: json['to'],
      baseWeight: weight.toDouble(),
      currentWeight: (json['current_weight'] ?? weight).toDouble(),
      hazardLevel: json['hazard_level'] ?? 0,
      blocked: json['blocked'] ?? false,
      isDynamic: json['dynamic'] ?? true,
      type: json['type'] ?? 'walk',
    );
  }
}
