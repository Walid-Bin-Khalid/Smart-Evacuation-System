import 'package:flutter/services.dart';
import '../Data/building_graph.dart';

class GraphLoaderService {
  static Future<BuildingGraph> loadGraph() async {
    final jsonString = await rootBundle.loadString(
      'assets/building_graph.json',
    );

    return buildingGraphFromJson(jsonString);
  }
}
