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
  String? _selectedHotelId;
  String selectedSort = 'recommended';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHotel(String id, List<HotelCardModel> list) {
    final idx = list.indexWhere((h) => h.id == id);
    if (idx != -1 && _scrollController.hasClients) {
      final target = (idx * 320.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
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
                  border: Border.all(color: AppTheme.getInputBorderColor(context)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: "Where to? (e.g. Bangalore, San Francisco)",
                    hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.hotelAccent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: AppTheme.getSecondaryTextColor(context)),
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
                        backgroundColor: AppTheme.getSurfaceColor(context),
                        side: BorderSide(color: AppTheme.getInputBorderColor(context)),
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
                      backgroundColor: AppTheme.getSurfaceColor(context),
                      side: BorderSide(color: AppTheme.getInputBorderColor(context)),
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
                      backgroundColor: isMapView ? AppTheme.brandColor.withValues(alpha: 0.12) : AppTheme.getSurfaceColor(context),
                      side: BorderSide(color: isMapView ? AppTheme.brandColor : AppTheme.getInputBorderColor(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      state.toggleHotelMapView();
                    },
                    icon: Icon(
                      isMapView ? Icons.list : Icons.map,
                      size: 14,
                      color: isMapView ? AppTheme.getBrandTextColor(context) : AppTheme.brandColor,
                    ),
                    label: Text(
                      isMapView ? "List" : "Map",
                      style: TextStyle(
                        fontSize: 11,
                        color: isMapView ? AppTheme.getBrandTextColor(context) : AppTheme.getTextColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Locked Map Section when Map is shown
        if (isMapView)
          Container(
            height: 290,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.getBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Map Header Bar matching Web
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.getCardColor(context),
                    border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppTheme.brandColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, size: 10, color: AppTheme.getBrandTextColor(context)),
                                const SizedBox(width: 4),
                                Text(
                                  "Map Explorer",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.getBrandTextColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Interactive property pins",
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.getSecondaryTextColor(context),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => state.toggleHotelMapView(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.getInputBorderColor(context)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.visibility_off, size: 11, color: AppTheme.getBrandTextColor(context)),
                              const SizedBox(width: 4),
                              Text(
                                "Hide",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.getTextColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Vector Map
                Expanded(
                  child: MapboxMapView(
                    key: const ValueKey('hotel_mapbox_map_view'),
                    properties: state.hotelResults,
                    selectedPropertyId: _selectedHotelId,
                    showBottomMiniCard: false,
                    onPropertyTap: (prop) {
                      setState(() {
                        _selectedHotelId = prop.id;
                      });
                      _scrollToHotel(prop.id, state.hotelResults);
                    },
                    onPropertySelected: (prop) => _navigateToDetail(context, state, prop.id),
                  ),
                ),
              ],
            ),
          ),

        // Vertically Scrollable List of Hotels
        Expanded(
          child: state.isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: 3,
                  itemBuilder: (context, index) => const SkeletonCard(),
                )
              : state.errorMessage != null
                  ? _buildErrorState(state)
                  : state.hotelResults.isEmpty
                      ? _buildEmptyState(state)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 4, bottom: 24),
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
                                if (!state.isHotelMapView) {
                                  state.toggleHotelMapView();
                                }
                              },
                            );
                          },
                        ),
        ),
      ],
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
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
