import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../widgets/guide_bundle_sheet.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

class ResortDetailScreen extends StatelessWidget {
  const ResortDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final resort = state.selectedProperty;

    if (resort == null) {
      return const Scaffold(body: Center(child: Text("No resort selected")));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Luxury Hero Visual Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: resort.coverImageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade200),
              ),
            ),
          ),

          // Resort Details & Local Guide Bundling Roster
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title, Location, and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resort.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (resort.tagline != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                resort.tagline!,
                                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppTheme.resortAccent),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.resortLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.resortAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              resort.reviewScore.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.resortAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        const Icon(Icons.calendar_month, size: 16, color: AppTheme.resortAccent),
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

                  // Amenities Chips
                  const Text("Sanctuary Amenities", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: resort.amenities.map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.resortLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.resortAccent.withOpacity(0.2)),
                        ),
                        child: Text(
                          a,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.resortAccent),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Room & Villa Selection
                  const Text("Select Villa or Suite", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...resort.roomTypes.map((room) => _buildVillaCard(context, state, room)),
                  const SizedBox(height: 28),

                  // -----------------------------------------------------------
                  // THE LOCAL GUIDE BUNDLING SECTION (Core Mandatory Feature)
                  // -----------------------------------------------------------
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.guideLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.guideGold.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.explore, color: AppTheme.guideGold, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              "Bundle a Certified Local Guide",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Enhance your resort stay by bundling a dedicated local expert for curated wildlife, snorkeling, and cultural expeditions.",
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 16),

                        // Guides Roster
                        if (resort.associatedGuides.isEmpty)
                          const Text("No resident guides assigned to this resort currently.", style: TextStyle(fontSize: 12))
                        else
                          ...resort.associatedGuides.map((guide) => _buildGuideBundleCard(context, state, guide)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Bottom Bundled Quote & Checkout Action
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
                Row(
                  children: [
                    const Text("ESTIMATED TOTAL", style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    if (state.selectedGuideBundle != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.guideLight, borderRadius: BorderRadius.circular(4)),
                        child: const Text("GUIDE BUNDLED", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.guideGold)),
                      ),
                    ],
                  ],
                ),
                Text(
                  state.currentPriceQuote != null
                      ? "\$${state.currentPriceQuote!.totalAmount.toStringAsFixed(2)}"
                      : "\$${state.selectedRoom?.currentPricePerNight?.toStringAsFixed(0) ?? '0'}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.resortAccent),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.resortAccent),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => const CheckoutScreen()));
                },
                child: Text(
                  state.selectedGuideBundle != null ? "Book Bundled Stay" : "Reserve Stay",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVillaCard(BuildContext context, AppState state, RoomTypeModel room) {
    final isSelected = state.selectedRoom?.id == room.id;
    return GestureDetector(
      onTap: () => state.selectRoom(room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.resortLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.resortAccent : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: room.id,
              groupValue: state.selectedRoom?.id,
              activeColor: AppTheme.resortAccent,
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
                ],
              ),
            ),
            Text(
              "\$${(room.currentPricePerNight ?? room.basePricePerNight).toStringAsFixed(0)} / night",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.resortAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideBundleCard(BuildContext context, AppState state, LocalGuideModel guide) {
    final isBundled = state.selectedGuideBundle?.id == guide.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBundled ? Colors.white : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBundled ? AppTheme.guideGold : AppTheme.divider,
          width: isBundled ? 2 : 1,
        ),
        boxShadow: isBundled
            ? [BoxShadow(color: AppTheme.guideGold.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CachedNetworkImage(
                  imageUrl: guide.profilePhotoUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          guide.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        if (guide.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 14, color: Colors.blueAccent),
                        ],
                      ],
                    ),
                    Text(
                      guide.headline,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "⭐ ${guide.rating.toStringAsFixed(1)} • \$${guide.dailyRate.toStringAsFixed(0)} / day",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.guideGold),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isBundled,
                activeColor: AppTheme.guideGold,
                onChanged: (_) => state.toggleGuideBundle(guide),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                onPressed: () {
                  GuideBundleSheet.show(
                    context,
                    guide: guide,
                    isBundled: isBundled,
                    onToggleBundle: () => state.toggleGuideBundle(guide),
                  );
                },
                icon: const Icon(Icons.info_outline, size: 14, color: AppTheme.guideGold),
                label: const Text("View Credentials & Bio", style: TextStyle(fontSize: 11, color: AppTheme.guideGold)),
              ),
              Text(
                isBundled ? "BUNDLED WITH STAY" : "TAP CHECKBOX TO BUNDLE",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isBundled ? AppTheme.success : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
