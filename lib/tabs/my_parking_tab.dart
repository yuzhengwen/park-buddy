import 'package:flutter/material.dart';
import '../screens/parking_session_detail_screen.dart';
import '../utils/parking_service.dart';

class MyParkingTab extends StatefulWidget {
  @override
  _MyParkingTabState createState() => _MyParkingTabState();
}

class _MyParkingTabState extends State<MyParkingTab> {
  final _parkingService = ParkingService();
  List<Map<String, dynamic>> cars = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    final data = await _parkingService.fetchCars();
    setState(() {
      cars = data;
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
                    return CarCard(
                      car: cars[index],
                      parkingService: _parkingService,
                    );
                  },
                ),
    );
  }
}

class CarCard extends StatefulWidget {
  final Map<String, dynamic> car;
  final ParkingService parkingService;

  CarCard({required this.car, required this.parkingService});

  @override
  _CarCardState createState() => _CarCardState();
}

class _CarCardState extends State<CarCard> {
  List<Map<String, dynamic>> sessions = [];
  bool isExpanded = false;
  bool isLoading = false;

  Future<void> _loadSessions() async {
    setState(() => isLoading = true);
    final data = await widget.parkingService.fetchSessions(widget.car['carplate']);
    setState(() {
      sessions = data;
      isLoading = false;
    });
  }

  IconData _getCarIcon(String? caricon) {
    switch (caricon) {
      case 'sedan': return Icons.directions_car;
      case 'sports': return Icons.directions_car_filled;
      case 'suv': return Icons.directions_car_filled;
      case 'van': return Icons.airport_shuttle;
      default: return Icons.directions_car;
    }
  }

  Widget _buildCarImage() {
    final caricon = widget.car['caricon'];
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey[200],
      child: caricon != null && caricon.startsWith('http')
          ? Image.network(
              caricon,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.directions_car, size: 100, color: Color(0xFF6200EA)),
            )
          : Icon(_getCarIcon(caricon), size: 100, color: Color(0xFF6200EA)),
    );
  }

  Widget _buildSessionList() {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (sessions.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text('No parking sessions yet'),
      );
    }
    return Column(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildCarImage(),
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
                if (isExpanded && sessions.isEmpty) _loadSessions();
              },
            ),
          ),
          if (isExpanded) ...[
            Divider(),
            _buildSessionList(),
          ],
        ],
      ),
    );
  }
}