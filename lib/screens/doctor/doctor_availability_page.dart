import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/theme.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/user_provider.dart';

class DoctorAvailabilityPage extends StatefulWidget {
  const DoctorAvailabilityPage({super.key});

  @override
  State<DoctorAvailabilityPage> createState() => _DoctorAvailabilityPageState();
}

class _DoctorAvailabilityPageState extends State<DoctorAvailabilityPage> {
  Map<String, Map<String, dynamic>> _availability = {
    'monday': {'start': '09:00', 'end': '17:00', 'available': true},
    'tuesday': {'start': '09:00', 'end': '17:00', 'available': true},
    'wednesday': {'start': '09:00', 'end': '17:00', 'available': true},
    'thursday': {'start': '09:00', 'end': '17:00', 'available': true},
    'friday': {'start': '09:00', 'end': '17:00', 'available': true},
    'saturday': {'start': null, 'end': null, 'available': false},
    'sunday': {'start': null, 'end': null, 'available': false},
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Get user ID - try from UserProvider first, then Firebase Auth
    String? userId;
    var currentUser = userProvider.currentUser;
    if (currentUser != null) {
      userId = currentUser.userId;
    } else {
      // If user data not loaded, try to get from Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        userId = firebaseUser.uid;
        // Try to load user data
        await userProvider.loadUserData(userId);
        currentUser = userProvider.currentUser;
      }
    }
    
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await doctorProvider.loadDoctor(userId);
      final doctor = doctorProvider.selectedDoctor;
      
      if (doctor != null && doctor.availability.isNotEmpty) {
        setState(() {
          // Convert DoctorAvailability objects to the format expected by the UI
          _availability = {
            'monday': {
              'start': doctor.availability['monday']?.start,
              'end': doctor.availability['monday']?.end,
              'available': doctor.availability['monday']?.available ?? false,
            },
            'tuesday': {
              'start': doctor.availability['tuesday']?.start,
              'end': doctor.availability['tuesday']?.end,
              'available': doctor.availability['tuesday']?.available ?? false,
            },
            'wednesday': {
              'start': doctor.availability['wednesday']?.start,
              'end': doctor.availability['wednesday']?.end,
              'available': doctor.availability['wednesday']?.available ?? false,
            },
            'thursday': {
              'start': doctor.availability['thursday']?.start,
              'end': doctor.availability['thursday']?.end,
              'available': doctor.availability['thursday']?.available ?? false,
            },
            'friday': {
              'start': doctor.availability['friday']?.start,
              'end': doctor.availability['friday']?.end,
              'available': doctor.availability['friday']?.available ?? false,
            },
            'saturday': {
              'start': doctor.availability['saturday']?.start,
              'end': doctor.availability['saturday']?.end,
              'available': doctor.availability['saturday']?.available ?? false,
            },
            'sunday': {
              'start': doctor.availability['sunday']?.start,
              'end': doctor.availability['sunday']?.end,
              'available': doctor.availability['sunday']?.available ?? false,
            },
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorProvider = Provider.of<DoctorProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('Manage Availability'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
          ..._availability.entries.map((entry) {
            final day = entry.key;
            final schedule = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(day[0].toUpperCase() + day.substring(1)),
                subtitle: schedule['available'] == true
                    ? Text('${schedule['start']} - ${schedule['end']}')
                    : const Text('Not available'),
                trailing: Switch(
                  value: schedule['available'] == true,
                  onChanged: (value) {
                    setState(() {
                      _availability[day] = {
                        'start': value ? '09:00' : null,
                        'end': value ? '17:00' : null,
                        'available': value,
                      };
                    });
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              // Get user ID - try from UserProvider first, then Firebase Auth
              String? userId;
              var currentUser = userProvider.currentUser;
              if (currentUser != null) {
                userId = currentUser.userId;
              } else {
                // If user data not loaded, try to get from Firebase Auth
                final firebaseUser = FirebaseAuth.instance.currentUser;
                if (firebaseUser != null) {
                  userId = firebaseUser.uid;
                  // Try to load user data
                  await userProvider.loadUserData(userId);
                }
              }
              
              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User data not loaded. Please try again.'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
                return;
              }
              
              final success = await doctorProvider.updateAvailability(
                doctorId: userId,
                availability: _availability,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Availability updated successfully'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Save Availability'),
            ),
          ),
        ],
      ),
    );
  }
}

