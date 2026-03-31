import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/parking_session_controller.dart';
import 'widgets/session_summary_card.dart';
import 'widgets/session_edit_section.dart';
import 'widgets/photos_section.dart';
import 'widgets/session_bottom_bar.dart';

class ParkingSessionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> session;
  const ParkingSessionDetailScreen({required this.session});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParkingSessionController(
        initialSession: session,
      )..init(),
      child: const _ParkingSessionDetailView(),
    );
  }
}

class _ParkingSessionDetailView extends StatelessWidget {
  const _ParkingSessionDetailView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingSessionController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Session',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6200EA),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: c.isLoadingSession
          ? const Center(child: CircularProgressIndicator())
          : c.errorMessage != null
              ? Center(child: Text(c.errorMessage!))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          // Non-editable summary card at the top
                          SessionSummaryCard(
                            isOngoing: c.isOngoing,
                            startTime: c.session?.startTime,
                            endTime: c.session?.endTime,
                            driverName: c.driverName,
                            carName: c.carName,
                            carPlate: c.session?.carPlate,
                          ),

                          // Editable fields in ListTile style
                          const SessionEditSection(),

                          // Photos section
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            child: const PhotosSection(),
                            ),                        ],
                      ),
                    ),

                    // Pinned bottom bar for ongoing sessions
                    if (c.isOngoing)
                      const SessionBottomBar(),
                  ],
                ),
    );
  }
}