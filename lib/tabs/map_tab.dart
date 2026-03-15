import 'package:flutter/material.dart';

import '../screens/car_park_finder_page.dart';
import '../services/api_controller.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  late final ApiController _apiController;

  @override
  void initState() {
    super.initState();
    _apiController = ApiController();
  }

  @override
  Widget build(BuildContext context) {
    return CarParkFinderPage(
      apiController: _apiController,
    );
  }
}
