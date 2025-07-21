/// Represents a celestial body (planet, node, or mathematical point)
/// in a Vedic astrological chart with all its associated properties
class Planet {
  /// Planet index as defined in constants (0-8)
  final int index;
  
  /// Longitude in the zodiac (0-360 degrees)
  final double longitude;
  
  /// Latitude relative to the ecliptic (degrees)
  final double latitude;
  
  /// Daily motion in longitude (degrees per day)
  /// Negative values indicate retrograde motion
  final double speed;
  
  /// Sign index (0-11) corresponding to the planet's position
  final int signIndex;

  /// House occupied by the planet (1-12)
  final int house;

  /// Creates a new Planet instance
  Planet({
    required this.index,
    required this.longitude,
    required this.latitude,
    required this.speed,
    int? signIndex, 
    required this.house,
  }) : signIndex = signIndex ?? (longitude ~/ 30).toInt() % 12;

  /// Planet name in English
  String get name {
    const planetNames = [
      'Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 
      'Saturn', 'Rahu', 'Ketu', 'Venus'
    ];
    return planetNames[index];
  }
  
  /// Zodiac sign name in English
  String get sign {
    const zodiacSigns = [
      'Aries', 'Taurus', 'Gemini', 'Cancer', 
      'Leo', 'Virgo', 'Libra', 'Scorpio', 
      'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
    ];
    return zodiacSigns[signIndex];
  }
  
  /// Degrees within the sign (0-30)
  double get degreeInSign => longitude % 30;
  
  /// Whether the planet is in retrograde motion
  bool get isRetrograde => speed < 0;

  /// Creates a copy of this planet with updated values
  Planet copyWith({
    int? index,
    double? longitude,
    double? latitude,
    double? speed,
    int? signIndex,
    int? house,
  }) {
    return Planet(
      index: index ?? this.index,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      speed: speed ?? this.speed,
      signIndex: signIndex ?? this.signIndex,
      house: house ?? this.house,
    );
  }

  @override
  String toString() {
    return 'Planet(name: $name, longitude: ${longitude.toStringAsFixed(2)}°, sign: $sign, house: $house)';
  }
}