import 'package:flutter/material.dart';
import '../utils/parking_service.dart';
import '../screens/parking_session_detail_screen.dart';
import '../services/user_service.dart'; 

class CarCard extends StatefulWidget {
  final Map<String, dynamic> car;
  final ParkingService parkingService;
  final UserService? userService;
  final bool showIcons,canExpand;
  final VoidCallback? onEdit;

  CarCard({required this.car, required this.parkingService, this.userService, this.showIcons = true, this.canExpand = true, this.onEdit});

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
                  Icon(Icons.directions_car, size: 100, color: Color(0xFFFF7643)),
            )
          : Icon(_getCarIcon(caricon), size: 100, color: Color(0xFFFF7643)),
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
    final String? carOwnerId = widget.car['ownerid'];
    final bool isOwner = widget.userService?.isCurrentUser(carOwnerId) ?? false;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          if(widget.showIcons)
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
            trailing: widget.canExpand ? IconButton(
                    icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() => isExpanded = !isExpanded);
                      if (isExpanded && sessions.isEmpty) _loadSessions();
                    },
                  )
                : isOwner ? IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFFFF7643)),
                        onPressed: widget.onEdit,
                      )
                    : FutureBuilder<String>(
                        future: widget.userService?.getOwnernameByUserId(widget.car['ownerid']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                            );
                          }
                          final name = snapshot.data ?? 'Family';
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              "$name's Car",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
            ),
          if (widget.canExpand && isExpanded) ...[
            Divider(),
            _buildSessionList(),
          ],
        ],
      ),
    );
  }
}