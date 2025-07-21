import 'package:sweph/sweph.dart';

/// Constants used throughout the Veda Jyoti application
/// Contains astrological, astronomical and application constants

/// Zodiac sign names in English
const List<String> zodiacSigns = [
  'Aries', 'Taurus', 'Gemini', 'Cancer', 
  'Leo', 'Virgo', 'Libra', 'Scorpio', 
  'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
];

/// Planet names in English
const List<String> planetNames = [
  'Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 
  'Saturn', 'Rahu', 'Ketu', 'Venus'
];

/// Swiss Ephemeris planet indices as HeavenlyBody enum values
const List<HeavenlyBody> planetIndices = [
  HeavenlyBody.SE_SUN,      // Sun
  HeavenlyBody.SE_MOON,     // Moon
  HeavenlyBody.SE_MARS,     // Mars
  HeavenlyBody.SE_MERCURY,  // Mercury
  HeavenlyBody.SE_JUPITER,  // Jupiter
  HeavenlyBody.SE_SATURN,   // Saturn
  HeavenlyBody.SE_MEAN_NODE, // Rahu (North Node)
  HeavenlyBody.SE_TRUE_NODE, // Ketu (will be calculated separately)
  HeavenlyBody.SE_VENUS,    // Venus
];

/// Essential ephemeris files needed for basic calculations
/// This is a simplified list for the basic app - the full app uses all files
const List<String> essentialEpheFiles = [
  'assets/ephe/semo_00.se1',
  'assets/ephe/semo_06.se1', 
  'assets/ephe/semo_12.se1',
  'assets/ephe/semo_18.se1',
  'assets/ephe/semo_24.se1',
  'assets/ephe/semo_30.se1',
  'assets/ephe/semo_36.se1',
  'assets/ephe/semo_42.se1',
  'assets/ephe/semo_48.se1',
  'assets/ephe/semo_54.se1',
  'assets/ephe/semo_60.se1',
  'assets/ephe/semo_66.se1',
  'assets/ephe/semo_72.se1',
  'assets/ephe/semo_78.se1',
  'assets/ephe/semo_84.se1',
  'assets/ephe/semo_90.se1',
  'assets/ephe/semo_96.se1',
  'assets/ephe/sepl_00.se1',
  'assets/ephe/sepl_06.se1',
  'assets/ephe/sepl_12.se1',
  'assets/ephe/sepl_18.se1',
  'assets/ephe/sepl_24.se1',
  'assets/ephe/sepl_30.se1',
  'assets/ephe/sepl_36.se1',
  'assets/ephe/sepl_42.se1',
  'assets/ephe/sepl_48.se1',
  'assets/ephe/sepl_54.se1',
  'assets/ephe/sepl_60.se1',
  'assets/ephe/sepl_66.se1',
  'assets/ephe/sepl_72.se1',
  'assets/ephe/sepl_78.se1',
  'assets/ephe/sepl_84.se1',
  'assets/ephe/sepl_90.se1',
  'assets/ephe/sepl_96.se1',
];