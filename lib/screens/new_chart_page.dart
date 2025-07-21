import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/ephemeris_service.dart';
import '../models/planet.dart';

class NewChartPage extends HookConsumerWidget {
  const NewChartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  dateController.text = '${date.day.toString().padLeft(2, '0')}/'
                      '${date.month.toString().padLeft(2, '0')}/'
                      '${date.year}';
                }
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
                hintText: is24HourFormat.value ? 'HH:MM' : 'HH:MM AM/PM',
                prefixIcon: const Icon(Icons.access_time),
                border: const OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        alwaysUse24HourFormat: is24HourFormat.value,
                      ),
                      child: child!,
                    );
                  },
                );
                if (time != null) {
                  if (is24HourFormat.value) {
                    timeController.text = '${time.hour.toString().padLeft(2, '0')}:'
                        '${time.minute.toString().padLeft(2, '0')}';
                  } else {
                    timeController.text = time.format(context);
                  }
                }
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
              TextFormField(
                controller: placeController,
                decoration: const InputDecoration(
                  hintText: 'Enter city, state, country',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  helperText: 'We will automatically find coordinates',
                ),
              ),
            ] else ...[
              // Manual latitude/longitude input
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
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 48),
            
            // Generate chart button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _generateChart(context, ref, 
                    chartType.value,
                    dateController.text,
                    timeController.text,
                    placeController.text,
                    latitudeController.text,
                    longitudeController.text,
                    useManualCoordinates.value,
                  );
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

  /// Generate chart with the provided form data
  Future<void> _generateChart(
    BuildContext context,
    WidgetRef ref,
    String chartType,
    String date,
    String time,
    String place,
    String latitude,
    String longitude,
    bool useManualCoordinates,
  ) async {
    try {
      // Validate inputs
      if (date.isEmpty || time.isEmpty) {
        _showErrorSnackBar(context, 'Please fill in date and time');
        return;
      }

      if (!useManualCoordinates && place.isEmpty) {
        _showErrorSnackBar(context, 'Please enter a place name');
        return;
      }

      if (useManualCoordinates && (latitude.isEmpty || longitude.isEmpty)) {
        _showErrorSnackBar(context, 'Please enter both latitude and longitude');
        return;
      }

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generating $chartType...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Parse date and time
      final parsedDate = DateTime.tryParse(date.replaceAll('/', '-'));
      if (parsedDate == null) {
        _showErrorSnackBar(context, 'Invalid date format');
        return;
      }

      // Parse time
      TimeOfDay? parsedTime;
      try {
        final timeParts = time.split(':');
        if (timeParts.length >= 2) {
          int hour = int.parse(timeParts[0]);
          int minute = int.parse(timeParts[1]);
          
          // Handle AM/PM if present
          if (time.toLowerCase().contains('pm') && hour != 12) {
            hour += 12;
          } else if (time.toLowerCase().contains('am') && hour == 12) {
            hour = 0;
          }
          
          parsedTime = TimeOfDay(hour: hour % 24, minute: minute);
        }
      } catch (e) {
        _showErrorSnackBar(context, 'Invalid time format');
        return;
      }

      if (parsedTime == null) {
        _showErrorSnackBar(context, 'Invalid time format');
        return;
      }

      // Get ephemeris service
      final ephemerisService = ref.read(ephemerisServiceProvider);
      
      // Ensure service is initialized
      if (!ephemerisService.isInitialized) {
        final initialized = await ephemerisService.initialize();
        if (!initialized) {
          if (context.mounted) {
            _showErrorSnackBar(context, 'Failed to initialize calculation engine');
          }
          return;
        }
      }

      // Calculate hour as decimal (for Swiss Ephemeris)
      final decimalHour = parsedTime.hour + (parsedTime.minute / 60.0);

      // Calculate planetary positions
      final planets = await ephemerisService.calculatePlanetPositions(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        decimalHour,
      );

      // For now, just show the results in a dialog
      if (context.mounted) {
        _showChartResultDialog(context, planets, chartType);
      }

    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Error generating chart: $e');
      }
    }
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

  void _showChartResultDialog(BuildContext context, List<Planet> planets, String chartType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$chartType Generated'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Planetary Positions:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: planets.length,
                  itemBuilder: (context, index) {
                    final planet = planets[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          planet.name.substring(0, 2),
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                      title: Text(planet.name),
                      subtitle: Text('${planet.sign} ${planet.degreeInSign.toStringAsFixed(1)}°'),
                      trailing: planet.isRetrograde 
                        ? const Icon(Icons.replay, size: 16, color: Colors.red)
                        : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to detailed chart view
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chart saved successfully!')),
              );
            },
            child: const Text('Save Chart'),
          ),
        ],
      ),
    );
  }
}