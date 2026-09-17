import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/hotel_card.dart';
import '../widgets/mapbox_map_view.dart';
import '../theme/app_theme.dart';
import 'hotel_detail_screen.dart';
import '../widgets/skeleton_loader.dart';

class HotelSearchScreen extends StatefulWidget {
  const HotelSearchScreen({super.key});

  @override
  State<HotelSearchScreen> createState() => _HotelSearchScreenState();
}

class _HotelSearchScreenState extends State<HotelSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(viewportFraction: 0.88);
  String? _selectedHotelId;
  String selectedSort = 'recommended';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isMapView = state.isHotelMapView;

    return Column(
      children: [
        // Fast Search Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppTheme.getCardColor(context),
          child: Column(
            children: [
              // Search Input
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.getDividerColor(context)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: "Where to? (e.g. Bangalore, San Francisco)",
                    prefixIcon: const Icon(Icons.search, color: AppTheme.hotelAccent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              state.fetchHotels();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (query) {
                    state.fetchHotels(city: query, sortBy: selectedSort);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips (Date Range, Sort, View Toggle)
              Row(
                children: [
                  // Date Range Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        side: BorderSide(color: AppTheme.getDividerColor(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _selectDateRange(context, state),
                      icon: const Icon(Icons.calendar_today, size: 14, color: AppTheme.hotelAccent),
                      label: Text(
                        state.displayDateRange,
                        style: TextStyle(fontSize: 11, color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      side: BorderSide(color: AppTheme.getDividerColor(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.tune, size: 14, color: AppTheme.hotelAccent),
                    label: Text("Filters", style: TextStyle(fontSize: 11, color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      side: BorderSide(color: AppTheme.getDividerColor(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      state.toggleHotelMapView();
                    },
                    icon: Icon(isMapView ? Icons.list : Icons.map, size: 14, color: AppTheme.hotelAccent),
                    label: Text(isMapView ? "List" : "Map", style: TextStyle(fontSize: 11, color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Body: Map View with Bottom Carousel or List View
        Expanded(
          child: state.isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: 3,
                  itemBuilder: (context, index) => const SkeletonCard(),
                )
              : isMapView
                  ? Stack(
                      children: [
                        MapboxMapView(
                          properties: state.hotelResults,
                          selectedPropertyId: _selectedHotelId,
                          showBottomMiniCard: false,
                          onPropertyTap: (prop) {
                            setState(() {
                              _selectedHotelId = prop.id;
                            });
                            final idx = state.hotelResults.indexWhere((h) => h.id == prop.id);
                            if (idx != -1 && _pageController.hasClients) {
                              _pageController.animateToPage(
                                idx,
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          onPropertySelected: (prop) => _navigateToDetail(context, state, prop.id),
                        ),
                        if (state.hotelResults.isNotEmpty)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            height: 110,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: state.hotelResults.length,
                              onPageChanged: (idx) {
                                final h = state.hotelResults[idx];
                                setState(() {
                                  _selectedHotelId = h.id;
                                });
                              },
                              itemBuilder: (context, idx) {
                                final h = state.hotelResults[idx];
                                return _buildCarouselCard(context, state, h);
                              },
                            ),
                          ),
                      ],
                    )
                  : state.errorMessage != null
                      ? _buildErrorState(state)
                      : state.hotelResults.isEmpty
                          ? _buildEmptyState(state)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: state.hotelResults.length,
                          itemBuilder: (context, idx) {
                            final hotel = state.hotelResults[idx];
                            return HotelCard(
                              hotel: hotel,
                              isSelected: hotel.id == _selectedHotelId,
                              onTap: () => _navigateToDetail(context, state, hotel.id),
                              onLocateTap: () {
                                setState(() {
                                  _selectedHotelId = hotel.id;
                                });
                                state.toggleHotelMapView();
                              },
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(BuildContext context, AppState state, HotelCardModel h) {
    final isSelected = h.id == _selectedHotelId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHotelId = h.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.hotelAccent : AppTheme.divider,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                h.coverImageUrl,
                width: 80,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.hotel, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    h.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${h.city} • ★ ${h.reviewScore.toStringAsFixed(1)}",
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\$${h.minPricePerNight.toStringAsFixed(0)} / night",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.hotelAccent),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.hotelAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: Size.zero,
              ),
              onPressed: () => _navigateToDetail(context, state, h.id),
              child: const Text("View", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, AppState state) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: state.checkInDate, end: state.checkOutDate),
    );
    if (picked != null) {
      state.setDates(picked.start, picked.end);
    }
  }

  void _navigateToDetail(BuildContext context, AppState state, String hotelId) async {
    try {
      final detail = await state.api.getHotelDetail(
        hotelId,
        checkIn: state.formattedCheckIn,
        checkOut: state.formattedCheckOut,
      );
      state.selectProperty(detail);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const HotelDetailScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildErrorState(AppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              "Unable to load hotels",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context)),
            ),
            const SizedBox(height: 6),
            Text(
              state.errorMessage ?? "An unexpected network error occurred.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => state.fetchHotels(),
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hotel_outlined, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            "No hotels found for your dates.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context)),
          ),
          const SizedBox(height: 6),
          Text(
            "Try expanding your date range or searching another city.",
            style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              state.fetchHotels();
            },
            child: const Text("Reset Search"),
          ),
        ],
      ),
    );
  }
}
