import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:sarri_ride/features/ride/widgets/location_status_indicator.dart';
import 'package:sarri_ride/features/ride/controllers/drawer_controller.dart';

class BookingInitialWidget extends StatelessWidget {
  final VoidCallback onDestinationTap;
  final VoidCallback onCarTap;
  final VoidCallback onPackageTap;
  final VoidCallback onFreightTap;
  final VoidCallback onWarehouseTap;
  final VoidCallback onCarRentalTap;
  final List<Map<String, dynamic>> recentDestinations;
  final Function(Map<String, dynamic>) onRecentDestinationTap;

  const BookingInitialWidget({
    super.key,
    required this.onDestinationTap,
    required this.onCarTap,
    required this.onPackageTap,
    required this.onFreightTap,
    required this.onWarehouseTap,
    required this.onCarRentalTap,
    required this.recentDestinations,
    required this.onRecentDestinationTap,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final backgroundColor = dark ? const Color(0xFF1A1A1A) : Colors.grey[100];
    final cardColor = dark ? const Color(0xFF242424) : Colors.white;
    final drawerController = Get.find<MapDrawerController>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Greeting ──
            Obx(() {
              final name = drawerController.userName.value;
              final firstName = name.split(' ').first;
              return Row(
                children: [
                  Text(
                    '${_getGreeting()}, $firstName',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : TColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 22)),
                ],
              );
            }),
            const SizedBox(height: 4),
            Text(
              "Let's get you moving.",
              style: TextStyle(
                fontSize: 14,
                color: dark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),

            // ── Search Bar ──
            GestureDetector(
              onTap: onDestinationTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.grey[500], size: 22),
                    const SizedBox(width: 12),
                    Text(
                      'Where are you going?',
                      style: TextStyle(
                        fontSize: 15,
                        color: dark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── GET STARTED label ──
            Text(
              'GET STARTED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: dark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 10),

            // ── Featured Ride Card ──
            GestureDetector(
              onTap: onCarTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: TColors.primary.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ride',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: dark ? Colors.white : TColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your favorite driver, just a tap away.',
                            style: TextStyle(
                              fontSize: 13,
                              color: dark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: TColors.primary,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Book a ride',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Car image decoration
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset(
                        'assets/images/content/car.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── MORE WAYS label ──
            Text(
              'MORE WAYS TO SEND & MOVE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: dark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 10),

            // ── Package & Warehouse row ──
            Row(
              children: [
                Expanded(
                  child: _ServiceCard(
                    imagePath: 'assets/images/content/package.png',
                    title: 'Package',
                    subtitle: 'Send items safely, door to door.',
                    onTap: onPackageTap,
                    cardColor: cardColor,
                    dark: dark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ServiceCard(
                    icon: Icons.warehouse_outlined,
                    title: 'Warehouse',
                    subtitle: 'Drop off at our nearest hub.',
                    onTap: onWarehouseTap,
                    cardColor: cardColor,
                    dark: dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Car Rental (full width) ──
            Stack(
              children: [
                _ServiceCard(
                  icon: Icons.vpn_key_outlined,
                  title: 'Car Rental',
                  subtitle: 'Pick up the keys, ride on your terms.',
                  onTap: onCarRentalTap,
                  cardColor: cardColor,
                  dark: dark,
                  fullWidth: true,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: TColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Center(child: LocationStatusIndicator()),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String? imagePath;
  final IconData? icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? cardColor;
  final bool dark;
  final bool fullWidth;

  const _ServiceCard({
    this.imagePath,
    this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.cardColor,
    required this.dark,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: fullWidth ? 22 : 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: fullWidth
            ? Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF2E2E2E) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: imagePath != null
                          ? Image.asset(imagePath!, width: 28, height: 28, fit: BoxFit.contain)
                          : Icon(icon, color: Colors.orange, size: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: dark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: dark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF2E2E2E) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: imagePath != null
                          ? Image.asset(imagePath!, width: 26, height: 26, fit: BoxFit.contain)
                          : Icon(icon, color: Colors.orange, size: 24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}
