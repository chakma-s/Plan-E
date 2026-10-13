/// Map Docking System
///
/// Designed for plug-and-play map provider swapping (like swapping batteries in a TV remote).
/// To switch vendors across the entire Flutter app, simply change [activeProvider].
enum MapProvider {
  /// CartoDB Voyager: Worldwide OpenStreetMap vector style with street-level rural coverage.
  /// 100% free, high performance, no API key required.
  cartoVoyager,

  /// MapTiler: Official OpenMapTiles style with satellite, terrain, and deep Asian village coverage.
  /// Requires free MapTiler account key (100,000 requests/month free).
  mapTiler,

  /// Stadia Maps: Alidade Smooth / Outdoors style with generous free tier (200,000 requests/month).
  stadia,

  /// Positron: High-contrast minimalist OpenStreetMap style (no API key required).
  osmPositron,
}

class MapDock {
  /// ⚡ BATTERY SWAP: Change this single value to switch map providers instantly!
  /// Options: [MapProvider.cartoVoyager], [MapProvider.mapTiler], [MapProvider.stadia], [MapProvider.osmPositron]
  static const MapProvider activeProvider = MapProvider.cartoVoyager;

  /// Optional API keys (leave empty for keyless providers like Carto & Positron)
  static const String mapTilerKey = "";
  static const String stadiaKey = "";

  /// Resolves the active vector tile style URL
  static String get activeStyleUrl {
    switch (activeProvider) {
      case MapProvider.mapTiler:
        if (mapTilerKey.isNotEmpty) {
          return "https://api.maptiler.com/maps/streets-v2/style.json?key=$mapTilerKey";
        }
        // Graceful fallback to Carto Voyager if no key is configured
        return "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json";

      case MapProvider.stadia:
        if (stadiaKey.isNotEmpty) {
          return "https://tiles.stadiamaps.com/styles/alidade_smooth.json?api_key=$stadiaKey";
        }
        return "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json";

      case MapProvider.osmPositron:
        return "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json";

      case MapProvider.cartoVoyager:
        // High-performance worldwide vector tile style with unlimited street-level zoom
        return "https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json";
    }
  }

  /// Human-readable label of current active provider
  static String get providerName {
    switch (activeProvider) {
      case MapProvider.cartoVoyager:
        return "CartoDB Voyager (OSM Vector)";
      case MapProvider.mapTiler:
        return "MapTiler Streets (OSM Vector)";
      case MapProvider.stadia:
        return "Stadia Maps (Alidade Vector)";
      case MapProvider.osmPositron:
        return "OSM Positron";
    }
  }
}
