double _toDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? defaultValue;
}

double? _toOptionalDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _toInt(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? defaultValue;
}

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'],
      role: json['role'] ?? 'CUSTOMER',
    );
  }
}

class HotelCardModel {
  final String id;
  final String name;
  final String slug;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final double starRating;
  final double reviewScore;
  final int reviewCount;
  final String coverImageUrl;
  final List<String> galleryImages;
  final List<String> amenities;
  final double minPricePerNight;
  final bool isAvailable;

  HotelCardModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.starRating,
    required this.reviewScore,
    required this.reviewCount,
    required this.coverImageUrl,
    this.galleryImages = const [],
    required this.amenities,
    required this.minPricePerNight,
    required this.isAvailable,
  });

  factory HotelCardModel.fromJson(Map<String, dynamic> json) {
    return HotelCardModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      starRating: _toDouble(json['star_rating'], 4.0),
      reviewScore: _toDouble(json['review_score']),
      reviewCount: _toInt(json['review_count']),
      coverImageUrl: json['cover_image_url'] ?? '',
      galleryImages: List<String>.from(json['gallery_images'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      minPricePerNight: _toDouble(json['min_price_per_night']),
      isAvailable: json['is_available'] ?? true,
    );
  }
}

class LocalGuideModel {
  final String id;
  final String fullName;
  final String headline;
  final String profilePhotoUrl;
  final List<String> languages;
  final double dailyRate;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final List<String> specialties;
  final bool isVerified;
  final String? bio;
  final int yearsOfExperience;

  LocalGuideModel({
    required this.id,
    required this.fullName,
    required this.headline,
    required this.profilePhotoUrl,
    required this.languages,
    required this.dailyRate,
    this.hourlyRate = 35.0,
    required this.rating,
    required this.reviewCount,
    required this.specialties,
    required this.isVerified,
    this.bio,
    this.yearsOfExperience = 1,
  });

  factory LocalGuideModel.fromJson(Map<String, dynamic> json) {
    return LocalGuideModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      headline: json['headline'] ?? '',
      profilePhotoUrl: json['profile_photo_url'] ?? '',
      languages: List<String>.from(json['languages'] ?? []),
      dailyRate: _toDouble(json['daily_rate'], 200.0),
      hourlyRate: _toDouble(json['hourly_rate'], 35.0),
      rating: _toDouble(json['rating'], 5.0),
      reviewCount: _toInt(json['review_count']),
      specialties: List<String>.from(json['specialties'] ?? []),
      isVerified: json['is_verified'] ?? false,
      bio: json['bio'],
      yearsOfExperience: _toInt(json['years_of_experience'], 1),
    );
  }
}

class ResortCardModel {
  final String id;
  final String name;
  final String slug;
  final String? tagline;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final double starRating;
  final double reviewScore;
  final int reviewCount;
  final String coverImageUrl;
  final List<String> galleryImages;
  final List<String> amenities;
  final double startingPricePerNight;
  final int availableGuidesCount;
  final List<LocalGuideModel> featuredGuides;

  ResortCardModel({
    required this.id,
    required this.name,
    required this.slug,
    this.tagline,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.starRating,
    required this.reviewScore,
    required this.reviewCount,
    required this.coverImageUrl,
    required this.galleryImages,
    required this.amenities,
    required this.startingPricePerNight,
    required this.availableGuidesCount,
    required this.featuredGuides,
  });

  factory ResortCardModel.fromJson(Map<String, dynamic> json) {
    var guidesJson = json['featured_guides'] as List? ?? [];
    return ResortCardModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      tagline: json['tagline'],
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      starRating: _toDouble(json['star_rating'], 5.0),
      reviewScore: _toDouble(json['review_score']),
      reviewCount: _toInt(json['review_count']),
      coverImageUrl: json['cover_image_url'] ?? '',
      galleryImages: List<String>.from(json['gallery_images'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      startingPricePerNight: _toDouble(json['starting_price_per_night']),
      availableGuidesCount: _toInt(json['available_guides_count']),
      featuredGuides: guidesJson.map((g) => LocalGuideModel.fromJson(g)).toList(),
    );
  }
}

class RoomTypeModel {
  final String id;
  final String propertyId;
  final String name;
  final String? description;
  final int maxOccupancy;
  final String bedConfiguration;
  final double basePricePerNight;
  final List<String> amenities;
  final List<String> images;
  final int? availableRooms;
  final double? currentPricePerNight;

