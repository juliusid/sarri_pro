import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/driver/controllers/trip_management_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class TripRequestScreen extends StatefulWidget {
  const TripRequestScreen({super.key});

  @override
  State<TripRequestScreen> createState() => _TripRequestScreenState();
}

class _TripRequestScreenState extends State<TripRequestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    // Auto-dismiss when request is cleared by controller
    ever(
      Get.find<TripManagementController>().currentTripRequest,
      (request) {
        if (request == null &&
            mounted &&
            Get.currentRoute == '/TripRequestScreen') {
          Get.back();
        }
      },
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripManagementController>();
    final dark = THelperFunctions.isDarkMode(context);
    final bg = dark ? const Color(0xFF1C1C1E) : Colors.white;
    final surface = dark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5);
    final textPrimary = dark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary =
        dark ? const Color(0xFF8E8E93) : const Color(0xFF6B6B6B);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: Obx(() {
          final request = controller.currentTripRequest.value;
          if (request == null) return const SizedBox.shrink();

          final totalSeconds = request.expiresAt
              .difference(request.requestTime)
              .inSeconds
              .clamp(1, 120);
          final timeLeft = controller.requestTimeLeft.value;
          final progress = (timeLeft / totalSeconds).clamp(0.0, 1.0);
          final isUrgent = timeLeft <= 5;

          return ScaleTransition(
            scale: _scaleAnim,
            child: SafeArea(
              child: Column(
                children: [
                  // ── Top bar: countdown ring + "New Trip Request"
                  _TopBar(
                    progress: progress,
                    timeLeft: timeLeft,
                    isUrgent: isUrgent,
                    bg: bg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // ── Rider row
                            _RiderRow(
                              request: request,
                              surface: surface,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),

                            const SizedBox(height: 20),

                            // ── Fare + distance + duration
                            _TripStats(
                              request: request,
                              surface: surface,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                            ),

                            const SizedBox(height: 20),

                            // ── Route
                            _RouteCard(
                              request: request,
                              surface: surface,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              dark: dark,
                            ),

                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Sticky action bar at bottom
                  _ActionBar(controller: controller, bg: bg),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Top bar with ring countdown
// ──────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final double progress;
  final int timeLeft;
  final bool isUrgent;
  final Color bg;
  final Color textPrimary;
  final Color textSecondary;

  const _TopBar({
    required this.progress,
    required this.timeLeft,
    required this.isUrgent,
    required this.bg,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor =
        isUrgent ? const Color(0xFFFF3B30) : TColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Countdown ring
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(52, 52),
                  painter: _RingPainter(
                    progress: progress,
                    color: ringColor,
                  ),
                ),
                Obx(() {
                  final t = Get.find<TripManagementController>()
                      .requestTimeLeft
                      .value;
                  final urgent = t <= 5;
                  return Text(
                    '${t}s',
                    style: TextStyle(
                      color: urgent
                          ? const Color(0xFFFF3B30)
                          : TColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(width: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Trip Request',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isUrgent
                    ? 'Expiring soon — respond now'
                    : 'Tap Accept to confirm',
                style: TextStyle(
                  color: isUrgent
                      ? const Color(0xFFFF3B30)
                      : textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Rider name, rating, ride type
// ──────────────────────────────────────────────
class _RiderRow extends StatelessWidget {
  final TripRequest request;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  const _RiderRow({
    required this.request,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: TColors.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Iconsax.user, color: TColors.primary, size: 26),
        ),
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.riderName,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFB800), size: 16),
                  const SizedBox(width: 3),
                  Text(
                    request.riderRating.toStringAsFixed(1),
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: TColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      request.rideType.toUpperCase(),
                      style: TextStyle(
                        color: TColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Seats badge
        if (request.seats > 1)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.people, color: textSecondary, size: 15),
                const SizedBox(width: 4),
                Text(
                  '${request.seats}',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Fare + distance + duration stat row
// ──────────────────────────────────────────────
class _TripStats extends StatelessWidget {
  final TripRequest request;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  const _TripStats({
    required this.request,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Fare
          Expanded(
            child: _Stat(
              value: '₦${_fmt(request.estimatedFare)}',
              label: 'Fare',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              large: true,
            ),
          ),
          _Divider(),
          // Distance
          Expanded(
            child: _Stat(
              value:
                  '${request.estimatedDistance.toStringAsFixed(1)} km',
              label: 'Distance',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
          if (request.estimatedDuration > 0) ...[
            _Divider(),
            Expanded(
              child: _Stat(
                value: '${request.estimatedDuration} min',
                label: 'Duration',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double fare) {
    if (fare >= 1000) {
      return fare
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return fare.toStringAsFixed(0);
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color textPrimary;
  final Color textSecondary;
  final bool large;
  const _Stat({
    required this.value,
    required this.label,
    required this.textPrimary,
    required this.textSecondary,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: textPrimary,
            fontSize: large ? 20 : 16,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(color: textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.withOpacity(0.25),
    );
  }
}

// ──────────────────────────────────────────────
// Route card
// ──────────────────────────────────────────────
class _RouteCard extends StatelessWidget {
  final TripRequest request;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final bool dark;

  const _RouteCard({
    required this.request,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _RouteStop(
            dotColor: const Color(0xFF34C759),
            label: 'Pickup',
            address: request.pickupAddress,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
            child: Row(
              children: [
                Container(
                  width: 1.5,
                  height: 22,
                  margin:
                      const EdgeInsets.only(right: 22, left: 4.5),
                  color: Colors.grey.withOpacity(0.35),
                ),
              ],
            ),
          ),
          _RouteStop(
            dotColor: const Color(0xFFFF3B30),
            label: 'Drop-off',
            address: request.destinationAddress,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String address;
  final Color textPrimary;
  final Color textSecondary;

  const _RouteStop({
    required this.dotColor,
    required this.label,
    required this.address,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 16),
          child: Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Sticky bottom action bar
// ──────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  final TripManagementController controller;
  final Color bg;

  const _ActionBar({required this.controller, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.15), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Decline
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              controller.declineTripRequest();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Color(0xFFFF3B30), size: 26),
            ),
          ),

          const SizedBox(width: 14),

          // Accept
          Expanded(
            child: Obx(() {
              final loading = controller.isAccepting.value;
              return GestureDetector(
                onTap: loading
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        controller.acceptTripRequest();
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  decoration: BoxDecoration(
                    color: loading
                        ? const Color(0xFF34C759).withOpacity(0.7)
                        : const Color(0xFF34C759),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: loading
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFF34C759)
                                  .withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Center(
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : const Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Thin countdown ring painter
// ──────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 5) / 2;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
