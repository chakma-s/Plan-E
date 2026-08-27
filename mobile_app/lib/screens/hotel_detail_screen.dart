import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

class HotelDetailScreen extends StatelessWidget {
  const HotelDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final hotel = state.selectedProperty;

    if (hotel == null) {
      return const Scaffold(body: Center(child: Text("No hotel selected")));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Carousel
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: hotel.coverImageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade200),
              ),
            ),
          ),

          // Hotel Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            hotel.reviewScore.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${hotel.address}, ${hotel.city}",
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Dates Indicator Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppTheme.hotelAccent),
                        const SizedBox(width: 8),
                        Text(
                          "Stay: ${state.displayDateRange}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          "${state.currentPriceQuote?.totalNights ?? 1} Nights",
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text("About the Property", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    hotel.description,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Room Selection Section (Allocation Engine live counts)
                  const Text("Select Room Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...hotel.roomTypes.map((room) => _buildRoomCard(context, state, room)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Bottom Checkout CTA
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppTheme.divider)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOTAL ESTIMATE", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                Text(
                  state.currentPriceQuote != null
                      ? "\$${state.currentPriceQuote!.totalAmount.toStringAsFixed(2)}"
                      : "\$${state.selectedRoom?.currentPricePerNight?.toStringAsFixed(0) ?? '0'}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.hotelAccent),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.hotelAccent),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => const CheckoutScreen()));
                },
                child: const Text("Book Now", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, AppState state, RoomTypeModel room) {
    final isSelected = state.selectedRoom?.id == room.id;
    return GestureDetector(
      onTap: () => state.selectRoom(room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.hotelLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.hotelAccent : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: room.id,
              groupValue: state.selectedRoom?.id,
              activeColor: AppTheme.hotelAccent,
              onChanged: (_) => state.selectRoom(room),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${room.bedConfiguration} • Max ${room.maxOccupancy} Guests",
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  if (room.availableRooms != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "${room.availableRooms} rooms allocated",
                      style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              "\$${(room.currentPricePerNight ?? room.basePricePerNight).toStringAsFixed(0)} / night",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.hotelAccent),
            ),
          ],
        ),
      ),
    );
  }
}
