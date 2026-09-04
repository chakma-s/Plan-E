import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/hotel_card.dart';
import '../widgets/mapbox_map_view.dart';
import '../theme/app_theme.dart';
import 'hotel_detail_screen.dart';import '../widgets/skeleton_loader.dart';

class HotelSearchScreen extends StatefulWidget {
  const HotelSearchScreen({super.key});

  @override
  State<HotelSearchScreen> createState() => _HotelSearchScreenState();
}

class _HotelSearchScreenState extends State<HotelSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool isMapView = false;
  String selectedSort = 'recommended';

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

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
                    hintText: "Where to? (e.g. San Francisco)",
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
                      setState(() {
                        isMapView = !isMapView;
                      });
                    },
                    icon: Icon(isMapView ? Icons.list : Icons.map, size: 14, color: AppTheme.hotelAccent),
                    label: Text(isMapView ? "List" : "Map", style: TextStyle(fontSize: 11, color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Body: Map View or List View
        Expanded(
          child: state.isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: 3,
                  itemBuilder: (context, index) => const SkeletonCard(),
                )
              : isMapView
                  ? MapboxMapView(
                      properties: state.hotelResults,
                      onPropertySelected: (prop) => _navigateToDetail(context, state, prop.id),
                    )
                  : state.hotelResults.isEmpty
                      ? _buildEmptyState(state)
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: state.hotelResults.length,
                          itemBuilder: (context, idx) {
                            final hotel = state.hotelResults[idx];
                            return HotelCard(
                              hotel: hotel,
                              onTap: () => _navigateToDetail(context, state, hotel.id),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
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
