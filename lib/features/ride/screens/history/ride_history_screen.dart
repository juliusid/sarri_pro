import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:iconsax/iconsax.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  int _displayedRidesCount = 10; // Initially show 10 rides
  bool _isLoadingMore = false;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return Scaffold(
      backgroundColor: dark ? TColors.dark : TColors.lightGrey,
      appBar: AppBar(
        title: const Text('Ride History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.light : TColors.dark,
            size: TSizes.iconLg,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showFilterDialog(context, dark),
            icon: Icon(
              Iconsax.filter,
              color: dark ? TColors.light : TColors.dark,
              size: TSizes.iconLg,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(TSizes.defaultSpace),
              padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColors.info, TColors.info.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: TColors.info.withOpacity(0.3),
                    blurRadius: TSizes.md,
                    offset: const Offset(0, TSizes.sm),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(TSizes.md),
                        decoration: BoxDecoration(
                          color: TColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                        ),
                        child: const Icon(
                          Iconsax.route_square,
                          color: TColors.white,
                          size: TSizes.iconLg,
                        ),
                      ),
                      const SizedBox(width: TSizes.spaceBtwItems),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Ride History',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: TColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: TSizes.xs),
                            Text(
                              'Track all your completed trips and journeys',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: TColors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Stats Cards Row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Rides',
                      value: _mockRides.length.toString(),
                      icon: Iconsax.car,
                      color: TColors.primary,
                      dark: dark,
                      context: context,
                    ),
                  ),
                  const SizedBox(width: TSizes.spaceBtwItems),
                  Expanded(
                    child: _buildStatCard(
                      title: 'This Month',
                      value: _getThisMonthRidesCount().toString(),
                      icon: Iconsax.calendar,
                      color: TColors.success,
                      dark: dark,
                      context: context,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Recent Rides Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
              // padding: const EdgeInsets.all(TSizes.defaultSpace),
              decoration: BoxDecoration(
                // color: dark ? TColors.dark : TColors.white,
                borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
                //     blurRadius: TSizes.md,
                //     offset: const Offset(0, TSizes.sm),
                //   ),
                // ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Rides',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dark ? TColors.white : TColors.black,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                        decoration: BoxDecoration(
                          color: TColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                        ),
                        child: Text(
                          'Showing ${_displayedRidesCount} of ${_mockRides.length}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: TColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  
                  // Ride history list
                  ...List.generate(
                    _displayedRidesCount.clamp(0, _mockRides.length), 
                    (index) {
                      final ride = _mockRides[index];
                      return _buildRideCard(ride, dark, context, index == _displayedRidesCount - 1 && index == _mockRides.length - 1);
                    }
                  ),
                  
                  // Load More Button
                  if (_displayedRidesCount < _mockRides.length) ...[
                    const SizedBox(height: TSizes.spaceBtwItems),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoadingMore ? null : _loadMoreRides,
                        icon: _isLoadingMore 
                          ? SizedBox(
                              width: TSizes.iconSm,
                              height: TSizes.iconSm,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(TColors.primary),
                              ),
                            )
                          : Icon(Iconsax.arrow_down, size: TSizes.iconSm),
                        label: Text(_isLoadingMore ? 'Loading...' : 'Load More Rides'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TColors.primary,
                          side: BorderSide(color: TColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
                        ),
                      ),
                    ),
                  ],
                  
                  // All Rides Loaded Message
                  if (_displayedRidesCount >= _mockRides.length) ...[
                    const SizedBox(height: TSizes.spaceBtwItems),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(TSizes.defaultSpace),
                      decoration: BoxDecoration(
                        color: TColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                        border: Border.all(
                          color: TColors.success.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.tick_circle,
                            color: TColors.success,
                            size: TSizes.iconMd,
                          ),
                          const SizedBox(width: TSizes.spaceBtwItems),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'All rides loaded',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: TColors.success,
                                  ),
                                ),
                                const SizedBox(height: TSizes.xs),
                                Text(
                                  'You\'ve reached the end of your ride history',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
          ],
        ),
      ),
    );
  }

  void _loadMoreRides() {
    setState(() {
      _isLoadingMore = true;
    });
    
    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _displayedRidesCount = (_displayedRidesCount + 10).clamp(0, _mockRides.length);
        _isLoadingMore = false;
      });
    });
  }

  int _getThisMonthRidesCount() {
    // Count rides from December (this month in our mock data)
    return _mockRides.where((ride) => ride.date.contains('Dec') || ride.date.contains('Today') || ride.date.contains('Yesterday')).length;
  }

  void _showFilterDialog(BuildContext context, bool dark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dark ? TColors.dark : TColors.white,
        title: Text(
          'Filter Rides',
          style: TextStyle(color: dark ? TColors.white : TColors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('All Rides', true, context),
            _buildFilterOption('Completed Only', false, context),
            _buildFilterOption('Cancelled Only', false, context),
            const SizedBox(height: TSizes.spaceBtwItems),
            const Divider(),
            const SizedBox(height: TSizes.spaceBtwItems),
            _buildFilterOption('Last 7 days', false, context),
            _buildFilterOption('Last 30 days', false, context),
            _buildFilterOption('All time', true, context),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: dark ? TColors.lightGrey : TColors.darkGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              THelperFunctions.showSnackBar('Filter applied successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.primary,
              foregroundColor: TColors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected, BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(color: dark ? TColors.white : TColors.black),
      ),
      leading: Radio<bool>(
        value: isSelected,
        groupValue: true,
        onChanged: (value) {},
        activeColor: TColors.primary,
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool dark,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.md,
            offset: const Offset(0, TSizes.sm),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
            ),
            child: Icon(
              icon,
              color: color,
              size: TSizes.iconLg,
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: dark ? TColors.white : TColors.black,
            ),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: dark ? TColors.lightGrey : TColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(RideHistory ride, bool dark, BuildContext context, bool isLastRide) {
    return Container(
      margin: EdgeInsets.only(bottom: isLastRide ? 0 : TSizes.defaultSpace),
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? TColors.dark : TColors.white,
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.3 : 0.1),
            blurRadius: TSizes.md,
            offset: const Offset(0, TSizes.sm),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ride.date,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: TSizes.sm, vertical: TSizes.xs),
                decoration: BoxDecoration(
                  color: _getStatusColor(ride.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                ),
                child: Text(
                  ride.status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getStatusColor(ride.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          // Route
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: TSizes.iconSm,
                    height: TSizes.iconSm,
                    decoration: const BoxDecoration(
                      color: TColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 30,
                    color: dark ? TColors.dark : Colors.grey[300],
                  ),
                  Container(
                    width: TSizes.iconSm,
                    height: TSizes.iconSm,
                    decoration: const BoxDecoration(
                      color: TColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.pickup,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                    const SizedBox(height: TSizes.spaceBtwItems),
                    Text(
                      ride.destination,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          // Driver info and price
          Row(
            children: [
              const CircleAvatar(
                radius: TSizes.iconMd,
                backgroundColor: TColors.primary,
                child: Icon(
                  Iconsax.user,
                  color: Colors.white,
                  size: TSizes.iconMd,
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driverName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: dark ? TColors.white : TColors.black,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: TSizes.iconSm),
                        const SizedBox(width: TSizes.xs),
                        Text(
                          '${ride.rating}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: dark ? TColors.lightGrey : TColors.darkGrey,
                          ),
                        ),
                        Text(
                          ' • ${ride.carModel}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: dark ? TColors.lightGrey : TColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '₦${ride.price}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: dark ? TColors.white : TColors.black,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.spaceBtwItems),
          
          // Action buttons
          Row(
            children: [
              // if (ride.status == 'Completed') ...[
              //   Expanded(
              //     child: OutlinedButton.icon(
              //       onPressed: () => _rateRide(ride),
              //       icon: const Icon(Icons.star_outline, size: TSizes.iconSm),
              //       label: const Text('Rate'),
              //       style: OutlinedButton.styleFrom(
              //         foregroundColor: TColors.primary,
              //         side: const BorderSide(color: TColors.primary),
              //       ),
              //     ),
              //   ),
              //   const SizedBox(width: TSizes.spaceBtwItems),
              // ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rebookRide(ride),
                  icon: const Icon(Iconsax.refresh, size: TSizes.iconSm),
                  label: const Text('Rebook'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwItems),
              OutlinedButton(
                onPressed: () => _viewDetails(ride),
                child: const Text('Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: dark ? TColors.lightGrey : TColors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return TColors.success;
      case 'Cancelled':
        return TColors.error;
      case 'In Progress':
        return TColors.warning;
      default:
        return TColors.info;
    }
  }

  void _rateRide(RideHistory ride) {
    THelperFunctions.showSnackBar('Rate ride with ${ride.driverName}');
  }

  void _rebookRide(RideHistory ride) {
    THelperFunctions.showSnackBar('Rebooking ride from ${ride.pickup} to ${ride.destination}');
  }

  void _viewDetails(RideHistory ride) {
    THelperFunctions.showSnackBar('Viewing details for ride on ${ride.date}');
  }
}

class RideHistory {
  final String date;
  final String pickup;
  final String destination;
  final String driverName;
  final double rating;
  final String carModel;
  final int price;
  final String status;

  RideHistory({
    required this.date,
    required this.pickup,
    required this.destination,
    required this.driverName,
    required this.rating,
    required this.carModel,
    required this.price,
    required this.status,
  });
}

// Mock data
final List<RideHistory> _mockRides = [
  RideHistory(
    date: 'Today, 2:30 PM',
    pickup: 'Victoria Island',
    destination: 'Lekki Phase 1',
    driverName: 'John Doe',
    rating: 4.8,
    carModel: 'Toyota Camry',
    price: 3200,
    status: 'Completed',
  ),
  RideHistory(
    date: 'Yesterday, 8:15 AM',
    pickup: 'Ikeja GRA',
    destination: 'Victoria Island',
    driverName: 'Sarah Johnson',
    rating: 4.9,
    carModel: 'Honda Accord',
    price: 2800,
    status: 'Completed',
  ),
  RideHistory(
    date: 'Dec 15, 6:45 PM',
    pickup: 'Surulere',
    destination: 'Yaba',
    driverName: 'Mike Wilson',
    rating: 4.7,
    carModel: 'Hyundai Elantra',
    price: 1500,
    status: 'Cancelled',
  ),
  RideHistory(
    date: 'Dec 14, 11:20 AM',
    pickup: 'Lekki Phase 1',
    destination: 'Ajah',
    driverName: 'David Brown',
    rating: 4.6,
    carModel: 'Toyota Corolla',
    price: 2200,
    status: 'Completed',
  ),
  RideHistory(
    date: 'Dec 13, 4:30 PM',
    pickup: 'Lagos Island',
    destination: 'Ikeja',
    driverName: 'Grace Adebayo',
    rating: 4.9,
    carModel: 'Nissan Sentra',
    price: 3500,
    status: 'Completed',
  ),
]; 