  RoomTypeModel({
    required this.id,
    required this.propertyId,
    required this.name,
    this.description,
    required this.maxOccupancy,
    required this.bedConfiguration,
    required this.basePricePerNight,
    required this.amenities,
    required this.images,
    this.availableRooms,
    this.currentPricePerNight,
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeModel(
      id: json['id'] ?? '',
      propertyId: json['property_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      maxOccupancy: _toInt(json['max_occupancy'], 2),
      bedConfiguration: json['bed_configuration'] ?? '1 King Bed',
      basePricePerNight: _toDouble(json['base_price_per_night']),
      amenities: List<String>.from(json['amenities'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      availableRooms: json['available_rooms'] != null ? _toInt(json['available_rooms']) : null,
      currentPricePerNight: _toOptionalDouble(json['current_price_per_night']),
    );
  }
}

class PropertyDetailModel {
  final String id;
  final String propertyType;
  final String name;
  final String slug;
  final String description;
  final String? tagline;
  final String address;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final double starRating;
  final double reviewScore;
  final int reviewCount;
  final String coverImageUrl;
  final List<String> galleryImages;
  final List<String> amenities;
  final String cancellationPolicy;
  final List<RoomTypeModel> roomTypes;
  final List<LocalGuideModel> associatedGuides;

  PropertyDetailModel({
    required this.id,
    required this.propertyType,
    required this.name,
    required this.slug,
    required this.description,
    this.tagline,
    required this.address,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.starRating,
    required this.reviewScore,
    required this.reviewCount,
    required this.coverImageUrl,
    required this.galleryImages,
    required this.amenities,
    required this.cancellationPolicy,
    required this.roomTypes,
    required this.associatedGuides,
  });

  factory PropertyDetailModel.fromJson(Map<String, dynamic> json) {
    var rooms = (json['room_types'] as List? ?? []).map((r) => RoomTypeModel.fromJson(r)).toList();
    var guides = (json['associated_guides'] as List? ?? []).map((g) => LocalGuideModel.fromJson(g)).toList();
    return PropertyDetailModel(
      id: json['id'] ?? '',
      propertyType: json['property_type'] ?? 'HOTEL',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      tagline: json['tagline'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      starRating: _toDouble(json['star_rating'], 4.0),
      reviewScore: _toDouble(json['review_score']),
      reviewCount: _toInt(json['review_count']),
      coverImageUrl: json['cover_image_url'] ?? '',
      galleryImages: List<String>.from(json['gallery_images'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      cancellationPolicy: json['cancellation_policy'] ?? '',
      roomTypes: rooms,
      associatedGuides: guides,
    );
  }
}

class PriceQuoteModel {
  final int totalNights;
  final double roomSubtotal;
  final double guideSubtotal;
  final double platformFee;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final bool isAvailable;
  final String? unavailabilityReason;

  PriceQuoteModel({
    required this.totalNights,
    required this.roomSubtotal,
    required this.guideSubtotal,
    required this.platformFee,
    required this.taxAmount,
    required this.totalAmount,
    required this.currency,
    required this.isAvailable,
    this.unavailabilityReason,
  });

  factory PriceQuoteModel.fromJson(Map<String, dynamic> json) {
    return PriceQuoteModel(
      totalNights: _toInt(json['total_nights'], 1),
      roomSubtotal: _toDouble(json['room_subtotal']),
      guideSubtotal: _toDouble(json['guide_subtotal']),
      platformFee: _toDouble(json['platform_fee']),
      taxAmount: _toDouble(json['tax_amount']),
      totalAmount: _toDouble(json['total_amount']),
      currency: json['currency'] ?? 'USD',
      isAvailable: json['is_available'] ?? true,
      unavailabilityReason: json['unavailability_reason'],
    );
  }
}

class ReservationModel {
  final String id;
  final String reservationCode;
  final String propertyName;
  final String propertyType;
  final String bookingType;
  final String status;
  final String paymentStatus;
  final String checkInDate;
  final String checkOutDate;
  final int totalNights;
  final int guestCount;
  final double roomSubtotal;
  final double guideSubtotal;
  final double platformFee;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final String? specialRequests;
  final String? guideName;
  final String? guidePhotoUrl;

  ReservationModel({
    required this.id,
    required this.reservationCode,
    required this.propertyName,
    required this.propertyType,
    required this.bookingType,
    required this.status,
    required this.paymentStatus,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalNights,
    required this.guestCount,
    required this.roomSubtotal,
    required this.guideSubtotal,
    required this.platformFee,
    required this.taxAmount,
    required this.totalAmount,
    required this.currency,
    this.specialRequests,
    this.guideName,
    this.guidePhotoUrl,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    var guideItem = json['guide_item'];
    return ReservationModel(
      id: json['id'] ?? '',
      reservationCode: json['reservation_code'] ?? '',
      propertyName: json['property_name'] ?? '',
      propertyType: json['property_type'] ?? '',
      bookingType: json['booking_type'] ?? '',
      status: json['status'] ?? 'CONFIRMED',
      paymentStatus: json['payment_status'] ?? 'PAID',
      checkInDate: json['check_in_date'] ?? '',
      checkOutDate: json['check_out_date'] ?? '',
      totalNights: _toInt(json['total_nights'], 1),
      guestCount: _toInt(json['guest_count'], 1),
      roomSubtotal: _toDouble(json['room_subtotal']),
      guideSubtotal: _toDouble(json['guide_subtotal']),
      platformFee: _toDouble(json['platform_fee']),
      taxAmount: _toDouble(json['tax_amount']),
      totalAmount: _toDouble(json['total_amount']),
      currency: json['currency'] ?? 'USD',
      specialRequests: json['special_requests'],
      guideName: guideItem != null ? guideItem['guide_name'] : null,
      guidePhotoUrl: guideItem != null ? guideItem['guide_photo_url'] : null,
    );
  }
}
