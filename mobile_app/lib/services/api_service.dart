import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api/v1";
  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // --- Auth ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      _authToken = json['data']['access_token'];
      return json['data'];
    }
    throw Exception(jsonDecode(res.body)['detail'] ?? 'Login failed');
  }

  // --- Hotel Pipeline (Transactional) ---
  Future<List<HotelCardModel>> searchHotels({
    String? city,
    String? checkIn,
    String? checkOut,
    int guests = 1,
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
    String sortBy = 'recommended',
  }) async {
    final queryParams = <String, String>{
      'guests': guests.toString(),
      'sort_by': sortBy,
    };
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (checkIn != null) queryParams['check_in'] = checkIn;
    if (checkOut != null) queryParams['check_out'] = checkOut;
    if (minLat != null) queryParams['min_lat'] = minLat.toString();
    if (maxLat != null) queryParams['max_lat'] = maxLat.toString();
    if (minLon != null) queryParams['min_lon'] = minLon.toString();
    if (maxLon != null) queryParams['max_lon'] = maxLon.toString();

    final uri = Uri.parse('$baseUrl/hotels').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List items = json['data'] ?? [];
      return items.map((i) => HotelCardModel.fromJson(i)).toList();
    }
    throw Exception('Failed to search hotels: ${res.body}');
  }

  Future<PropertyDetailModel> getHotelDetail(String hotelId, {String? checkIn, String? checkOut}) async {
    final queryParams = <String, String>{};
    if (checkIn != null) queryParams['check_in'] = checkIn;
    if (checkOut != null) queryParams['check_out'] = checkOut;

    final uri = Uri.parse('$baseUrl/hotels/$hotelId').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return PropertyDetailModel.fromJson(json['data']);
    }
    throw Exception('Failed to load hotel detail');
  }

  // --- Resort Pipeline (Immersive + Guides) ---
  Future<List<ResortCardModel>> searchResorts({
    String? destination,
    String? checkIn,
    String? checkOut,
    int guests = 1,
    bool withGuidesOnly = false,
    String sortBy = 'featured',
  }) async {
    final queryParams = <String, String>{
      'guests': guests.toString(),
      'with_guides_only': withGuidesOnly.toString(),
      'sort_by': sortBy,
    };
    if (destination != null && destination.isNotEmpty) queryParams['destination'] = destination;
    if (checkIn != null) queryParams['check_in'] = checkIn;
    if (checkOut != null) queryParams['check_out'] = checkOut;

    final uri = Uri.parse('$baseUrl/resorts').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List items = json['data'] ?? [];
      return items.map((i) => ResortCardModel.fromJson(i)).toList();
    }
    throw Exception('Failed to search resorts: ${res.body}');
  }

  Future<PropertyDetailModel> getResortDetail(String resortId, {String? checkIn, String? checkOut}) async {
    final queryParams = <String, String>{};
    if (checkIn != null) queryParams['check_in'] = checkIn;
    if (checkOut != null) queryParams['check_out'] = checkOut;

    final uri = Uri.parse('$baseUrl/resorts/$resortId').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers);

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return PropertyDetailModel.fromJson(json['data']);
    }
    throw Exception('Failed to load resort detail');
  }

  // --- Local Guide Profile ---
  Future<LocalGuideModel> getGuideDetail(String guideId) async {
    final uri = Uri.parse('$baseUrl/guides/$guideId');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return LocalGuideModel.fromJson(json['data']);
    }
    throw Exception('Failed to load guide details');
  }

  // --- Booking & Quote Engine ---
  Future<PriceQuoteModel> getPriceQuote({
    required String propertyId,
    required String checkInDate,
    required String checkOutDate,
    required List<Map<String, dynamic>> roomItems,
    Map<String, dynamic>? guideBundle,
  }) async {
    final body = {
      'property_id': propertyId,
      'check_in_date': checkInDate,
      'check_out_date': checkOutDate,
      'room_items': roomItems,
      if (guideBundle != null) 'guide_bundle': guideBundle,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/bookings/quote'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return PriceQuoteModel.fromJson(json['data']);
    }
    throw Exception('Failed to compute price quote: ${res.body}');
  }

  Future<ReservationModel> createReservation({
    required String propertyId,
    required String checkInDate,
    required String checkOutDate,
    required int guestCount,
    required List<Map<String, dynamic>> roomItems,
    Map<String, dynamic>? guideBundle,
    String? specialRequests,
  }) async {
    final body = {
      'property_id': propertyId,
      'check_in_date': checkInDate,
      'check_out_date': checkOutDate,
      'guest_count': guestCount,
      'room_items': roomItems,
      if (guideBundle != null) 'guide_bundle': guideBundle,
      if (specialRequests != null) 'special_requests': specialRequests,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 201) {
      final json = jsonDecode(res.body);
      return ReservationModel.fromJson(json['data']);
    }
    final errJson = jsonDecode(res.body);
    throw Exception(errJson['detail'] ?? 'Booking transaction failed');
  }

  Future<List<ReservationModel>> getMyReservations() async {
    final res = await http.get(Uri.parse('$baseUrl/bookings/my-reservations'), headers: _headers);
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final List items = json['data'] ?? [];
      return items.map((i) => ReservationModel.fromJson(i)).toList();
    }
    throw Exception('Failed to load user reservations');
  }
}
