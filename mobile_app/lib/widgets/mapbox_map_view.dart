import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MapboxMapView extends StatefulWidget {
  final List<dynamic> properties; // List<HotelCardModel> or List<ResortCardModel>
  final Function(dynamic property) onPropertySelected;
  final Function(double minLat, double maxLat, double minLon, double maxLon)? onBoundsChanged;

  const MapboxMapView({
    super.key,
    required this.properties,
    required this.onPropertySelected,
    this.onBoundsChanged,
  });

  @override
  State<MapboxMapView> createState() => _MapboxMapViewState();
}

class _MapboxMapViewState extends State<MapboxMapView> {
  MapLibreMapController? mapController;
  dynamic selectedProperty;
  bool isStyleLoaded = false;

  // High-performance worldwide vector tile style with unlimited street-level zoom (no API key required)
  static const String mapboxStyle = "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json";

  @override
  void didUpdateWidget(covariant MapboxMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isStyleLoaded && oldWidget.properties != widget.properties) {
      _addPropertyMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default initial location: San Francisco / Carmel Bay area
    final initialTarget = widget.properties.isNotEmpty
        ? LatLng(widget.properties.first.latitude, widget.properties.first.longitude)
        : const LatLng(37.7749, -122.4194);

    return Stack(
      children: [
        MapLibreMap(
          styleString: mapboxStyle,
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 11.0,
          ),
          onMapCreated: (controller) {
            mapController = controller;
            controller.onSymbolTapped.add(_onSymbolTapped);
            controller.onCircleTapped.add(_onCircleTapped);
          },
          onStyleLoadedCallback: () {
            if (mounted) {
              setState(() {
                isStyleLoaded = true;
              });
            }
            _addPropertyMarkers();
          },
          onCameraIdle: () async {
            if (mapController != null && widget.onBoundsChanged != null) {
              try {
                final bounds = await mapController!.getVisibleRegion();
                widget.onBoundsChanged!(
                  bounds.southwest.latitude,
                  bounds.northeast.latitude,
                  bounds.southwest.longitude,
                  bounds.northeast.longitude,
                );
              } catch (_) {}
            }
          },
        ),

        // Loading overlay until map style is initialized
        if (!isStyleLoaded)
          Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 12),
                  Text(
                    "Loading vector map...",
                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

        // Floating Selection Card at bottom of map
        if (selectedProperty != null)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildPropertyMiniCard(selectedProperty),
          ),
      ],
    );
  }

  Future<void> _addPropertyMarkers() async {
    if (mapController == null || !isStyleLoaded) return;
    try {
      await mapController!.clearSymbols();
      await mapController!.clearCircles();

      for (final prop in widget.properties) {
        final isResort = prop is ResortCardModel;
        final price = isResort
            ? "\$${prop.startingPricePerNight.toStringAsFixed(0)}"
            : "\$${prop.minPricePerNight.toStringAsFixed(0)}";

        // Circle pill background
        await mapController!.addCircle(
          CircleOptions(
            geometry: LatLng(prop.latitude, prop.longitude),
            circleRadius: 15.0,
            circleColor: isResort ? "#0D9488" : "#4F46E5",
            circleStrokeWidth: 2.0,
            circleStrokeColor: "#FFFFFF",
          ),
          {'id': prop.id},
        );

        // Price text centered in the pill
        await mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(prop.latitude, prop.longitude),
            textField: price,
            textSize: 10.0,
            textColor: "#FFFFFF",
            textAnchor: "center",
          ),
          {'id': prop.id},
        );
      }
    } catch (e) {
      debugPrint("Error updating map markers: $e");
    }
  }

  void _onSymbolTapped(Symbol symbol) {
    _handlePropertyTap(symbol.data?['id']);
  }

  void _onCircleTapped(Circle circle) {
    _handlePropertyTap(circle.data?['id']);
  }

  void _handlePropertyTap(dynamic propId) {
    if (propId == null) return;
    final match = widget.properties.firstWhere(
      (p) => p.id == propId,
      orElse: () => null,
    );
    if (match != null && mounted) {
      setState(() {
        selectedProperty = match;
      });
      widget.onPropertySelected(match);
    }
  }

  Widget _buildPropertyMiniCard(dynamic prop) {
    final isResort = prop is ResortCardModel;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              prop.coverImageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade300,
                child: const Icon(Icons.apartment),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prop.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${prop.city} • ⭐ ${prop.reviewScore.toStringAsFixed(1)}",
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  isResort
                      ? "From \$${prop.startingPricePerNight.toStringAsFixed(0)} / night"
                      : "\$${prop.minPricePerNight.toStringAsFixed(0)} / night",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isResort ? AppTheme.resortAccent : AppTheme.hotelAccent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => widget.onPropertySelected(prop),
          ),
        ],
      ),
    );
  }
}
