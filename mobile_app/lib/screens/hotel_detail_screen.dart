import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/photo_gallery_dialog.dart';
import 'checkout_screen.dart';

class HotelDetailScreen extends StatefulWidget {
  const HotelDetailScreen({super.key});

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
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
    final hotel = state.selectedProperty;

    if (hotel == null) {
      return const Scaffold(body: Center(child: Text("No hotel selected")));
    }

    final allImages = [
      hotel.coverImageUrl,
      ...hotel.galleryImages,
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Interactive Image Carousel & Gallery Indicator
          SliverAppBar(
            expandedHeight: 270,
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
                          title: hotel.name,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: allImages[idx],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey.shade300),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),

                  // Gradient scrim
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom bar with Photo Counter & Fullscreen button
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
                            title: hotel.name,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.hotelAccent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.fullscreen, color: Colors.black, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "View Gallery",
                                  style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800),
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
                                  color: isSelected ? AppTheme.hotelAccent : AppTheme.divider,
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

                  // Amenities Chips
                  const Text("Hotel Amenities", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hotel.amenities.map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Text(
                          a,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                      );
                    }).toList(),
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

                  // Room Selection Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Available Rooms & Suites", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(
                        "${hotel.roomTypes.length} Options",
                        style: const TextStyle(fontSize: 12, color: AppTheme.hotelAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...hotel.roomTypes.map((room) => _buildRoomCard(context, state, room)),
                  const SizedBox(height: 90),
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
                child: const Text("Book Selected Room", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, AppState state, RoomTypeModel room) {
    final isSelected = state.selectedRoom?.id == room.id;
    final roomImage = room.images.isNotEmpty ? room.images.first : null;

    return GestureDetector(
      onTap: () => state.selectRoom(room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.hotelLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.hotelAccent : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.hotelAccent.withOpacity(0.12),
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
                  activeColor: AppTheme.hotelAccent,
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
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.hotelAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
