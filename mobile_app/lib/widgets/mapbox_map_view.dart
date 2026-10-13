import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../config/map_dock.dart';
import 'app_network_image.dart';

class MapboxMapView extends StatefulWidget {
  final List<dynamic> properties; // List<HotelCardModel> or List<ResortCardModel>
  final Function(dynamic property) onPropertySelected;
  final Function(dynamic property)? onPropertyTap;
  final String? selectedPropertyId;
  final bool showBottomMiniCard;
  final Function(double minLat, double maxLat, double minLon, double maxLon)? onBoundsChanged;

  const MapboxMapView({
    super.key,
    required this.properties,
    required this.onPropertySelected,
    this.onPropertyTap,
    this.selectedPropertyId,
    this.showBottomMiniCard = true,
    this.onBoundsChanged,
  });

  @override
  State<MapboxMapView> createState() => _MapboxMapViewState();
}

class _MapboxMapViewState extends State<MapboxMapView> {
  MapLibreMapController? mapController;
  dynamic selectedProperty;
  bool isStyleLoaded = false;

  // Swappable vector tile style delegated to the central MapDock
  static String get mapboxStyle => MapDock.activeStyleUrl;

  dynamic _findProperty(String? id) {
    if (id == null) return null;
    for (final prop in widget.properties) {
      if (prop.id == id) return prop;
    }
    return null;
  }

  CameraPosition _getInitialCameraPosition() {
    final selected = _findProperty(widget.selectedPropertyId);
    if (selected != null && selected.latitude != null && selected.longitude != null) {
      return CameraPosition(
        target: LatLng(selected.latitude, selected.longitude),
        zoom: 14.0,
      );
    }

    for (final p in widget.properties) {
      final city = (p.city as String?)?.toLowerCase() ?? '';
      if (city.contains('bangalore') || city.contains('bengaluru')) {
        return CameraPosition(
          target: LatLng(p.latitude, p.longitude),
          zoom: 12.0,
        );
      }
    }

    if (widget.properties.isNotEmpty) {
      final first = widget.properties.first;
      return CameraPosition(
        target: LatLng(first.latitude, first.longitude),
        zoom: 12.0,
      );
    }

    return const CameraPosition(
      target: LatLng(12.9716, 77.5946),
      zoom: 11.0,
    );
  }

  @override
  void didUpdateWidget(covariant MapboxMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (isStyleLoaded) {
      if (oldWidget.properties != widget.properties ||
          oldWidget.selectedPropertyId != widget.selectedPropertyId) {
        _addPropertyMarkers();
      }
      if (widget.selectedPropertyId != null &&
          widget.selectedPropertyId != oldWidget.selectedPropertyId) {
        final prop = _findProperty(widget.selectedPropertyId);
        if (prop != null && prop.latitude != null && prop.longitude != null) {
          setState(() {
            selectedProperty = prop;
          });
          mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(prop.latitude, prop.longitude),
              14.0,
            ),
            duration: const Duration(milliseconds: 600),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    mapController?.onSymbolTapped.remove(_onSymbolTapped);
    mapController?.onCircleTapped.remove(_onCircleTapped);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          key: const ValueKey('plane_maplibre_canvas'),
          styleString: mapboxStyle,
          initialCameraPosition: _getInitialCameraPosition(),
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
            if (widget.selectedPropertyId != null) {
              final prop = _findProperty(widget.selectedPropertyId);
              if (prop != null && prop.latitude != null && prop.longitude != null) {
                mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(prop.latitude, prop.longitude),
                    14.0,
                  ),
                  duration: const Duration(milliseconds: 600),
                );
              }
            }
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
        if (widget.showBottomMiniCard && selectedProperty != null)
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

      final activeId = widget.selectedPropertyId ?? selectedProperty?.id;

      for (final prop in widget.properties) {
        final isResort = prop is ResortCardModel;
        final isSelected = prop.id == activeId;
        final price = isResort
            ? "\$${prop.startingPricePerNight.toStringAsFixed(0)}"
            : "\$${prop.minPricePerNight.toStringAsFixed(0)}";

        // Circle pill background
        await mapController!.addCircle(
          CircleOptions(
            geometry: LatLng(prop.latitude, prop.longitude),
            circleRadius: isSelected ? 20.0 : 15.0,
            circleColor: isSelected
                ? "#0F172A"
                : (isResort ? "#0D9488" : "#4F46E5"),
            circleStrokeWidth: isSelected ? 3.5 : 2.0,
            circleStrokeColor: isSelected ? "#7DE720" : "#FFFFFF",
          ),
          {'id': prop.id},
        );

        // Price text centered in the pill
        await mapController!.addSymbol(
          SymbolOptions(
            geometry: LatLng(prop.latitude, prop.longitude),
            textField: price,
            textSize: isSelected ? 12.0 : 10.0,
            textColor: isSelected ? "#7DE720" : "#FFFFFF",
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
    final match = _findProperty(propId.toString());
    if (match != null && mounted) {
      setState(() {
        selectedProperty = match;
      });
      if (match.latitude != null && match.longitude != null) {
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(match.latitude, match.longitude),
            14.0,
          ),
          duration: const Duration(milliseconds: 600),
        );
      }
      _addPropertyMarkers();
      if (widget.onPropertyTap != null) {
        widget.onPropertyTap!(match);
      }
    }
  }

  Widget _buildPropertyMiniCard(dynamic prop) {
    final isResort = prop is ResortCardModel;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
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
          AppNetworkImage(
            imageUrl: prop.coverImageUrl,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(10),
            fallbackIcon: Icons.apartment,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  prop.name,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.getTextColor(context)),
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
