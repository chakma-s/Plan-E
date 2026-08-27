import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class BookingSuccessScreen extends StatelessWidget {
  final ReservationModel reservation;

  const BookingSuccessScreen({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final hasGuide = reservation.guideName != null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Success Badge
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: AppTheme.success, size: 64),
              ),
              const SizedBox(height: 16),
              const Text(
                "Reservation Confirmed!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                "Your room allocation has been atomically secured.",
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),

              // Reservation Code Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("RESERVATION CODE", style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          reservation.reservationCode,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20, color: AppTheme.textSecondary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: reservation.reservationCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Reservation code copied to clipboard!")),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stay Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    _buildRow("Property", reservation.propertyName),
                    const Divider(height: 20),
                    _buildRow("Dates", "${reservation.checkInDate} → ${reservation.checkOutDate}"),
                    const Divider(height: 20),
                    _buildRow("Total Paid", "\$${reservation.totalAmount.toStringAsFixed(2)} USD"),
                  ],
                ),
              ),

              // Bundled Local Guide Confirmation (if applicable)
              if (hasGuide) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.guideLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.guideGold.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppTheme.guideGold, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "BUNDLED LOCAL GUIDE",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.guideGold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reservation.guideName!,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const Text(
                              "Your guide will meet you at resort check-in.",
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 36),

              // Return to Home
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (ctx) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text("Return to Home Explorer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ],
    );
  }
}
