// lib/features/authentication/widgets/sign_in_update_notice.dart
//
// One-time notice explaining that email/password sign-in has been replaced
// by Google/Apple. Shown in two places, each with its own dismissal flag:
//   - the Login screen, for people actively trying to sign in and wondering
//     where the password field went;
//   - the rider/driver home, so people who are still signed in hear about it
//     before their session expires rather than after.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/constants/sizes.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

/// Where the notice is being shown from — each surface is dismissed
/// independently, so seeing it on Login doesn't suppress it on Home.
enum SignInNoticeSurface { login, home }

class SignInUpdateNotice extends StatelessWidget {
  final SignInNoticeSurface surface;

  const SignInUpdateNotice({super.key, required this.surface});

  static String _storageKey(SignInNoticeSurface surface) =>
      'seen_social_login_notice_${surface.name}';

  /// Surfaces already queued this session. The storage flag is only written
  /// on dismissal, so without this a StatelessWidget rebuilding before the
  /// user taps "Got it" would stack duplicate dialogs.
  static final Set<SignInNoticeSurface> _queued = {};

  /// Shows the notice once per surface. Safe to call unconditionally from
  /// initState or build — it no-ops if already acknowledged or queued.
  static void maybeShow(SignInNoticeSurface surface) {
    if (_queued.contains(surface)) return;
    if (GetStorage().read(_storageKey(surface)) == true) return;
    _queued.add(surface);

    // Defer to the next frame so callers can fire this during initState or
    // build, before the first frame has settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.dialog(
        SignInUpdateNotice(surface: surface),
        barrierDismissible: false,
      );
    });
  }

  void _acknowledge() {
    GetStorage().write(_storageKey(surface), true);
    if (Get.isDialogOpen ?? false) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final isHome = surface == SignInNoticeSurface.home;

    return Dialog(
      backgroundColor: dark ? TColors.dark : TColors.white,
      insetPadding: const EdgeInsets.all(TSizes.defaultSpace),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(TSizes.sm),
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
              ),
              child: const Icon(
                Iconsax.shield_tick,
                color: TColors.primary,
                size: TSizes.iconMd,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            Text(
              'Signing in has changed',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: TSizes.sm),

            Text(
              isHome
                  ? 'Next time you sign in, use Continue with Google or Apple '
                      'instead of a password. Pick the same email you use now — '
                      'your account, trips and saved places stay exactly as they are.'
                  : 'Passwords are no longer needed. Tap Continue with Google or '
                      'Apple and choose the same email you have always used — '
                      'your account, trips and saved places stay exactly as they are.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark ? TColors.lightGrey : TColors.darkGrey,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: TSizes.spaceBtwSections),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _acknowledge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: TColors.white,
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
