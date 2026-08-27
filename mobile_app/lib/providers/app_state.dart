import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

enum JourneyType { hotel, resort }

class AppState extends ChangeNotifier {
  final ApiService api = ApiService();


  // Theme State
  ThemeMode currentTheme = ThemeMode.light;

  void toggleTheme() {
    currentTheme = currentTheme == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Authentication

  UserModel? currentUser;
  bool isAuthenticated = false;

  // Dual-Journey Tab State
  JourneyType activeJourney = JourneyType.hotel;

  // Date Selection Defaults (Check-in tomorrow, Check-out 3 days later)
  DateTime checkInDate = DateTime.now().add(const Duration(days: 1));
  DateTime checkOutDate = DateTime.now().add(const Duration(days: 4));
  int guestCount = 2;

  // Search Results & Loading
  bool isLoading = false;
  String? errorMessage;

  List<HotelCardModel> hotelResults = [];
  List<ResortCardModel> resortResults = [];

  // Active Draft Booking Flow
  PropertyDetailModel? selectedProperty;
  RoomTypeModel? selectedRoom;
  int selectedRoomCount = 1;
  LocalGuideModel? selectedGuideBundle; // The Local Guide Bundling feature state
  String? guideSpecialRequests;

  PriceQuoteModel? currentPriceQuote;
  bool isCalculatingQuote = false;

  AppState() {
    // Initial fetch of sample properties
    fetchHotels();
    fetchResorts();
  }

  String get formattedCheckIn => DateFormat('yyyy-MM-dd').format(checkInDate);
  String get formattedCheckOut => DateFormat('yyyy-MM-dd').format(checkOutDate);
  String get displayDateRange =>
      "${DateFormat('MMM d').format(checkInDate)} - ${DateFormat('MMM d, yyyy').format(checkOutDate)}";

  void setJourney(JourneyType journey) {
    activeJourney = journey;
    notifyListeners();
  }

  void setDates(DateTime checkIn, DateTime checkOut) {
    checkInDate = checkIn;
    checkOutDate = checkOut;
    notifyListeners();
    // Refresh search results for new dates
    if (activeJourney == JourneyType.hotel) {
      fetchHotels();
    } else {
      fetchResorts();
    }
  }

  Future<void> loginAsBetaUser() async {
    try {
      final res = await api.login('traveler.alex@example.com', 'Password123!');
      currentUser = UserModel.fromJson(res['user']);
      isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  // --- Hotel Pipeline Search ---
  Future<void> fetchHotels({String? city, String sortBy = 'recommended'}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      hotelResults = await api.searchHotels(
        city: city,
        checkIn: formattedCheckIn,
        checkOut: formattedCheckOut,
        guests: guestCount,
        sortBy: sortBy,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Resort Pipeline Search ---
  Future<void> fetchResorts({String? destination, bool withGuidesOnly = false, String sortBy = 'featured'}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      resortResults = await api.searchResorts(
        destination: destination,
        checkIn: formattedCheckIn,
        checkOut: formattedCheckOut,
        guests: guestCount,
        withGuidesOnly: withGuidesOnly,
        sortBy: sortBy,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Guide Bundling & Cart Actions ---
  void selectProperty(PropertyDetailModel property) {
    selectedProperty = property;
    selectedRoom = property.roomTypes.isNotEmpty ? property.roomTypes.first : null;
    selectedGuideBundle = null;
    currentPriceQuote = null;
    notifyListeners();
    calculateQuote();
  }

  void selectRoom(RoomTypeModel room) {
    selectedRoom = room;
    notifyListeners();
    calculateQuote();
  }

  void toggleGuideBundle(LocalGuideModel guide) {
    if (selectedGuideBundle?.id == guide.id) {
      selectedGuideBundle = null; // Unbundle
    } else {
      selectedGuideBundle = guide; // Bundle selected guide
    }
    notifyListeners();
    calculateQuote();
  }

  void clearGuideBundle() {
    selectedGuideBundle = null;
    notifyListeners();
    calculateQuote();
  }

  Future<void> calculateQuote() async {
    if (selectedProperty == null || selectedRoom == null) return;

    isCalculatingQuote = true;
    notifyListeners();

    try {
      final roomItems = [
        {'room_type_id': selectedRoom!.id, 'rooms_count': selectedRoomCount}
      ];

      Map<String, dynamic>? guideItem;
      if (selectedGuideBundle != null) {
        guideItem = {
          'guide_id': selectedGuideBundle!.id,
          'service_date': formattedCheckIn,
          'duration_days': 1,
          'special_requirements': guideSpecialRequests ?? 'Exclusive resort excursion',
        };
      }

      currentPriceQuote = await api.getPriceQuote(
        propertyId: selectedProperty!.id,
        checkInDate: formattedCheckIn,
        checkOutDate: formattedCheckOut,
        roomItems: roomItems,
        guideBundle: guideItem,
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isCalculatingQuote = false;
      notifyListeners();
    }
  }

  Future<ReservationModel> finalizeBooking() async {
    if (selectedProperty == null || selectedRoom == null) {
      throw Exception('Missing property or room selection');
    }

    if (!isAuthenticated) {
      await loginAsBetaUser();
    }

    final roomItems = [
      {'room_type_id': selectedRoom!.id, 'rooms_count': selectedRoomCount}
    ];

    Map<String, dynamic>? guideItem;
    if (selectedGuideBundle != null) {
      guideItem = {
        'guide_id': selectedGuideBundle!.id,
        'service_date': formattedCheckIn,
        'duration_days': 1,
        'special_requirements': guideSpecialRequests ?? 'Exclusive resort excursion',
      };
    }

    final reservation = await api.createReservation(
      propertyId: selectedProperty!.id,
      checkInDate: formattedCheckIn,
      checkOutDate: formattedCheckOut,
      guestCount: guestCount,
      roomItems: roomItems,
      guideBundle: guideItem,
      specialRequests: "Special booking via Plan-E Mobile App.",
    );

    return reservation;
  }
}
