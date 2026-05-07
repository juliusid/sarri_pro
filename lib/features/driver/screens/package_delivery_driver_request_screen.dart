import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sarri_ride/features/driver/controllers/package_delivery_driver_controller.dart';
import 'package:sarri_ride/utils/constants/colors.dart';
import 'package:sarri_ride/utils/helpers/helper_functions.dart';

class PackageDeliveryDriverRequestScreen extends StatelessWidget {
  const PackageDeliveryDriverRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PackageDeliveryDriverController>();
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Delivery'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Iconsax.arrow_left_2,
            color: dark ? TColors.white : TColors.black,
          ),
        ),
      ),
      body: Obx(() {
        final step = controller.step.value;

        if (step == PackageDeliveryDriverStep.request) {
          return _buildRequestStep(controller, context);
        }

        if (step == PackageDeliveryDriverStep.accepted) {
          return _buildPickupConfirmStep(controller);
        }

        if (step == PackageDeliveryDriverStep.pickupConfirmed) {
          return _buildStartStep(controller);
        }

        if (step == PackageDeliveryDriverStep.started) {
          return _buildArriveStep(controller);
        }

        if (step == PackageDeliveryDriverStep.arrived ||
            step == PackageDeliveryDriverStep.awaitingDeliveryConfirmation) {
          return _buildDeliveryConfirmStep(controller);
        }

        if (step == PackageDeliveryDriverStep.delivered) {
          return const Center(
            child: Text('Delivery confirmed. Waiting for payment...'),
          );
        }

        return const Center(child: CircularProgressIndicator());
      }),
    );
  }

  Widget _buildRequestStep(
    PackageDeliveryDriverController controller,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New package request',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text('From: ${controller.currentLocationName.value}'),
          Text('To: ${controller.destinationName.value}'),
          const SizedBox(height: 12),
          Text('Pickup code: ${controller.pickupCode.value}'),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Iconsax.close_circle),
                  label: const Text('Reject'),
                  onPressed: () {
                    controller.rejectRequest().then((_) => Get.back());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Iconsax.check),
                  label: const Text('Accept'),
                  onPressed: () async {
                    await controller.acceptRequest();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupConfirmStep(PackageDeliveryDriverController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirm pickup'),
          const SizedBox(height: 12),
          Text('Use pickup code: ${controller.pickupCode.value}'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.tick_circle),
              label: const Text('Confirm Pickup'),
              style: ElevatedButton.styleFrom(backgroundColor: TColors.success),
              onPressed: () async {
                await controller.confirmPickup();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartStep(PackageDeliveryDriverController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Start delivery'),
          const SizedBox(height: 12),
          const Text('This will call `/package_delivery/start-delivery-trip`.'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.play),
              label: const Text('Start Trip'),
              style: ElevatedButton.styleFrom(backgroundColor: TColors.info),
              onPressed: () async {
                await controller.startTrip();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArriveStep(PackageDeliveryDriverController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Arrive at dropoff'),
          const SizedBox(height: 12),
          const Text('This will call `/package_delivery/arrive-at-dropoff`.'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.location_cross),
              label: const Text('Arrived'),
              style: ElevatedButton.styleFrom(backgroundColor: TColors.warning),
              onPressed: () async {
                await controller.arriveAtDropoff();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryConfirmStep(PackageDeliveryDriverController controller) {
    final deliveryCodeController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirm delivery'),
          const SizedBox(height: 12),
          Text('Recipient: ${controller.receiverName.value}'),
          Text('Enter delivery code (6 digits)'),
          const SizedBox(height: 12),
          TextField(
            controller: deliveryCodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g. 482931',
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.tick_square),
              label: const Text('Confirm Delivery'),
              style: ElevatedButton.styleFrom(backgroundColor: TColors.success),
              onPressed: () async {
                await controller.confirmDeliveryWithCode(
                  deliveryCodeController.text,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
