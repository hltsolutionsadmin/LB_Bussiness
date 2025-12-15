import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF97316), Color(0xFFEA580C), Color(0xFFDC2626)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade50, Colors.white],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Local Basket – Admin & Restaurant Admin App',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Last Updated: 01 Dec 2025',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _lead(),
                            const SizedBox(height: 16),
                            _section('1. Eligibility & Access', const [
                              'Only authorized Admin Users approved by Local Basket may access the Admin App.',
                              'You must provide valid and accurate information during registration or onboarding.',
                              'Login credentials (username, password, OTP, etc.) are strictly assigned to individual Admin Users and must not be shared.',
                              'Local Basket reserves the right to verify, modify, restrict, or revoke access at any time.',
                            ]),
                            _section('2. Administrative Roles & Responsibilities', const [
                              'For All Admin Users: You are responsible for managing data assigned to you within the App (restaurants, orders, users, operations, etc.).',
                              'All data entered or updated must be accurate, lawful, and compliant with Local Basket policies.',
                              'Any misuse of admin privileges, such as unauthorized data changes, fraudulent behavior, or deletion of records, may result in suspension or legal action.',
                              'For Restaurant Admins (Specific Responsibilities): You must ensure restaurant details such as Menu items, Pricing, Stock availability, Delivery timings, Offer updates remain accurate and up to date.',
                              'Any incorrect data added by Restaurant Admins will not be the responsibility of Local Basket.',
                            ]),
                            _section('3. Security & Credential Protection', const [
                              'Admin Users must always maintain the confidentiality of their login credentials.',
                              'Local Basket is not responsible for unauthorized access caused by sharing passwords or OTPs, weak passwords, device loss, or credential leakage.',
                              'You must report suspicious activities or unauthorized access immediately.',
                            ]),
                            _section('4. Proper & Authorized Use', const [
                              'The Admin App must be used only for approved administrative tasks.',
                              'You must not manipulate or tamper with system data, access sections beyond your permission, or use the app for personal, illegal, or unrelated business purposes.',
                              'Use the app on an updated device with a stable internet connection for best performance.',
                            ]),
                            _section('5. Data Management & Accountability', const [
                              'All actions taken in the Admin App using your account are your responsibility.',
                              'Local Basket is not responsible for wrong data entry, accidental deletion, incomplete updates, or operational disruptions caused by incorrect configurations.',
                              'Ensure data accuracy and follow proper verification steps before saving updates.',
                            ]),
                            _section('6. Privacy & Confidentiality', const [
                              'Do not share customer, restaurant, order, or business information with unauthorized persons.',
                              'All data accessed through the Admin App is confidential and protected under Local Basket’s Privacy Policy.',
                              'Screenshots, recordings, or sharing of internal information is strictly prohibited.',
                            ]),
                            _section('7. Professional Conduct & Compliance', const [
                              'Admin Users must act ethically, responsibly, and professionally.',
                              'Any fraudulent behavior, policy violation, or misuse of admin access will lead to immediate action, including suspension or legal steps.',
                            ]),
                            _section('8. Limitation of Liability', const [
                              'Local Basket is not liable for misuse of admin access due to carelessness or credential sharing, incorrect updates performed by Admin Users, loss of data caused by negligence, or operational issues caused by wrong configuration by Restaurant Admins.',
                              'Admin Users accept full responsibility for all activities performed using their account.',
                            ]),
                            _section('9. Suspension & Termination', const [
                              'Local Basket may suspend or permanently terminate access for misuse of admin privileges, security violations, unauthorized data sharing, breach of confidentiality, submission of false information, or violation of any Terms mentioned here.',
                            ]),
                            _section('10. Updates to Terms', const [
                              'Local Basket may update or modify these Terms at any time.',
                              'Notifications will be provided through the Admin App or registered communication channels.',
                              'Continuing to use the App after updates means you accept the revised Terms.',
                            ]),
                            const SizedBox(height: 24),
                            Center(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B35),
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                  shadowColor: const Color(
                                    0xFFFF6B35,
                                  ).withOpacity(0.4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text(
                                  'I Understand',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _lead() {
    return const Text(
      'These Terms & Conditions ("Terms") govern the use of the Local Basket Admin Application ("Admin App") by all authorized individuals ("Admin Users", "You"), including Local Basket Internal Admins and Restaurant Admins. By accessing or using the Admin App, you agree to follow all rules and responsibilities listed below.',
      style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF374151)),
    );
  }

  static Widget _section(String title, List<String> bullets) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
