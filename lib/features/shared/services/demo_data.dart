import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sarri_ride/features/shared/models/user_model.dart';
import 'package:sarri_ride/utils/constants/enums.dart';

class DemoDataService {
  static final DemoDataService _instance = DemoDataService._internal();
  factory DemoDataService() => _instance;
  DemoDataService._internal();

  static DemoDataService get instance => _instance;

  // Demo accounts
  static const String riderEmail = 'rider@demo.com';
  static const String riderPassword = 'Rider123!';
  static const String driverEmail = 'driver@demo.com';
  static const String driverPassword = 'Driver123!';

  // Mock user data
  final Map<String, User> _demoUsers = {};

  void initializeDemoData() {
    _demoUsers.clear();

    // Create demo rider (remains the same)
    final riderUser = User(
      id: 'rider_001',
      email: riderEmail,
      firstName: 'John',
      lastName: 'Rider',
      phoneNumber: '+2348012345678',
      userType: UserType.rider,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      riderProfile: RiderProfile(
        userId: 'rider_001',
        rating: 4.8,
        totalTrips: 25,
        savedPlaces: [
          'Home - 123 Victoria Island, Lagos',
          'Work - 456 Lekki Phase 1, Lagos',
          'Gym - 789 Ikeja GRA, Lagos',
        ],
        emergencyContact: '+2348087654321',
        preferences: {
          'preferredPaymentMethod': 'wallet',
          'musicPreference': 'pop',
          'temperaturePreference': 'cool',
        },
      ),
    );

    // --- UPDATED DEMO DRIVER ---
    final driverUser = User(
      id: 'driver_001',
      email: driverEmail,
      firstName: 'Mike',
      lastName: 'Driver',
      phoneNumber: '+2348098765432',
      userType: UserType.driver,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
      driverProfile: DriverProfile(
        // Use the new structure
        userId: 'driver_001',
        // Example nested objects
        drivingLicense: DrivingLicenseModel(
          // Example
          issueDate: DateTime.now().subtract(const Duration(days: 85)),
          expiryDate: DateTime.now().add(const Duration(days: 1095)),
          // Add image URLs if needed for demo
        ),
        currentAddress: AddressModel(
          // Example
          address: '10 Driver St',
          city: 'Ikeja',
          state: 'Lagos',
          country: 'Nigeria',
          postalCode: '100001',
        ),
        permanentAddress: AddressModel(
          // Example
          address: '10 Driver St',
          city: 'Ikeja',
          state: 'Lagos',
          country: 'Nigeria',
          postalCode: '100001',
        ),
        bankDetails: BankDetailsModel(
          // Example
          bankAccountNumber: '1234567890',
          bankName: 'Demo Bank',
          bankAccountName: 'Mike Driver',
        ),
        vehicleDetails: Vehicle(
          // Use VehicleDetails nested object
          make: 'Toyota',
          model: 'Camry',
          year: 2020,
          plateNumber: 'ABC-123-XY', // Use plateNumber
          color: 'Black',
          type: VehicleType.sedan,
          seats: 4, // Seats now part of Vehicle
        ),
        location: LocationModel(
          // Use Location nested object
          type: 'Point',
          coordinates: const LatLng(6.5244, 3.3792), // Use coordinates
          state: 'Lagos',
        ),
        // Fields directly in DriverProfile
        isVerified: true,
        adminVerified: false, // Example
        availabilityStatus: 'available', // Match API field
        status: 'active', // Match API field
        lastLocationUpdate: DateTime.now().subtract(const Duration(minutes: 2)),
        // dateOfBirth: DateTime(1990, 5, 15), // Example
        // gender: 'male', // Example
        emergencyContactNumber: '+2348076543210',
        licenseNumber: 'LOS-123456789', // Example
        // seat: 4, // Seat is now inside vehicleDetails

        // Stats (keep using direct fields as defined in DriverProfile)
        rating: 4.9,
        totalTrips: 1250,
        totalEarnings: 2850000.0, // ₦2,850,000
        acceptanceRate: 95.5,
        cancellationRate: 2.1,
      ),
    );
    // --- END UPDATED DEMO DRIVER ---

    _demoUsers[riderEmail] = riderUser;
    _demoUsers[driverEmail] = driverUser;
  }

  // Authentication methods
  Future<User?> authenticateUser(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if ((email == riderEmail && password == riderPassword) ||
        (email == driverEmail && password == driverPassword)) {
      return _demoUsers[email];
    }
    return null;
  }

  // Get user by email
  User? getUserByEmail(String email) {
    return _demoUsers[email];
  }

  // Get all demo users
  List<User> getAllUsers() {
    return _demoUsers.values.toList();
  }

