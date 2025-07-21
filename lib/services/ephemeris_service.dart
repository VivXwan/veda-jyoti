import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sweph/sweph.dart';
import '../models/planet.dart';
import '../utils/constants.dart';
import 'ephemeris_manager.dart';

class EphemerisService {
  bool _isInitialized = false;
  String? _ephemerisPath;
  
  bool get isInitialized => _isInitialized;
  String? get ephemerisPath => _ephemerisPath;

  /// Initialize the Swiss Ephemeris with required ephemeris files
  /// This must be called before any calculations are performed
  Future<bool> initialize({EphemerisManager? ephemerisManager}) async {
    if (_isInitialized) return true; // Already initialized
    
    try {
      print('Initializing Swiss Ephemeris...');
      
      // Set up ephemeris directory path
      await _setupEphemerisPath();
      
      // Copy bundled assets to local storage if needed
      if (ephemerisManager != null) {
        await _copyBundledAssets(ephemerisManager);
      }
      
      // Get list of available ephemeris files from local storage
      final availableFiles = await _getAvailableEphemerisFiles();
      
      if (availableFiles.isEmpty) {
        // Fallback to bundled assets if no local files
        await Sweph.init(epheAssets: essentialEpheFiles);
      } else {
        // Initialize with local ephemeris directory
        // Note: We'll use the assets approach for now and copy files to the expected location
        await Sweph.init(epheAssets: essentialEpheFiles);
      }
      
      _isInitialized = true;
      print('Swiss Ephemeris initialized successfully with ${availableFiles.length} files');
      return true;
    } catch (e) {
      print('Error initializing ephemeris service: $e');
      return false;
    }
  }

  /// Set up the local ephemeris directory path
  Future<void> _setupEphemerisPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    _ephemerisPath = '${appDir.path}/ephe';
    
