// lib/features/referral/controllers/referral_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sarri_ride/config/api_config.dart';
import 'package:sarri_ride/core/services/http_service.dart';
import 'package:sarri_ride/features/referral/models/referral_model.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';
import 'package:share_plus/share_plus.dart';

class ReferralController extends GetxController {
  static ReferralController get instance => Get.find();

  final HttpService _http = HttpService.instance;

  // ── Observables ──────────────────────────────────────────────────────────

  final Rx<ReferralModel?> referral = Rx<ReferralModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isApplyingCode = false.obs;
  final RxString error = ''.obs;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    loadReferralProfile();
  }

  // ── Load Profile ─────────────────────────────────────────────────────────

  Future<void> loadReferralProfile() async {
    isLoading.value = true;
    error.value = '';
    try {
      // 1. Create or get the referral profile
      final profileRes = await _http.get(ApiConfig.referralProfileEndpoint);
      final profileData = _http.handleResponse(profileRes);

      // 2. Also fetch full stats (history etc.)
      final statsRes = await _http.get(ApiConfig.referralStatsEndpoint);
      final statsData = _http.handleResponse(statsRes);

      // Merge profile + stats into a single model
      final merged = <String, dynamic>{
        ...profileData['data'] as Map<String, dynamic>? ?? {},
        'stats': (statsData['data'] as Map<String, dynamic>?)?['stats'] ?? {},
        'recentReferrals': (statsData['data'] as Map<String, dynamic>?)?['recentReferrals'] ?? [],
        'hasReferralProfile': true,
      };
      referral.value = ReferralModel.fromJson(merged);
    } on ApiException catch (e) {
      error.value = e.message;
      debugPrint('ReferralController: Failed to load profile — ${e.message}');
    } catch (e) {
      error.value = 'Failed to load referral data.';
      debugPrint('ReferralController: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Apply Referral Code (called post-signup) ──────────────────────────────

  Future<bool> applyReferralCode(String code) async {
    if (code.trim().isEmpty) return false;
    isApplyingCode.value = true;
    try {
      final res = await _http.post(
        ApiConfig.referralApplyEndpoint,
        body: {'referralCode': code.trim().toUpperCase()},
      );
      _http.handleResponse(res);
      THelperFunctions.showSnackBar('Referral code applied! 🎉');
      return true;
    } on ApiException catch (e) {
      // Non-fatal — don't block the user from using the app
      debugPrint('ReferralController: Code apply failed — ${e.message}');
      // Only show error if it's not "already used" (common benign case)
      if (!e.message.toLowerCase().contains('already')) {
        THelperFunctions.showSnackBar('Referral: ${e.message}');
      }
      return false;
    } finally {
      isApplyingCode.value = false;
    }
  }

  // ── Validate Code (before applying) ──────────────────────────────────────

  Future<Map<String, dynamic>?> validateReferralCode(String code) async {
    if (code.trim().isEmpty) return null;
    try {
      final res = await _http.post(
        ApiConfig.referralValidateEndpoint,
        body: {'referralCode': code.trim().toUpperCase()},
        requiresAuth: false,
      );
      final data = _http.handleResponse(res);
      if (data['valid'] == true) return data['data'] as Map<String, dynamic>?;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Calculate how many points to apply to a ride ─────────────────────────

  Future<Map<String, dynamic>?> calculatePointsForRide(double tripPrice) async {
    if ((referral.value?.availablePoints ?? 0) == 0) return null;
    try {
      final res = await _http.post(
        ApiConfig.referralCalculateDiscountEndpoint,
        body: {'tripPrice': tripPrice},
      );
      final data = _http.handleResponse(res);
      return data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── Share Referral Code ───────────────────────────────────────────────────

  void shareReferralCode() {
    final code = referral.value?.referralCode;
    if (code == null) return;
    final nairaValue = referral.value?.nairaBalance ?? 0;
    final message = nairaValue > 0
        ? 'Join me on SarriRide! Use my referral code **$code** when signing up. '
          'I earn Sarri Points worth ₦${nairaValue.toStringAsFixed(0)} already. '
          'sarriride://signup?ref=$code'
        : 'Join me on SarriRide! Use my code **$code** at signup. '
          'sarriride://signup?ref=$code';
    Share.share(message, subject: 'Join SarriRide with my referral code');
  }

  // ── Convenience getters ───────────────────────────────────────────────────

  bool get isSalesPerson => referral.value?.referralType == 'sales_person';

  bool get isRider => referral.value?.referralType == 'rider';

  String get displayPoints {
    final pts = referral.value?.availablePoints ?? 0;
    final naira = referral.value?.nairaBalance ?? 0;
    return '$pts pts (≈₦${naira.toStringAsFixed(0)})';
  }

  String get tierDisplayName {
    final t = referral.value?.tier ?? 'bronze';
    return t[0].toUpperCase() + t.substring(1);
  }

  Color get tierColor {
    switch (referral.value?.tier) {
      case 'silver':   return const Color(0xFF9E9E9E);
      case 'gold':     return const Color(0xFFFFB300);
      case 'platinum': return const Color(0xFF42A5F5);
      case 'diamond':  return const Color(0xFF9C27B0);
      default:         return const Color(0xFFFF7043); // bronze
    }
  }
}
