import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sarri Ride – User Agreement",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Jurisdiction: Federal Republic of Nigeria\nEffective Date: Jan 2026",
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              "Introduction",
              "This User Agreement (“Agreement”, “Terms”) governs your access to and use of the Sarri Ride mobile application... By downloading, installing, accessing, or using Sarri Ride, you confirm that you have read, understood, and agreed to be bound by these Terms.",
            ),

            _buildSection(
              "1. Company Information",
              "Sarri Ride is operated by Sarri Ride Limited, a company duly registered under the laws of the Federal Republic of Nigeria...",
            ),

            _buildSection(
              "2. Definitions",
              "“User” means any person who accesses or uses the Services.\n“Rider” means a User who requests transportation...\n“Driver” means a person who provides transportation services...",
            ),

            _buildSection(
              "3. Eligibility",
              "To use Sarri Ride, you must be at least 18 years of age, have legal capacity under Nigerian law...",
            ),

            _buildSection(
              "4. Nature of the Platform",
              "4.1 Independent Contractor Model (Current)\nSarri Ride Limited does not provide transportation services directly. Drivers are independent contractors.\n\n4.2 Future Employment Model\nSarri Ride Limited reserves the right to own vehicles or employ drivers directly in the future.",
            ),

            _buildSection(
              "5. User Accounts",
              "Users must create an account to access the Services and are responsible for maintaining confidentiality...",
            ),

            _buildSection(
              "6. Driver Obligations",
              "Drivers must hold a valid Nigerian driver’s license, maintain valid vehicle documentation...",
            ),

            _buildSection(
              "7. Rider Obligations",
              "Riders agree to provide accurate trip details, pay applicable fares, and treat drivers respectfully.",
            ),

            _buildSection(
              "8. Payments & Fees",
              "Fares are calculated based on distance, time, and demand. All payments are final except as required by Nigerian law.",
            ),

            _buildSection(
              "9. Cancellations",
              "Cancellation fees may apply. Repeated misuse may result in account termination.",
            ),

            _buildSection(
              "10. Ratings",
              "Users may submit truthful and respectful ratings. Sarri Ride may remove content violating Terms.",
            ),

            _buildSection(
              "11. Prohibited Conduct",
              "Users must not use the Services unlawfully, harass others, or provide false information.",
            ),

            _buildSection(
              "12. Safety Disclaimer",
              "Sarri Ride Limited does not guarantee user conduct. Use of Services is at the user’s own risk.",
            ),

            _buildSection(
              "13. Limitation of Liability",
              "Total liability shall not exceed the amount paid for the relevant trip.",
            ),

            _buildSection(
              "14. Indemnification",
              "Users agree to indemnify Sarri Ride Limited from claims arising from their use of the Services.",
            ),

            _buildSection(
              "15. Privacy Policy",
              "Personal data is processed in accordance with the Nigeria Data Protection Act (NDPA).",
            ),

            _buildSection(
              "16. Suspension",
              "Sarri Ride Limited may suspend access for violations or unsafe conduct.",
            ),

            _buildSection(
              "17. Changes to Terms",
              "We may amend these Terms at any time. Continued use constitutes acceptance.",
            ),

            _buildSection(
              "18. Governing Law",
              "Governed by the laws of the Federal Republic of Nigeria.",
            ),

            _buildSection(
              "19. Dispute Resolution",
              "Disputes shall first be resolved amicably, then submitted to Nigerian courts.",
            ),

            _buildSection(
              "20. Contact Information",
              "Sarri Ride Limited\nEmail: info@sarriride.com\nAddress:667B Tawaliyu Bello Aromire Street, Omole Phase ",
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}
