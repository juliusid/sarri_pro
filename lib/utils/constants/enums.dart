/* --
      LIST OF Enums
      They cannot be created inside a class.
-- */

/// Switch of Custom Brand-Text-Size Widget
enum TextSizes { small, medium, large }

enum OrderStatus { processing, shipped, delivered }

enum PaymentMethods {
  paypal,
  googlePay,
  applePay,
  visa,
  masterCard,
  creditCard,
  paystack,
  razorPay,
  paytm,
}

enum UserType { rider, driver }

enum DriverStatus { offline, online, onTrip, unavailable, onBreak }

enum VehicleType { sedan, suv, hatchback, motorcycle, van, truck }

enum RequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
  completed,
  expired,
}

enum TripStatus {
  none,
  requested,
  accepted,
  drivingToPickup,
  arrivedAtPickup,
  tripInProgress,
  completed,
  cancelled,
  arrivedAtDestination,
}

enum DocumentType {
  driverLicense,
  vehicleRegistration,
  insurance,
  profilePhoto,
  vehiclePhoto,
}

enum DocumentStatus { pending, approved, rejected, expired }
