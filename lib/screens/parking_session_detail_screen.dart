import 'package:flutter/material.dart';

class ParkingSessionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> session;

  ParkingSessionDetailScreen({required this.session});

  @override
  Widget build(BuildContext context) {
    bool isOngoing = session['parkingendtime'] == null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Parking Session',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF6200EA),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            detailRow('Session Name', session['sessionname'] ?? 'Unnamed'),
            detailRow('Location', session['location'] ?? '-'),
            detailRow('Start Time', session['parkingstarttime']?.toString() ?? '-'),
            detailRow('End Time', isOngoing ? 'Ongoing' : session['parkingendtime']?.toString() ?? '-'),
            detailRow('Fees', '\$${session['currentfees'] ?? 0}'),
            detailRow('Car Plate', session['carplate'] ?? '-'),
            if (isOngoing)
              Padding(
                padding: EdgeInsets.only(top: 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6200EA),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {},
                    child: Text('END PARKING',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16)),
          Divider(),
        ],
      ),
    );
  }
}
