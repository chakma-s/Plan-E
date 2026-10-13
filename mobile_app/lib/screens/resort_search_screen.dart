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
  final ScrollController _scrollController = ScrollController();
  String? _selectedResortId;
  bool withGuidesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToResort(String id, List<ResortCardModel> list) {
    final idx = list.indexWhere((r) => r.id == id);
    if (idx != -1 && _scrollController.hasClients) {
      final target = (idx * 340.0).clamp(0.0, _scrollController.position.maxScrollExtent);
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
    final isMapView = state.isResortMapView;

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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.getInputBorderColor(context)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppTheme.getTextColor(context)),
                  decoration: InputDecoration(
                    hintText: "Where to? (e.g. Bangalore, Carmel)",
                    hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.resortAccent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: AppTheme.getSecondaryTextColor(context)),
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
                        backgroundColor: AppTheme.getSurfaceColor(context),
                        side: BorderSide(color: AppTheme.getInputBorderColor(context)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _selectDateRange(context, state),
                      icon: const Icon(Icons.calendar_today, size: 14, color: AppTheme.resortAccent),
                      label: Text(
                        state.displayDateRange,
                        style: TextStyle(fontSize: 11, color: AppTheme.getTextColor(context), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Guide Only Filter Pill
                  FilterChip(
                    backgroundColor: AppTheme.getSurfaceColor(context),
                    avatar: const Icon(Icons.verified_user, size: 14, color: AppTheme.brandColor),
                    label: Text(
                      "Guides",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: withGuidesOnly ? AppTheme.getBrandTextColor(context) : AppTheme.getTextColor(context),
                      ),
                    ),
                    selected: withGuidesOnly,
                    selectedColor: AppTheme.brandColor.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.getBrandTextColor(context),
                    side: BorderSide(color: withGuidesOnly ? AppTheme.brandColor : AppTheme.getInputBorderColor(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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

                  // Map/List View Toggle Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      backgroundColor: isMapView ? AppTheme.brandColor.withValues(alpha: 0.12) : AppTheme.getSurfaceColor(context),
                      side: BorderSide(color: isMapView ? AppTheme.brandColor : AppTheme.getInputBorderColor(context)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      state.toggleResortMapView();
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
                        onTap: () => state.toggleResortMapView(),
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
                    key: const ValueKey('resort_mapbox_map_view'),
                    properties: state.resortResults,
                    selectedPropertyId: _selectedResortId,
                    showBottomMiniCard: false,
                    onPropertyTap: (prop) {
                      setState(() {
                        _selectedResortId = prop.id;
                      });
                      _scrollToResort(prop.id, state.resortResults);
                    },
                    onPropertySelected: (prop) => _navigateToDetail(context, state, prop.id),
                  ),
                ),
              ],
            ),
          ),

        // Vertically Scrollable List of Resorts
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.brandColor))
              : state.errorMessage != null
                  ? _buildErrorState(state)
                  : state.resortResults.isEmpty
                      ? _buildEmptyState(state)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 4, bottom: 24),
                          itemCount: state.resortResults.length,
                          itemBuilder: (context, idx) {
                            final resort = state.resortResults[idx];
                            return ResortCard(
                              resort: resort,
                              isSelected: resort.id == _selectedResortId,
                              onTap: () => _navigateToDetail(context, state, resort.id),
                              onLocateTap: () {
                                setState(() {
                                  _selectedResortId = resort.id;
                                });
                                if (!state.isResortMapView) {
                                  state.toggleResortMapView();
                                }
                              },
                              onGuideTap: (guide) => _openGuideModal(context, state, guide),
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
              "Unable to load resorts",
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandColor, foregroundColor: Colors.black),
              onPressed: () => state.fetchResorts(),
              child: const Text("Try Again", style: TextStyle(fontWeight: FontWeight.w800)),
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
          const Icon(Icons.beach_access_outlined, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            "No resorts found for your filters.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.getTextColor(context)),
          ),
          const SizedBox(height: 6),
          Text(
            "Try toggling off 'Bundled Guides' or changing destinations.",
            style: TextStyle(fontSize: 13, color: AppTheme.getSecondaryTextColor(context)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandColor, foregroundColor: Colors.black),
            onPressed: () {
              _searchController.clear();
              setState(() {
                withGuidesOnly = false;
              });
              state.fetchResorts();
            },
            child: const Text("Reset Filters", style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
