import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/parking_session_detail_screen.dart';

class MyParkingTab extends StatefulWidget {
  @override
  _MyParkingTabState createState() => _MyParkingTabState();
}

class _MyParkingTabState extends State<MyParkingTab> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> cars = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCars();
  }

  Future<void> fetchCars() async {
    final response = await supabase
        .from('cars')
        .select();
    setState(() {
      cars = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Parking', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF6200EA),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cars.isEmpty
              ? Center(child: Text('No cars registered yet'))
              : ListView.builder(
                  itemCount: cars.length,
                  itemBuilder: (context, index) {
                    return CarCard(car: cars[index]);
                  },
                ),
    );
  }
}

class CarCard extends StatefulWidget {
  final Map<String, dynamic> car;
  CarCard({required this.car});

  @override
  _CarCardState createState() => _CarCardState();
}

class _CarCardState extends State<CarCard> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> sessions = [];
  bool isExpanded = false;
  bool isLoading = false;

  Future<void> fetchSessions() async {
    setState(() => isLoading = true);
    final response = await supabase
        .from('parkingsession')
        .select()
        .eq('carplate', widget.car['carplate'])
        .order('parkingstarttime', ascending: false)
        .limit(3);
    setState(() {
      sessions = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  IconData _getCarIcon(String? caricon) {
    switch (caricon) {
      case 'sedan': return Icons.directions_car;
      case 'sports': return Icons.sports_score;
      case 'suv': return Icons.directions_car_filled;
      case 'van': return Icons.airport_shuttle;
      default: return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            color: Colors.grey[200],
            child: Icon(
              _getCarIcon(widget.car['caricon']),
              size: 100,
              color: Color(0xFF6200EA),
            ),
          ),
          ListTile(
            title: Text(widget.car['carname'] ?? 'Unknown Car',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.car['carplate'] ?? ''),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: Colors.orange),
                    SizedBox(width: 4),
                    Text('Parked',
                        style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() => isExpanded = !isExpanded);
                if (isExpanded && sessions.isEmpty) fetchSessions();
              },
            ),
          ),
          if (isExpanded) ...[
            Divider(),
            isLoading
                ? Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                : sessions.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No parking sessions yet'),
                      )
                    : Column(
                        children: sessions.map((session) {
                          return ListTile(
                            leading: Icon(Icons.history, color: Colors.grey),
                            title: Text(session['sessionname'] ?? 'Unnamed Session'),
                            subtitle: Text(session['location'] ?? ''),
                            trailing: Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ParkingSessionDetailScreen(session: session),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
          ]
        ],
      ),
    );
  }
}