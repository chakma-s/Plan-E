import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../widgets/guide_bundle_sheet.dart';
import '../widgets/photo_gallery_dialog.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

class ResortDetailScreen extends StatefulWidget {
  const ResortDetailScreen({super.key});

  @override
  State<ResortDetailScreen> createState() => _ResortDetailScreenState();
}

class _ResortDetailScreenState extends State<ResortDetailScreen> {
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final resort = state.selectedProperty;

    if (resort == null) {
      return const Scaffold(body: Center(child: Text("No resort selected")));
    }

    final allImages = [
      resort.coverImageUrl,
      ...resort.galleryImages,
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Luxury Hero Visual Header with Interactive Photo Carousel
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _imagePageController,
                    itemCount: allImages.length,
                    onPageChanged: (idx) {
                      setState(() => _currentImageIndex = idx);
                    },
                    itemBuilder: (context, idx) {
                      return GestureDetector(
                        onTap: () => showPhotoGallery(
                          context,
                          allImages,
                          initialIndex: _currentImageIndex,
                          title: resort.name,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: allImages[idx],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey.shade300),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),

                  // Gradient Scrim
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.65),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Top Sanctuary Pill
                  Positioned(
                    top: 48,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.spa, color: AppTheme.resortAccent, size: 14),
                          SizedBox(width: 4),
                          Text("Sanctuary", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Controls
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.photo_library, color: Colors.white, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                "${_currentImageIndex + 1} / ${allImages.length} Photos",
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => showPhotoGallery(
                            context,
                            allImages,
                            initialIndex: _currentImageIndex,
                            title: resort.name,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.resortAccent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.fullscreen, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "View Gallery",
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  const SizedBox(height: 6),
                  Text(
                    "${resort.address}, ${resort.city}",
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Extra Images Horizontal Preview Ribbon
                  if (allImages.length > 1) ...[
                    SizedBox(
                      height: 52,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: allImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final isSelected = idx == _currentImageIndex;
                          return GestureDetector(
                            onTap: () {
                              _imagePageController.animateToPage(
                                idx,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppTheme.resortAccent : AppTheme.divider,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: allImages[idx],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Select Villa or Suite", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(
                        "${resort.roomTypes.length} Available",
                        style: const TextStyle(fontSize: 12, color: AppTheme.resortAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
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
                Text(
                  state.selectedGuideBundle != null ? "BUNDLED ESTIMATE" : "TOTAL ESTIMATE",
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
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
                  state.selectedGuideBundle != null ? "Book Bundled Stay" : "Reserve Selected Room",
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
    final roomImage = room.images.isNotEmpty ? room.images.first : null;

    return GestureDetector(
      onTap: () => state.selectRoom(room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.resortLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.resortAccent : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.resortAccent.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Image Thumbnail with Photo Count & Lightbox Trigger
                if (roomImage != null)
                  GestureDetector(
                    onTap: () {
                      if (room.images.isNotEmpty) {
                        showPhotoGallery(context, room.images, title: room.name);
                      }
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: roomImage,
                            width: 88,
                            height: 72,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(width: 88, height: 72, color: Colors.grey.shade200),
                          ),
                        ),
                        if (room.images.length > 1)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.camera_alt, color: Colors.white, size: 9),
                                  const SizedBox(width: 2),
                                  Text(
                                    "${room.images.length}",
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(width: 12),

                // Room Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${room.bedConfiguration} • Max ${room.maxOccupancy} Guests",
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      if (room.description != null && room.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          room.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),

                // Selection Radio
                Radio<String>(
                  value: room.id,
                  groupValue: state.selectedRoom?.id,
                  activeColor: AppTheme.resortAccent,
                  onChanged: (_) => state.selectRoom(room),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Amenities row & Price row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (room.amenities.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: room.amenities.take(3).map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(a, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                        );
                      }).toList(),
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  "\$${(room.currentPricePerNight ?? room.basePricePerNight).toStringAsFixed(0)} / night",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.resortAccent),
                ),
              ],
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
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppTheme.resortAccent, size: 14),
                      ],
                    ),
                    Text(
                      guide.headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          "${guide.rating.toStringAsFixed(1)} (${guide.reviewCount})",
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "+ \$${guide.dailyRate.toStringAsFixed(0)} / day",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.guideGold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  GuideBundleSheet.show(
                    context,
                    guide: guide,
                    isBundled: isBundled,
                    onToggleBundle: () => state.toggleGuideBundle(guide),
                  );
                },
                child: const Text("View Profile", style: TextStyle(fontSize: 11, color: AppTheme.guideGold, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBundled ? Colors.red.shade400 : AppTheme.guideGold,
                  foregroundColor: isBundled ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => state.toggleGuideBundle(guide),
                icon: Icon(isBundled ? Icons.remove_circle_outline : Icons.add_circle_outline, size: 14),
                label: Text(
                  isBundled ? "Remove Bundle" : "Bundle Guide",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
