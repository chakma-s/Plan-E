import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  List<ReservationModel> reservations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final state = Provider.of<AppState>(context, listen: false);
    if (!state.isAuthenticated) {
      await state.loginAsBetaUser();
    }
    try {
      final items = await state.api.getMyReservations();
      if (mounted) {
        setState(() {
          reservations = items;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Reservations"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reservations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reservations.length,
                  itemBuilder: (context, idx) {
                    final res = reservations[idx];
                    final isResort = res.bookingType.contains("RESORT");
                    final hasGuide = res.guideName != null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.divider),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isResort ? AppTheme.resortLight : AppTheme.hotelLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isResort ? "RESORT STAY" : "CITY HOTEL",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isResort ? AppTheme.resortAccent : AppTheme.hotelAccent,
                                  ),
                                ),
                              ),
                              Text(
                                res.reservationCode,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            res.propertyName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${res.checkInDate} → ${res.checkOutDate} (${res.totalNights} nights)",
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                          if (hasGuide) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.guideLight.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified, size: 14, color: AppTheme.guideGold),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Bundled Guide: ${res.guideName}",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.guideGold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Paid: \$${res.totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w700)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "CONFIRMED",
                                  style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.luggage_outlined, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          const Text("No active bookings found.", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text("Your confirmed reservations will appear here.", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
