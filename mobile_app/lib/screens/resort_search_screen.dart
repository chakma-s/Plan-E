import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../widgets/resort_card.dart';
import '../widgets/guide_bundle_sheet.dart';
import '../widgets/mapbox_map_view.dart';
import '../theme/app_theme.dart';
import 'resort_detail_screen.dart';

class ResortSearchScreen extends StatefulWidget {
  const ResortSearchScreen({super.key});

  @override
  State<ResortSearchScreen> createState() => _ResortSearchScreenState();
}

class _ResortSearchScreenState extends State<ResortSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool withGuidesOnly = false;
  bool isMapView = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Column(
      children: [
        // Immersive Search Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppTheme.getCardColor(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.getSurfaceColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.getDividerColor(context)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: "Search Sanctuary Destinations (e.g. Carmel, Hawaii)",
                    prefixIcon: const Icon(Icons.explore, color: AppTheme.resortAccent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              state.fetchResorts();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (query) {
                    state.fetchResorts(destination: query, withGuidesOnly: withGuidesOnly);
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Filter Controls
              Row(
                children: [
                  // Date Range Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        side: const BorderSide(color: AppTheme.getDividerColor(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _selectDateRange(context, state),
                      icon: const Icon(Icons.calendar_month, size: 14, color: AppTheme.resortAccent),
                      label: Text(
                        state.displayDateRange,
                        style: const TextStyle(fontSize: 11, color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Guide Only Filter Pill
                  FilterChip(
                    avatar: const Icon(Icons.verified_user, size: 14, color: AppTheme.guideGold),
                    label: const Text("Bundled Guides", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    selected: withGuidesOnly,
                    selectedColor: AppTheme.guideLight,
                    checkmarkColor: AppTheme.guideGold,
                    side: BorderSide(color: withGuidesOnly ? AppTheme.guideGold : AppTheme.divider),
                    onSelected: (selected) {
                      setState(() {
                        withGuidesOnly = selected;
                      });
                      state.fetchResorts(
                        destination: _searchController.text,
                        withGuidesOnly: withGuidesOnly,
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Map/List View switcher removed because layout is now split 50/50
                ],
              ),
            ],
          ),
        ),

        // Body: 50% Map View / 50% List View
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.resortAccent))
              : Column(
                  children: [
                    // Top 50%: Map View
                    Expanded(
                      flex: 1,
                      child: MapboxMapView(
                        properties: state.resortResults,
                        onPropertySelected: (prop) => _navigateToDetail(context, state, prop.id),
                      ),
                    ),
                    // Bottom 50%: List View
                    Expanded(
                      flex: 1,
                      child: state.resortResults.isEmpty
                          ? _buildEmptyState(state)
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 8, bottom: 24),
                              itemCount: state.resortResults.length,
                              itemBuilder: (context, idx) {
                                final resort = state.resortResults[idx];
                                return ResortCard(
                                  resort: resort,
                                  onTap: () => _navigateToDetail(context, state, resort.id),
                                  onGuideTap: (guide) => _openGuideModal(context, state, guide),
                                );
                              },
                            ),
                    ),
                  ],
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

  void _openGuideModal(BuildContext context, AppState state, LocalGuideModel guide) {
    GuideBundleSheet.show(
      context,
      guide: guide,
      isBundled: state.selectedGuideBundle?.id == guide.id,
      onToggleBundle: () => state.toggleGuideBundle(guide),
    );
  }

  void _navigateToDetail(BuildContext context, AppState state, String resortId) async {
    try {
      final detail = await state.api.getResortDetail(
        resortId,
        checkIn: state.formattedCheckIn,
        checkOut: state.formattedCheckOut,
      );
      state.selectProperty(detail);
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const ResortDetailScreen()),
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
          const Icon(Icons.beach_access_outlined, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          const Text(
            "No resorts found for your filters.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context)),
          ),
          const SizedBox(height: 6),
          const Text(
            "Try toggling off 'Bundled Guides' or changing destinations.",
            style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.resortAccent),
            onPressed: () {
              _searchController.clear();
              setState(() {
                withGuidesOnly = false;
              });
              state.fetchResorts();
            },
            child: const Text("Reset Filters"),
          ),
        ],
      ),
    );
  }
}
