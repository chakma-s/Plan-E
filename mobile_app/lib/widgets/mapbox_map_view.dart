import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
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
  MapboxMapController? mapController;
  dynamic selectedProperty;

  static const String mapboxStyle = MapboxStyles.MAPBOX_STREETS;
  static const String accessToken = "pk.eyJ1IjoicGxhbmUtdHJhdmVsIiwiYSI6ImNsdGVzdHRva2VuIn0.demo";

  @override
  Widget build(BuildContext context) {
    // Default initial location: San Francisco / Carmel Bay area
    final initialTarget = widget.properties.isNotEmpty
        ? LatLng(widget.properties.first.latitude, widget.properties.first.longitude)
        : const LatLng(37.7749, -122.4194);

    return Stack(
      children: [
        MapboxMap(
          accessToken: accessToken,
          styleString: mapboxStyle,
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 11.0,
          ),
          onMapCreated: (controller) {
            mapController = controller;
            _addPropertyMarkers();
          },
          onCameraIdle: () async {
            if (mapController != null && widget.onBoundsChanged != null) {
              final bounds = await mapController!.getVisibleRegion();
              widget.onBoundsChanged!(
                bounds.southwest.latitude,
                bounds.northeast.latitude,
                bounds.southwest.longitude,
                bounds.northeast.longitude,
              );
            }
          },
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

  void _addPropertyMarkers() {
    if (mapController == null) return;
    mapController!.clearSymbols();

    for (final prop in widget.properties) {
      final isResort = prop is ResortCardModel;
      final price = isResort
          ? "\$${prop.startingPricePerNight.toStringAsFixed(0)}"
          : "\$${prop.minPricePerNight.toStringAsFixed(0)}";

      mapController!.addSymbol(
        SymbolOptions(
          geometry: LatLng(prop.latitude, prop.longitude),
          iconImage: isResort ? "resort-pin" : "hotel-pin",
          iconSize: 1.2,
          textField: price,
          textOffset: const Offset(0, 1.2),
          textSize: 12.0,
          textColor: isResort ? "#0D9488" : "#4F46E5",
          textHaloColor: "#FFFFFF",
          textHaloWidth: 2.0,
        ),
        {'id': prop.id},
      );
    }

    mapController!.onSymbolTapped.add((symbol) {
      final propId = symbol.data?['id'];
      final match = widget.properties.firstWhere(
        (p) => p.id == propId,
        orElse: () => null,
      );
      if (match != null) {
        setState(() {
          selectedProperty = match;
        });
        widget.onPropertySelected(match);
      }
    });
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
