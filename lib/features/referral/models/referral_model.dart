// lib/features/referral/models/referral_model.dart

class ReferralModel {
  final String? referralCode;
  final String? referralLink;
  final String referralType; // 'rider' | 'sales_person'
  final bool hasReferralProfile;
  final bool turnOffReferral;

  // Sarri Points (rider type)
  final int availablePoints;
  final int totalPoints;
  final int usedPoints;

  // Stats
  final int totalReferrals;
  final int completedReferrals;
  final int activeReferrals;
  final int pendingReferrals;
  final int totalDiscountRidesEarned; // sales person type

  // Discount (sales person)
  final double? individualDiscountPercent;
  final double effectiveDiscountPercent;

  // Tier
  final String tier;

  // Recent history
  final List<ReferralHistoryItem> recentReferrals;

  // Config from admin (injected when available)
  final int pointsPerRide;
  final double pointToNairaRate;
  final double maxPointsRedeemPercent;

  const ReferralModel({
    this.referralCode,
    this.referralLink,
    this.referralType = 'rider',
    this.hasReferralProfile = false,
    this.turnOffReferral = false,
    this.availablePoints = 0,
    this.totalPoints = 0,
    this.usedPoints = 0,
    this.totalReferrals = 0,
    this.completedReferrals = 0,
    this.activeReferrals = 0,
    this.pendingReferrals = 0,
    this.totalDiscountRidesEarned = 0,
    this.individualDiscountPercent,
    this.effectiveDiscountPercent = 10,
    this.tier = 'bronze',
    this.recentReferrals = const [],
    this.pointsPerRide = 5,
    this.pointToNairaRate = 1.0,
    this.maxPointsRedeemPercent = 50.0,
  });

  /// Naira value of available Sarri Points
  double get nairaBalance => availablePoints * pointToNairaRate;

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final stats = data['stats'] as Map<String, dynamic>? ?? {};

    return ReferralModel(
      referralCode:              data['referralCode'] as String?,
      referralLink:              data['referralLink'] as String?,
      referralType:              data['referralType'] as String? ?? 'rider',
      hasReferralProfile:        data['hasReferralProfile'] as bool? ?? true,
      turnOffReferral:           data['turnOffReferral'] as bool? ?? false,
      availablePoints:           (stats['availablePoints'] ?? data['availablePoints'] ?? 0) as int,
      totalPoints:               (stats['totalPoints'] ?? data['totalPoints'] ?? 0) as int,
      usedPoints:                (stats['usedPoints'] ?? data['usedPoints'] ?? 0) as int,
      totalReferrals:            (stats['totalReferrals'] ?? data['totalReferrals'] ?? 0) as int,
      completedReferrals:        (stats['completedReferrals'] ?? data['completedReferrals'] ?? 0) as int,
      activeReferrals:           (stats['activeReferrals'] ?? data['activeReferrals'] ?? 0) as int,
      pendingReferrals:          (stats['pendingReferrals'] ?? data['pendingReferrals'] ?? 0) as int,
      totalDiscountRidesEarned:  (data['totalDiscountRidesEarned'] ?? 0) as int,
      individualDiscountPercent: (data['individualDiscountPercent'] as num?)?.toDouble(),
      effectiveDiscountPercent:  (data['effectiveDiscountPercent'] as num?)?.toDouble() ?? 10,
      tier:                      stats['tier'] ?? data['tier'] ?? 'bronze',
      recentReferrals: (data['recentReferrals'] as List<dynamic>? ?? [])
          .map((e) => ReferralHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ReferralModel copyWith({
    String? referralCode,
    String? referralType,
    int? availablePoints,
    int? totalPoints,
    int? usedPoints,
    String? tier,
  }) {
    return ReferralModel(
      referralCode: referralCode ?? this.referralCode,
      referralLink: referralLink,
      referralType: referralType ?? this.referralType,
      hasReferralProfile: hasReferralProfile,
      turnOffReferral: turnOffReferral,
      availablePoints: availablePoints ?? this.availablePoints,
      totalPoints: totalPoints ?? this.totalPoints,
      usedPoints: usedPoints ?? this.usedPoints,
      totalReferrals: totalReferrals,
      completedReferrals: completedReferrals,
      activeReferrals: activeReferrals,
      pendingReferrals: pendingReferrals,
      totalDiscountRidesEarned: totalDiscountRidesEarned,
      individualDiscountPercent: individualDiscountPercent,
      effectiveDiscountPercent: effectiveDiscountPercent,
      tier: tier ?? this.tier,
      recentReferrals: recentReferrals,
      pointsPerRide: pointsPerRide,
      pointToNairaRate: pointToNairaRate,
      maxPointsRedeemPercent: maxPointsRedeemPercent,
    );
  }
}

class ReferralHistoryItem {
  final String name;
  final DateTime joinedAt;
  final String status;
  final DateTime? firstTripCompleted;
  final int pointsEarned;
  final int totalRidesCompleted;
  final int discountRidesEarned;

  const ReferralHistoryItem({
    required this.name,
    required this.joinedAt,
    required this.status,
    this.firstTripCompleted,
    this.pointsEarned = 0,
    this.totalRidesCompleted = 0,
    this.discountRidesEarned = 0,
  });

  factory ReferralHistoryItem.fromJson(Map<String, dynamic> json) {
    return ReferralHistoryItem(
      name:                json['name'] as String? ?? 'User',
      joinedAt:            DateTime.tryParse(json['joinedAt'] as String? ?? '') ?? DateTime.now(),
      status:              json['status'] as String? ?? 'pending',
      firstTripCompleted:  json['firstTripCompleted'] != null
          ? DateTime.tryParse(json['firstTripCompleted'] as String)
          : null,
      pointsEarned:        (json['pointsEarned'] ?? 0) as int,
      totalRidesCompleted: (json['totalRidesCompleted'] ?? 0) as int,
      discountRidesEarned: (json['discountRidesEarned'] ?? 0) as int,
    );
  }
}
