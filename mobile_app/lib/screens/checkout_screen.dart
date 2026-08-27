import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'booking_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final prop = state.selectedProperty;
    final room = state.selectedRoom;
    final quote = state.currentPriceQuote;
    final guide = state.selectedGuideBundle;

    if (prop == null || room == null || quote == null) {
      return const Scaffold(body: Center(child: Text("Missing booking details")));
    }

    final isResort = prop.propertyType == "RESORT";
    final themeColor = isResort ? AppTheme.resortAccent : AppTheme.hotelAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm & Checkout"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: prop.coverImageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isResort ? AppTheme.resortLight : AppTheme.hotelLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isResort ? "RESORT & VILLA" : "CITY HOTEL",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: themeColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prop.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${prop.city}, ${prop.country}",
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stay Schedule Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDateCol("CHECK-IN", state.formattedCheckIn),
                      Icon(Icons.arrow_forward, color: themeColor, size: 18),
                      _buildDateCol("CHECK-OUT", state.formattedCheckOut),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Selected Room: ${room.name}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text("${quote.totalNights} Nights", style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // LOCAL GUIDE BUNDLED ITEM (If present)
            // -----------------------------------------------------------------
            if (guide != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.guideLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.guideGold.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified, color: AppTheme.guideGold, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          "Bundled Local Tour Guide",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.guideGold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.guideGold, borderRadius: BorderRadius.circular(6)),
                          child: const Text("ATTACHED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: CachedNetworkImageProvider(guide.profilePhotoUrl),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(guide.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text(
                                "${guide.specialties.take(2).join(' • ')}",
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "\$${guide.dailyRate.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.guideGold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Itemized Financial Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Price Breakdown", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _buildPriceRow(
                    "Room Subtotal (${quote.totalNights} nights)",
                    "\$${quote.roomSubtotal.toStringAsFixed(2)}",
                  ),
                  if (guide != null) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow(
                      "Local Guide Fee (1 Day Bundled)",
                      "\$${quote.guideSubtotal.toStringAsFixed(2)}",
                      color: AppTheme.guideGold,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    "Platform Service Fee (5%)",
                    "\$${quote.platformFee.toStringAsFixed(2)}",
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    "Estimated Lodging Tax (8.5%)",
                    "\$${quote.taxAmount.toStringAsFixed(2)}",
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Grand Total",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                      ),
                      Text(
                        "\$${quote.totalAmount.toStringAsFixed(2)} USD",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: themeColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Submit Booking Action
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                onPressed: isProcessing ? null : () => _submitReservation(context, state),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Confirm & Pay \$${quote.totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "Guaranteed zero overbooking via database row allocation locking.",
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCol(String label, String dateStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(dateStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _submitReservation(BuildContext context, AppState state) async {
    setState(() {
      isProcessing = true;
    });

    try {
      final reservation = await state.finalizeBooking();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (ctx) => BookingSuccessScreen(reservation: reservation)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppTheme.error, content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }
}