    // Ensure directory exists
    final epheDir = Directory(_ephemerisPath!);
    if (!await epheDir.exists()) {
      await epheDir.create(recursive: true);
    }
  }

  /// Copy bundled ephemeris assets to local storage on first run
  Future<void> _copyBundledAssets(EphemerisManager manager) async {
    try {
      // Get the default/essential files from the manifest
      final manifest = await manager.getManifest();
      final downloadedFiles = await manager.getDownloadedFiles();
      
      // Check if we need to copy default files
      final missingDefaults = manifest.defaultFiles
          .where((file) => !downloadedFiles.contains(file))
          .toList();
      
      if (missingDefaults.isNotEmpty) {
        print('Missing default ephemeris files: $missingDefaults');
        // For now, we'll assume these are handled by the download process
        // In a complete implementation, you might copy from assets here
      }
    } catch (e) {
      print('Warning: Could not check for bundled assets: $e');
    }
  }

  /// Get list of available ephemeris files in local storage
  Future<List<String>> _getAvailableEphemerisFiles() async {
    try {
      if (_ephemerisPath == null) return [];
      
      final epheDir = Directory(_ephemerisPath!);
      if (!await epheDir.exists()) return [];
      
      final files = await epheDir.list().toList();
      return files
          .where((file) => file is File && 
                 (file.path.endsWith('.se1') || 
                  file.path.endsWith('.txt')))
          .map((file) => file.path.split('/').last)
          .toList();
    } catch (e) {
      print('Error getting available ephemeris files: $e');
      return [];
    }
  }

  /// Re-initialize the service when new files are downloaded
  Future<bool> reinitialize({EphemerisManager? ephemerisManager}) async {
    _isInitialized = false;
    return await initialize(ephemerisManager: ephemerisManager);
  }

  /// Check if the service is initialized and throw an exception if not
  void _checkInitialization() {
    if (!_isInitialized) {
      throw Exception('Ephemeris service not initialized. Call initialize() first.');
    }
  }

  /// Convert Gregorian date to Julian Day
  double dateTimeToJulianDay(int year, int month, int day, double hour) {
    return Sweph.swe_julday(
      year,
      month,
      day,
      hour,
      CalendarType.SE_GREG_CAL,
    );
  }

  /// Calculate planetary positions for a given date and time
  Future<List<Planet>> calculatePlanetPositions(
    int year,
    int month,
    int day,
    double hour, {
    bool isSidereal = true,
  }) async {
    _checkInitialization();
    
    // Convert to Julian Day
    final julianDay = dateTimeToJulianDay(year, month, day, hour);
    
    // Calculate planetary positions
    return calculatePlanetaryPositions(julianDay, isSidereal: isSidereal);
  }

  /// Calculate planetary positions for a given Julian Day
  List<Planet> calculatePlanetaryPositions(double julianDay, {bool isSidereal = true}) {
    _checkInitialization();
    
    // Set calculation flags
    final SwephFlag flags = isSidereal 
        ? (SwephFlag.SEFLG_SIDEREAL | SwephFlag.SEFLG_SPEED)
        : SwephFlag.SEFLG_SPEED;
    
    final planets = <Planet>[];
    
    // Calculate positions for all planets
    for (int i = 0; i < planetIndices.length; i++) {
      // Special case for Ketu (South Node)
      if (i == 7) { // Ketu
        // Get Rahu's position (must be calculated before Ketu)
        final rahuPlanet = planets.firstWhere((p) => p.index == 6);
        // Ketu is exactly opposite to Rahu
        final ketuLongitude = (rahuPlanet.longitude + 180.0) % 360.0;
        
        planets.add(Planet(
          index: i,
          longitude: ketuLongitude,
          latitude: -rahuPlanet.latitude, // Opposite latitude
          speed: rahuPlanet.speed, // Same speed as Rahu
          house: 0, // House will be calculated later
        ));
      } else {
        try {
          // Calculate position using Swiss Ephemeris
          final result = Sweph.swe_calc_ut(
            julianDay,
            planetIndices[i],
            flags,
          );
          
          // Extract speed (daily motion)
          double speed = 0.0;
          try {
            final dynamic dynamicResult = result;
            if (dynamicResult.speedInLongitude != null) {
              speed = dynamicResult.speedInLongitude;
            }
          } catch (e) {
            // Speed calculation failed, continue with 0.0
          }
          
          planets.add(Planet(
            index: i,
            longitude: result.longitude,
            latitude: result.latitude,
            speed: speed,
            house: 0, // House will be calculated later
          ));
        } catch (e) {
          throw Exception('Failed to calculate position for planet ${planetNames[i]}: $e');
        }
      }
    }
    
    return planets;
  }

  /// Calculate the ascendant (Lagna) degree for a given time and location
  double calculateAscendant(
    double julianDay, 
    double latitude, 
    double longitude, {
    bool isSidereal = true,
  }) {
    _checkInitialization();
    
    try {
      // Use Whole house system which is standard in Vedic astrology
      final houses = Sweph.swe_houses(
        julianDay,
        latitude,
        longitude,
        Hsys.W, // Whole house system from the sweph package
      );
      
      // Calculate ayanamsa for sidereal calculations
      final ayanamsa = isSidereal 
          ? Sweph.swe_get_ayanamsa_ex_ut(julianDay, SwephFlag.SEFLG_SIDEREAL)
          : 0.0;
      
      // The ascendant is the first entry in ascmc array
      return houses.ascmc[0] - ayanamsa;
    } catch (e) {
      throw Exception('Failed to calculate ascendant: $e');
    }
  }

  /// Calculate houses for all planets in the chart
  List<Planet> calculateHousesForPlanets(
    List<Planet> planets,
    double ascendantDegree,
  ) {
    final ascendantSignIndex = (ascendantDegree ~/ 30).toInt() % 12;
    
    return planets.map((planet) {
      final planetSignIndex = planet.signIndex;
      
      final house = ((planetSignIndex - ascendantSignIndex + 12) % 12) + 1;
      
      return planet.copyWith(house: house);
    }).toList();
  }
}

// Riverpod provider for the ephemeris service
final ephemerisServiceProvider = Provider<EphemerisService>((ref) {
  return EphemerisService();
});