import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:park_buddy/models/parking_session.dart';
import 'package:park_buddy/screens/parking_session_detail_screen.dart';
import 'package:park_buddy/utils/parking_service.dart';
import '../tabs/map_tab.dart';
import '../tabs/profile_tab.dart';
import '../tabs/my_parking_tab.dart';
import 'package:park_buddy/services/notification_service.dart' as notif;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of widgets for each tab
  final List<Widget> _widgetOptions = <Widget>[
    MyParkingTab(),
    MapTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();

    notif.startService(onTapNotif: _onTapNotif);
  }

  Future<void> _onTapNotif(String payload) async {
    // Parse notification payload into parking session object
    final sessionFromNotif = ParkingSession.fromMap(jsonDecode(payload));

    // Get corresponding parking session from database
    final session = await ParkingService().fetchSessionById(
      sessionFromNotif.sessionId,
    );

    if (session == null) return;

    // Navigate to parking session details screen
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ParkingSessionDetailScreen(session: session),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Park Buddy'),
      ),
      body: _widgetOptions[_selectedIndex], // Display selected tab content
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'My Parking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.my_location),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