  // Create new user (for registration)
  Future<User> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required UserType userType,
    String? phoneNumber,
    DriverProfile? driverProfile,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    final user = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      userType: userType,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      riderProfile: userType == UserType.rider
          ? RiderProfile(
              userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
            )
          : null,
      driverProfile: driverProfile,
    );

    _demoUsers[email] = user;
    return user;
  }

  // Update user
  Future<User> updateUser(User user) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final updatedUser = user.copyWith(updatedAt: DateTime.now());
    _demoUsers[user.email] = updatedUser;
    return updatedUser;
  }

  // Update driver location (updates nested LocationModel)
  Future<void> updateDriverLocation(String userId, LatLng location) async {
    try {
      final user = _demoUsers.values.firstWhere(
        (user) => user.id == userId && user.userType == UserType.driver,
        orElse: () => throw StateError('Driver not found'),
      );

      if (user.driverProfile != null) {
        // Use copyWith on DriverProfile to update the nested LocationModel
        final updatedDriverProfile = user.driverProfile!.copyWith(
          currentLocation: location, // Pass LatLng directly to copyWith
          // lastLocationUpdate is handled by copyWith
        );

        final updatedUser = user.copyWith(
          driverProfile: updatedDriverProfile,
          updatedAt: DateTime.now(),
        );

        _demoUsers[user.email] = updatedUser;
      }
    } catch (e) {
      print(
        'Warning: Could not update driver location for userId: $userId. Error: $e',
      );
    }
  }

  // Update driver status (updates availabilityStatus)
  Future<void> updateDriverStatus(
    String userId,
    String availabilityStatus,
  ) async {
    // Use String for status
    try {
      final user = _demoUsers.values.firstWhere(
        (user) => user.id == userId && user.userType == UserType.driver,
        orElse: () => throw StateError('Driver not found'),
      );

      if (user.driverProfile != null) {
        // Use copyWith on DriverProfile to update availabilityStatus
        final updatedDriverProfile = user.driverProfile!.copyWith(
          availabilityStatus: availabilityStatus, // Update availabilityStatus
        );

        final updatedUser = user.copyWith(
          driverProfile: updatedDriverProfile,
          updatedAt: DateTime.now(),
        );

        _demoUsers[user.email] = updatedUser;
      }
    } catch (e) {
      print(
        'Warning: Could not update driver status for userId: $userId. Error: $e',
      );
    }
  }

  // Get nearby drivers (uses nested location)
  List<User> getNearbyDrivers(LatLng location, {double radiusKm = 5.0}) {
    return _demoUsers.values
        .where(
          (user) =>
              user.userType == UserType.driver &&
              user.driverProfile?.availabilityStatus ==
                  'available' && // Check availabilityStatus
              user.driverProfile?.location.coordinates != null,
        ) // Check nested coordinates
        .toList();
    // TODO: Implement actual distance check using user.driverProfile.location.coordinates
  }

  // Mock trip data
  List<Map<String, dynamic>> getMockTripsForUser(
    String userId,
    UserType userType,
  ) {
    if (userType == UserType.rider) {
      return [
        {
          'id': 'trip_001',
          'date': DateTime.now().subtract(const Duration(days: 1)),
          'from': 'Victoria Island, Lagos',
          'to': 'Lekki Phase 1, Lagos',
          'fare': 2500.0,
          'driverName': 'Mike Driver',
          'rating': 5.0,
          'status': 'completed',
        },
        {
          'id': 'trip_002',
          'date': DateTime.now().subtract(const Duration(days: 3)),
          'from': 'Ikeja GRA, Lagos',
          'to': 'Victoria Island, Lagos',
          'fare': 3200.0,
          'driverName': 'Sarah Johnson',
          'rating': 4.5,
          'status': 'completed',
        },
        {
          'id': 'trip_003',
          'date': DateTime.now().subtract(const Duration(days: 7)),
          'from': 'Surulere, Lagos',
          'to': 'Lekki Phase 1, Lagos',
          'fare': 4500.0,
          'driverName': 'David Wilson',
          'rating': 5.0,
          'status': 'completed',
        },
      ];
    } else {
      return [
        {
          'id': 'trip_101',
          'date': DateTime.now().subtract(const Duration(hours: 2)),
          'from': 'Victoria Island, Lagos',
          'to': 'Lekki Phase 1, Lagos',
          'fare': 2500.0,
          'riderName': 'John Rider',
          'rating': 5.0,
          'status': 'completed',
          'earnings': 2250.0, // After commission
        },
        {
          'id': 'trip_102',
          'date': DateTime.now().subtract(const Duration(hours: 5)),
          'from': 'Ikeja GRA, Lagos',
          'to': 'Victoria Island, Lagos',
          'fare': 3200.0,
          'riderName': 'Alice Smith',
          'rating': 4.0,
          'status': 'completed',
          'earnings': 2880.0,
        },
        {
          'id': 'trip_103',
          'date': DateTime.now().subtract(const Duration(days: 1)),
          'from': 'Surulere, Lagos',
          'to': 'Lekki Phase 1, Lagos',
          'fare': 4500.0,
          'riderName': 'Bob Johnson',
          'rating': 5.0,
          'status': 'completed',
          'earnings': 4050.0,
        },
      ];
    }
  }

  // Mock earnings data for drivers
  Map<String, dynamic> getMockEarningsData(String driverId) {
    return {
      'today': {'trips': 8, 'earnings': 28500.0, 'hours': 6.5},
      'thisWeek': {'trips': 45, 'earnings': 185000.0, 'hours': 35.0},
      'thisMonth': {'trips': 180, 'earnings': 720000.0, 'hours': 140.0},
      'allTime': {'trips': 1250, 'earnings': 2850000.0, 'hours': 950.0},
    };
  }
}
