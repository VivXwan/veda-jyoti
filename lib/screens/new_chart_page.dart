import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/ephemeris_service.dart';
import '../models/planet.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';


class NewChartPage extends HookConsumerWidget {
  const NewChartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🏗️ BUILD DEBUG: NewChartPage build method called');
    
    // Chart type state
    final chartType = useState<String>('Birth Chart');
    
    // Form controllers
    final dateController = useTextEditingController();
    final timeController = useTextEditingController();
    final placeController = useTextEditingController();
    final latitudeController = useTextEditingController();
    final longitudeController = useTextEditingController();
    
    // UI state
    final is24HourFormat = useState<bool>(false);
    final useManualCoordinates = useState<bool>(false);
    
    // Geocoding state
    final geocodingResults = useState<List<Map<String, dynamic>>>([]);
    final isLoadingGeocoding = useState<bool>(false);
    final geocodingTimer = useRef<Timer?>(null);
    final skipNextGeocodingCall = useRef<bool>(false);
    
    // Location state (from geocoding)
    final selectedLocation = useState<Map<String, dynamic>>({});
    
    // Timezone state
    final currentTimezone = useState<Map<String, dynamic>>({});
    final isLoadingTimezone = useState<bool>(false);
    final timezoneTimer = useRef<Timer?>(null);
    
    // Flag to prevent location updates during auto-population
    final isAutoPopulating = useRef<bool>(false);
    
    print('🏗️ BUILD DEBUG: State variables initialized - geocodingResults: ${geocodingResults.value.length} items, selectedLocation: "${selectedLocation.value}", currentTimezone: "${currentTimezone.value}"');
    
    // Watch for manual coordinate mode changes and pre-populate fields
    useEffect(() {
      if (useManualCoordinates.value && selectedLocation.value.isNotEmpty) {
        final lat = selectedLocation.value['latitude'] as double?;
        final lng = selectedLocation.value['longitude'] as double?;
        
        if (lat != null && lng != null) {
          print('🔄 MODE SWITCH DEBUG: Auto-populating coordinate fields - Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}');
          isAutoPopulating.value = true;
          latitudeController.text = lat.toStringAsFixed(6);
          longitudeController.text = lng.toStringAsFixed(6);
          // Reset flag after a brief delay to allow both fields to update
          Future.delayed(const Duration(milliseconds: 100), () {
            isAutoPopulating.value = false;
          });
        }
      }
      return null;
    }, [useManualCoordinates.value]);
    
