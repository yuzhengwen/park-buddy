import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:park_buddy/services/service_locator.dart';
import 'package:provider/provider.dart';
import 'package:park_buddy/models/parking_session.dart';
import 'package:park_buddy/screens/parking_session_detail_screen.dart';
import 'package:park_buddy/services/parking_service.dart';
import 'package:park_buddy/providers/cars_provider.dart';
import '../tabs/map_tab.dart';
import '../tabs/profile_tab.dart';
import '../tabs/my_parking_tab.dart';
import 'package:park_buddy/services/notification_service.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarsProvider()..loadCars(),
      child: const _MainScreenBody(),
    );
  }
}

class _MainScreenBody extends StatefulWidget {
  const _MainScreenBody();

  @override
  State<_MainScreenBody> createState() => _MainScreenBodyState();
}

class _MainScreenBodyState extends State<_MainScreenBody> {
  final _notifService = getIt<NotifService>();
  int _selectedIndex = 0;

  // List of widgets for each tab
  final List<Widget> _widgetOptions = <Widget>[
    MyParkingTab(),
    MapTab(),
    ProfileTab(),
  ];

  void _onTapNavBar(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showPendingAlertsDialog() {
    final emptyText = Padding(
      padding: .symmetric(vertical: 20),
      child: Text(
        'No scheduled parking rate alerts',
        textAlign: .center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(
              color: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.38),
            ),
      ),
    );

    ListTile createAlertEntry(RateNotification alert) {
      final name = alert.session.sessionName ?? '(unnamed session)';
      final threshold = '\$${alert.session.rateThreshold!.toStringAsFixed(2)}';
      final time = DateFormat.yMd().add_jm().format(alert.scheduledTime);

      return ListTile(
        title: Text(name),
        subtitle: Text('$time ($threshold)'),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Rate Alerts'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListenableBuilder(
            listenable: _notifService,
            builder: (context, child) {
              final alerts = _notifService.pendingRateAlerts;

              return alerts.isEmpty
                ? emptyText
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      return createAlertEntry(alerts[index]);
                    },
                  );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Park Buddy'),
        actions: [
          IconButton(
            onPressed: _showPendingAlertsDialog,
            icon: ListenableBuilder(
              listenable: _notifService,
              builder: (context, child) => Badge.count(
                count: _notifService.pendingRateAlerts.length,
                child: child,
              ),
              child: const Icon(Icons.notifications),
            ),
          ),
        ],
      ),
      body: _widgetOptions[_selectedIndex], // Display selected tab content
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTapNavBar,
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