    // Also watch for selectedLocation changes to update fields if already in manual mode
    useEffect(() {
      if (useManualCoordinates.value && selectedLocation.value.isNotEmpty) {
        final lat = selectedLocation.value['latitude'] as double?;
        final lng = selectedLocation.value['longitude'] as double?;
        
        if (lat != null && lng != null && selectedLocation.value['place_id'] != 'manual') {
          // Only auto-populate if this is not a manual location (to prevent circular updates)
          print('🔄 LOCATION UPDATE DEBUG: Updating coordinate fields with new location - Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}');
          isAutoPopulating.value = true;
          latitudeController.text = lat.toStringAsFixed(6);
          longitudeController.text = lng.toStringAsFixed(6);
          // Reset flag after a brief delay to allow both fields to update
          Future.delayed(const Duration(milliseconds: 100), () {
            isAutoPopulating.value = false;
          });
        }
      }
      return null;
    }, [selectedLocation.value]);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
            Text(
              'Create New Chart',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Chart type selection
            Text(
              'Chart Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Birth Chart'),
                    selected: chartType.value == 'Birth Chart',
                    onSelected: (selected) {
                      if (selected) chartType.value = 'Birth Chart';
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Prashna Chart'),
                    selected: chartType.value == 'Prashna Chart',
                    onSelected: (selected) {
                      if (selected) chartType.value = 'Prashna Chart';
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Date input
            Text(
              'Date',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            TextFormField(
              controller: dateController,
              decoration: const InputDecoration(
                hintText: 'DD/MM/YYYY',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                LengthLimitingTextInputFormatter(10),
                DateInputFormatter(),
              ],
              onChanged: (value) {
                // Parse and update Riverpod provider if needed
                // For now, we'll just update the controller
              },
            ),
            
            const SizedBox(height: 24),
            
            // Time input with format toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Time',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text('24-hour format'),
                Switch(
                  value: is24HourFormat.value,
                  onChanged: (value) => is24HourFormat.value = value,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            TextFormField(
              controller: timeController,
              decoration: InputDecoration(
                hintText: is24HourFormat.value ? 'HH:MM:SS' : 'HH:MM:SS AM/PM',
                prefixIcon: const Icon(Icons.access_time),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9:APMapm\s]')),
                LengthLimitingTextInputFormatter(11),
                TimeInputFormatter(is24Hour: is24HourFormat.value),
              ],
              onChanged: (value) {
                // Parse and update Riverpod provider if needed
                // For now, we'll just update the controller
              },
            ),
            
            const SizedBox(height: 24),
            
            // Place input with coordinate toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text('Manual coordinates'),
                Switch(
                  value: useManualCoordinates.value,
                  onChanged: (value) => useManualCoordinates.value = value,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            if (!useManualCoordinates.value) ...[
              // Place name input for auto-geocoding
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: placeController,
                    decoration: InputDecoration(
                      hintText: 'Enter city, state, country',
                      prefixIcon: const Icon(Icons.location_on),
                      border: const OutlineInputBorder(),
                      helperText: 'We will automatically find coordinates',
                      suffixIcon: isLoadingGeocoding.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      print('📝 UI DEBUG: Location field onChanged triggered with value: "$value"');
                      _onLocationTextChanged(value, geocodingTimer, geocodingResults, isLoadingGeocoding, skipNextGeocodingCall, selectedLocation);
                    },
                  ),
                  if (geocodingResults.value.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: geocodingResults.value.length,
                        itemBuilder: (context, index) {
                          final result = geocodingResults.value[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place, size: 20),
                            title: Text(
                              result['display_name'] ?? 'Unknown location',
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: result['lat'] != null && result['lon'] != null
                                ? Text(
                                    'Lat: ${result['lat']}, Lon: ${result['lon']}',
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                            onTap: () {
                              print('🎯 SELECTION DEBUG: User selected location: ${result['display_name']}');
                              _selectGeocodingResult(result, placeController, geocodingResults, skipNextGeocodingCall, selectedLocation, currentTimezone, latitudeController, longitudeController);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  // Display selected location info if available
                  if (selectedLocation.value.isNotEmpty && !useManualCoordinates.value) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 20, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Selected Location',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildLocationInfoRow('Place:', selectedLocation.value['place_name'] ?? 'Unknown'),
                          _buildLocationInfoRow('Latitude:', (selectedLocation.value['latitude'] as double?)?.toStringAsFixed(6) ?? '0.0'),
                          _buildLocationInfoRow('Longitude:', (selectedLocation.value['longitude'] as double?)?.toStringAsFixed(6) ?? '0.0'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ] else ...[
              // Manual latitude/longitude input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: latitudeController,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            hintText: '0.0000',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          onChanged: (value) {
                            print('📝 UI DEBUG: Latitude field onChanged triggered with value: "$value"');
                            print('📝 UI DEBUG: Current longitude value: "${longitudeController.text}"');
                            
                            // Update selectedLocation with manual coordinates
                            final lat = double.tryParse(value) ?? 0.0;
                            final lng = double.tryParse(longitudeController.text) ?? 0.0;
                            selectedLocation.value = {
                              'place_name': 'Manual Location',
                              'latitude': lat,
                              'longitude': lng,
                              'place_id': 'manual',
                              'importance': 1.0,
                              'address': {},
                            };
                            
                            _onCoordinateChanged(latitudeController.text, longitudeController.text, 
                                timezoneTimer, currentTimezone, isLoadingTimezone, selectedLocation, isAutoPopulating, placeController, skipNextGeocodingCall);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: longitudeController,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            hintText: '0.0000',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          onChanged: (value) {
                            print('📝 UI DEBUG: Longitude field onChanged triggered with value: "$value"');
                            print('📝 UI DEBUG: Current latitude value: "${latitudeController.text}"');
                            
                            // Update selectedLocation with manual coordinates
                            final lat = double.tryParse(latitudeController.text) ?? 0.0;
                            final lng = double.tryParse(value) ?? 0.0;
                            selectedLocation.value = {
                              'place_name': 'Manual Location',
                              'latitude': lat,
                              'longitude': lng,
                              'place_id': 'manual',
                              'importance': 1.0,
                              'address': {},
                            };
                            
                            _onCoordinateChanged(latitudeController.text, longitudeController.text, 
                                timezoneTimer, currentTimezone, isLoadingTimezone, selectedLocation, isAutoPopulating, placeController, skipNextGeocodingCall);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (currentTimezone.value.isNotEmpty || isLoadingTimezone.value) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 20, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              if (isLoadingTimezone.value) ...[
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                const Text('Calculating timezone...'),
                              ] else ...[
                                Text(
                                  'Timezone Information',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (!isLoadingTimezone.value && currentTimezone.value.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildTimezoneInfoRow('ID:', currentTimezone.value['timeZoneId'] ?? 'Unknown'),
                            _buildTimezoneInfoRow('Name:', currentTimezone.value['timeZoneName'] ?? 'Unknown'),
                            _buildTimezoneInfoRow('Raw Offset:', '${(currentTimezone.value['rawOffset'] ?? 0) ~/ 3600}h ${((currentTimezone.value['rawOffset'] ?? 0) % 3600) ~/ 60}m'),
                            _buildTimezoneInfoRow('DST Offset:', '${(currentTimezone.value['dstOffset'] ?? 0) ~/ 3600}h ${((currentTimezone.value['dstOffset'] ?? 0) % 3600) ~/ 60}m'),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
            
            const SizedBox(height: 48),
            
            // Generate chart button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // Validate required fields
                    if (dateController.text.isEmpty || timeController.text.isEmpty) {
                      _showErrorSnackBar(context, 'Please enter date and time');
                      return;
                    }

                    if (selectedLocation.value.isEmpty) {
                      _showErrorSnackBar(context, 'Please select a location or enter coordinates');
                      return;
                    }

                    // 1. Parse Date and Time
                    final dateParts = dateController.text.split('/');
                    final timeParts = timeController.text.split(':');
                    if (dateParts.length != 3 || timeParts.length < 2) {
                      _showErrorSnackBar(context, 'Please enter valid date (DD/MM/YYYY) and time (HH:MM)');
                      return;
                    }
                    
                    final year = int.tryParse(dateParts[2]);
                    final month = int.tryParse(dateParts[1]);
                    final day = int.tryParse(dateParts[0]);
                    final hourInt = int.tryParse(timeParts[0]);
                    final minuteInt = int.tryParse(timeParts[1]);
                    final secondInt = timeParts.length > 2 ? int.tryParse(timeParts[2]) ?? 0 : 0;
                    DateTime chartDateTime = DateTime(year!, month!, day!, hourInt!, minuteInt!, secondInt);

                    if (year == null || month == null || day == null || hourInt == null || minuteInt == null) {
                      _showErrorSnackBar(context, 'Invalid date or time format');
                      return;
                    }

                    // 2. Get Location and Timezone from selectedLocation (single source of truth)
                    final latitude = selectedLocation.value['latitude'] as double?;
                    final longitude = selectedLocation.value['longitude'] as double?;

                    if (latitude == null || longitude == null || latitude == 0.0 && longitude == 0.0) {
                      _showErrorSnackBar(context, 'Invalid location coordinates. Please select a location.');
                      return;
                    }

                    final rawOffset = currentTimezone.value['rawOffset'] as int? ?? 0;
                    final dstOffset = currentTimezone.value['dstOffset'] as int? ?? 0;
                    print("rawOffset: $rawOffset, dstOffset: $dstOffset");

                    // 3. Calculate local time and timezone offset
                    final localHour = hourInt + (minuteInt / 60.0) + (secondInt / 3600.0);
                    final timezoneOffsetInHours = rawOffset / 3600.0;

                    // Show loading indicator
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calculating planetary positions...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }

                    // 4. Calculate Planets
                    final ephemerisService = ref.read(ephemerisServiceProvider);
                    
                    // Initialize service if needed
                    if (!ephemerisService.isInitialized) {
                      final initialized = await ephemerisService.initialize();
                      if (!initialized) {
                        if (context.mounted) {
                          _showErrorSnackBar(context, 'Failed to initialize ephemeris service');
                        }
                        return;
                      }
                    }

                    final planets = await ephemerisService.calculatePlanetPositions(
                      chartDateTime,
                      timezoneOffsetInHours,
                      longitude,
                      latitude,
                    );

                    print('🌟 CALCULATION DEBUG:');
                    print('   Calculated ${planets.length} planetary positions');

                    // 5. Navigate to Display Screen
                    if (context.mounted) {
                      GoRouter.of(context).push('/chart_display', extra: planets);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showErrorSnackBar(context, 'Error generating chart: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text(
                  'Generate Chart',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chart Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Birth Chart: Traditional natal chart based on birth date, time, and location\n'
                      '• Prashna Chart: Horary chart for answering specific questions\n'
                      '• All calculations use precise Swiss Ephemeris data\n'
                      '• Charts can be saved and exported in various formats',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  

  /// Build a timezone information row
  Widget _buildTimezoneInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a location information row
  Widget _buildLocationInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle location text changes with debounce
  void _onLocationTextChanged(
    String value,
    ObjectRef<Timer?> geocodingTimer,
    ValueNotifier<List<Map<String, dynamic>>> geocodingResults,
    ValueNotifier<bool> isLoadingGeocoding,
    ObjectRef<bool> skipNextGeocodingCall,
    ValueNotifier<Map<String, dynamic>> selectedLocation,
  ) {
    print('🔍 GEOCODING DEBUG: Location text changed to: "$value"');
    
    // Check if we should skip this call (programmatic update)
    if (skipNextGeocodingCall.value) {
      print('🔍 GEOCODING DEBUG: Skipping geocoding call (programmatic update)');
      skipNextGeocodingCall.value = false;
      return;
    }
    
    // Clear previously selected location when user starts typing manually
    if (selectedLocation.value.isNotEmpty) {
      print('🔍 GEOCODING DEBUG: Clearing previously selected location');
      selectedLocation.value = {};
    }
    
    // Cancel previous timer
    geocodingTimer.value?.cancel();
    print('🔍 GEOCODING DEBUG: Previous timer cancelled');
    
    // Clear results if text is too short
    if (value.length <= 2) {
      print('🔍 GEOCODING DEBUG: Text too short (${value.length} chars), clearing results');
      geocodingResults.value = [];
      isLoadingGeocoding.value = false;
      return;
    }
    
    print('🔍 GEOCODING DEBUG: Starting 800ms timer for geocoding');
    // Start new timer
    geocodingTimer.value = Timer(const Duration(milliseconds: 800), () {
      print('🔍 GEOCODING DEBUG: Timer fired, calling _fetchGeocodingResults');
      _fetchGeocodingResults(value, geocodingResults, isLoadingGeocoding);
    });
  }

  /// Handle selection of a geocoding result
  void _selectGeocodingResult(
    Map<String, dynamic> result,
    TextEditingController placeController,
    ValueNotifier<List<Map<String, dynamic>>> geocodingResults,
    ObjectRef<bool> skipNextGeocodingCall,
    ValueNotifier<Map<String, dynamic>> selectedLocation,
    ValueNotifier<Map<String, dynamic>> currentTimezone,
    TextEditingController latitudeController,
    TextEditingController longitudeController,
  ) {
    print('🎯 SELECTION DEBUG: Setting skip flag and updating text field');
    
    // Set flag to skip next geocoding call
    skipNextGeocodingCall.value = true;
    
    // Update text field with selected location
    placeController.text = result['display_name'] ?? '';
    
    // Parse and store coordinates as numbers for consistent access
    final lat = double.tryParse(result['lat'] ?? '') ?? 0.0;
    final lng = double.tryParse(result['lon'] ?? '') ?? 0.0;
    
    // Store complete location information from geocoding result
    final locationInfo = {
      'place_name': result['display_name'] ?? '',
      'latitude': lat,  // Store as double, not string
      'longitude': lng, // Store as double, not string
      'place_id': result['place_id'] ?? '',
      'importance': result['importance'] ?? 0.0,
      'address': result['address'] ?? {},
    };
    selectedLocation.value = locationInfo;
    
    // Update coordinate text fields immediately (for consistency when user switches to manual mode)
    latitudeController.text = lat.toStringAsFixed(6);
    longitudeController.text = lng.toStringAsFixed(6);
    
    // Update timezone information from geocoding result
    final timezoneInfo = {
      'timeZoneId': result['timeZoneId'] ?? 'Unknown',
      'timeZoneName': result['timeZoneName'] ?? 'Unknown',
      'rawOffset': result['rawOffset'] ?? 0,
      'dstOffset': result['dstOffset'] ?? 0,
    };
    currentTimezone.value = timezoneInfo;
    
    print('🎯 SELECTION DEBUG: Location field updated to: "${placeController.text}"');
    print('🎯 SELECTION DEBUG: Location data stored: $locationInfo');
    print('🎯 SELECTION DEBUG: Coordinate fields updated: Lat=${lat.toStringAsFixed(6)}, Lng=${lng.toStringAsFixed(6)}');
    print('🎯 SELECTION DEBUG: Timezone updated to: $timezoneInfo');
    
    // Clear results dropdown
    geocodingResults.value = [];
  }

  /// Fetch geocoding results from Firebase Cloud Function
  Future<void> _fetchGeocodingResults(
    String address,
    ValueNotifier<List<Map<String, dynamic>>> geocodingResults,
    ValueNotifier<bool> isLoadingGeocoding,
  ) async {
    print('🌍 GEOCODING API DEBUG: Starting geocoding for address: "$address"');
    isLoadingGeocoding.value = true;
    
    try {
      final timestampMs = DateTime.now().millisecondsSinceEpoch;
      final timestamp = (timestampMs / 1000).round(); // Convert to seconds for backend
      print('🌍 GEOCODING API DEBUG: Generated timestamp: $timestamp (converted from $timestampMs ms)');
      
      // Make request to Cloud Function (using emulator URL for testing)
      final uri = Uri.parse('http://127.0.0.1:5001/veda-jyoti/us-central1/get_geocoding')
          .replace(queryParameters: {
        'address': address,
        'timestamp': timestamp.toString(),
      });
      
      print('🌍 GEOCODING API DEBUG: Request URL: $uri');
      print('🌍 GEOCODING API DEBUG: Making HTTP GET request...');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('🌍 GEOCODING API DEBUG: Response status code: ${response.statusCode}');
      print('🌍 GEOCODING API DEBUG: Response headers: ${response.headers}');
      print('🌍 GEOCODING API DEBUG: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Backend returns a list directly, not wrapped in a 'results' key
        final results = (json.decode(response.body) as List?)?.cast<Map<String, dynamic>>() ?? [];
        print('🌍 GEOCODING API DEBUG: Parsed ${results.length} results');
        for (int i = 0; i < results.length && i < 3; i++) {
          print('🌍 GEOCODING API DEBUG: Result $i: ${results[i]}');
        }
        geocodingResults.value = results.take(5).toList(); // Limit to 5 results
        print('🌍 GEOCODING API DEBUG: Successfully set ${geocodingResults.value.length} results');
      } else {
        print('🌍 GEOCODING API DEBUG: Non-200 status code, clearing results');
        geocodingResults.value = [];
      }
    } catch (e, stackTrace) {
      print('🌍 GEOCODING API ERROR: Exception occurred: $e');
      print('🌍 GEOCODING API ERROR: Stack trace: $stackTrace');
      geocodingResults.value = [];
    } finally {
      print('🌍 GEOCODING API DEBUG: Setting loading to false');
      isLoadingGeocoding.value = false;
    }
  }

  /// Handle coordinate changes with debounce for timezone lookup
  void _onCoordinateChanged(
    String latitude,
    String longitude,
    ObjectRef<Timer?> timezoneTimer,
    ValueNotifier<Map<String, dynamic>> currentTimezone,
    ValueNotifier<bool> isLoadingTimezone,
    ValueNotifier<Map<String, dynamic>> selectedLocation,
    ObjectRef<bool> isAutoPopulating,
    TextEditingController placeController,
    ObjectRef<bool> skipNextGeocodingCall,
  ) {
    print('🕐 TIMEZONE DEBUG: Coordinate changed - Lat: "$latitude", Lng: "$longitude"');
    print('🕐 TIMEZONE DEBUG: isAutoPopulating flag: ${isAutoPopulating.value}');
    
    // Cancel previous timer
    timezoneTimer.value?.cancel();
    print('🕐 TIMEZONE DEBUG: Previous timer cancelled');
    
    // Clear timezone if coordinates are empty
    final lat = double.tryParse(latitude);
    final lng = double.tryParse(longitude);
    
    print('🕐 TIMEZONE DEBUG: Parsed coordinates - Lat: $lat, Lng: $lng');
    
    if (lat == null || lng == null) {
      print('🕐 TIMEZONE DEBUG: Invalid coordinates, clearing timezone');
      currentTimezone.value = {};
      isLoadingTimezone.value = false;
      return;
    }
    
    // Update stored location if this is a manual change (not auto-population)  
    if (!isAutoPopulating.value && selectedLocation.value.isNotEmpty) {
      print('🔄 MANUAL COORDINATE DEBUG: Updating stored location with manual coordinates');
      final updatedLocation = {
        'place_name': 'Manual location',
        'latitude': latitude,
        'longitude': longitude,
        'place_id': 'manual',
        'importance': 1.0,
        'address': {'display_name': 'Manual location'},
      };
      selectedLocation.value = updatedLocation;
      
      // Clear the place text field when switching to manual location (set skip flag first)
      print('🔄 MANUAL COORDINATE DEBUG: Clearing place text field');
      skipNextGeocodingCall.value = true;
      placeController.clear();
      
      print('🔄 MANUAL COORDINATE DEBUG: Updated location: $updatedLocation');
    } else if (!isAutoPopulating.value && selectedLocation.value.isEmpty) {
      // If no previous location was stored, create a new manual location entry
      print('🔄 MANUAL COORDINATE DEBUG: Creating new manual location entry');
      final newLocation = {
        'place_name': 'Manual location',
        'latitude': latitude,
        'longitude': longitude,
        'place_id': 'manual',
        'importance': 1.0,
        'address': {'display_name': 'Manual location'},
      };
      selectedLocation.value = newLocation;
      
      // Clear the place text field for new manual location (set skip flag first)
      print('🔄 MANUAL COORDINATE DEBUG: Clearing place text field for new manual location');
      skipNextGeocodingCall.value = true;
      placeController.clear();
      
      print('🔄 MANUAL COORDINATE DEBUG: Created location: $newLocation');
    }
    
    print('🕐 TIMEZONE DEBUG: Starting 800ms timer for timezone lookup');
    // Start new timer
    timezoneTimer.value = Timer(const Duration(milliseconds: 800), () {
      print('🕐 TIMEZONE DEBUG: Timer fired, calling _fetchTimezone');
      _fetchTimezone(lat, lng, currentTimezone, isLoadingTimezone);
    });
  }

  /// Fetch timezone from Firebase Cloud Function
  Future<void> _fetchTimezone(
    double latitude,
    double longitude,
    ValueNotifier<Map<String, dynamic>> currentTimezone,
    ValueNotifier<bool> isLoadingTimezone,
  ) async {
    print('⏰ TIMEZONE API DEBUG: Starting timezone lookup for Lat: $latitude, Lng: $longitude');
    isLoadingTimezone.value = true;
    
    try {
      final timestampMs = DateTime.now().millisecondsSinceEpoch;
      final timestamp = (timestampMs / 1000).round(); // Convert to seconds for backend
      print('⏰ TIMEZONE API DEBUG: Generated timestamp: $timestamp (converted from $timestampMs ms)');
      
      // Make request to Cloud Function (using emulator URL for testing)
      final uri = Uri.parse('http://127.0.0.1:5001/veda-jyoti/us-central1/get_timezone')
          .replace(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'timestamp': timestamp.toString(),
      });
      
      print('⏰ TIMEZONE API DEBUG: Request URL: $uri');
      print('⏰ TIMEZONE API DEBUG: Making HTTP GET request...');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('⏰ TIMEZONE API DEBUG: Response status code: ${response.statusCode}');
      print('⏰ TIMEZONE API DEBUG: Response headers: ${response.headers}');
      print('⏰ TIMEZONE API DEBUG: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final timezoneInfo = {
          'timeZoneId': data['timeZoneId'] ?? 'Unknown',
          'timeZoneName': data['timeZoneName'] ?? 'Unknown',
          'rawOffset': data['rawOffset'] ?? 0,
          'dstOffset': data['dstOffset'] ?? 0,
        };
        print('⏰ TIMEZONE API DEBUG: Parsed timezone data: $timezoneInfo');
        currentTimezone.value = timezoneInfo;
        print('⏰ TIMEZONE API DEBUG: Successfully set timezone to: ${currentTimezone.value}');
      } else {
        print('⏰ TIMEZONE API DEBUG: Non-200 status code, setting error message');
        currentTimezone.value = {
          'timeZoneId': 'Error',
          'timeZoneName': 'Error loading timezone',
          'rawOffset': 0,
          'dstOffset': 0,
        };
      }
    } catch (e, stackTrace) {
      print('⏰ TIMEZONE API ERROR: Exception occurred: $e');
      print('⏰ TIMEZONE API ERROR: Stack trace: $stackTrace');
      currentTimezone.value = {
        'timeZoneId': 'Error',
        'timeZoneName': 'Error loading timezone',
        'rawOffset': 0,
        'dstOffset': 0,
      };
    } finally {
      print('⏰ TIMEZONE API DEBUG: Setting loading to false');
      isLoadingTimezone.value = false;
    }
  }
}

/// Custom input formatter for date fields (DD/MM/YYYY)
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Remove any non-digit characters except /
    String digitsOnly = text.replaceAll(RegExp(r'[^\d/]'), '');
    
    // Add slashes at appropriate positions
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 && digitsOnly[i] != '/') {
        formatted += '/';
      } else if (i == 5 && digitsOnly[i] != '/') {
        formatted += '/';
      }
      formatted += digitsOnly[i];
    }
    
    // Limit to DD/MM/YYYY format
    if (formatted.length > 10) {
      formatted = formatted.substring(0, 10);
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Custom input formatter for time fields (HH:MM:SS)
class TimeInputFormatter extends TextInputFormatter {
  final bool is24Hour;
  
  TimeInputFormatter({required this.is24Hour});
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (is24Hour) {
      // Remove any non-digit characters except :
      String digitsOnly = text.replaceAll(RegExp(r'[^\d:]'), '');
      
      // Add colons at appropriate positions
      String formatted = '';
      for (int i = 0; i < digitsOnly.length; i++) {
        if (i == 2 && digitsOnly[i] != ':') {
          formatted += ':';
        } else if (i == 5 && digitsOnly[i] != ':') {
          formatted += ':';
        }
        formatted += digitsOnly[i];
      }
      
      // Limit to HH:MM:SS format
      if (formatted.length > 8) {
        formatted = formatted.substring(0, 8);
      }
      
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      // For 12-hour format, allow digits, colons, spaces, A, P, M
      String filtered = text.replaceAll(RegExp(r'[^\d:APMapm\s]'), '');
      
      return TextEditingValue(
        text: filtered,
        selection: TextSelection.collapsed(offset: filtered.length),
      );
    }
  }
}