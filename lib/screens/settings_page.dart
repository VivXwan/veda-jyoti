import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Appearance settings
  String selectedFont = 'Roboto';
  double fontSize = 16.0;
  ThemeMode themeMode = ThemeMode.system;
  String colorScheme = 'Default';
  
  // Preference settings
  String chartStyle = 'North Indian';
  String planetSymbolLanguage = 'English';
  
  // Account settings
  bool cloudSyncEnabled = false;
  bool dataEncryptionEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Appearance Section
            ExpansionTile(
              title: const Text('Appearance'),
              leading: const Icon(Icons.palette),
              initiallyExpanded: false,
              children: [
                // Font selection
                ListTile(
                  title: const Text('Font'),
                  subtitle: Text(selectedFont),
                  trailing: DropdownButton<String>(
                    value: selectedFont,
                    items: ['Roboto', 'Open Sans', 'Lato', 'Montserrat']
                        .map((font) => DropdownMenuItem(
                              value: font,
                              child: Text(font),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedFont = value;
                        });
                      }
                    },
                  ),
                ),
                
                // Font size
                ListTile(
                  title: const Text('Font Size'),
                  subtitle: Slider(
                    value: fontSize,
                    min: 12.0,
                    max: 24.0,
                    divisions: 12,
                    label: fontSize.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        fontSize = value;
                      });
                    },
                  ),
                ),
                
                // Theme mode
                ListTile(
                  title: const Text('Theme'),
                  subtitle: Text(themeMode.name.capitalize()),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    items: [
                      const DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      const DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                      const DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          themeMode = value;
                        });
                      }
                    },
                  ),
                ),
                
                // Color scheme
                ListTile(
                  title: const Text('Color Scheme'),
                  subtitle: Text(colorScheme),
                  trailing: DropdownButton<String>(
                    value: colorScheme,
                    items: ['Default', 'Blue', 'Green', 'Purple', 'Orange']
                        .map((scheme) => DropdownMenuItem(
                              value: scheme,
                              child: Text(scheme),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          colorScheme = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Preferences Section
            ExpansionTile(
              title: const Text('Preferences'),
              leading: const Icon(Icons.tune),
              initiallyExpanded: false,
              children: [
                // Chart style
                ListTile(
                  title: const Text('Chart Style'),
                  subtitle: Text(chartStyle),
                  trailing: DropdownButton<String>(
                    value: chartStyle,
                    items: [
                      'North Indian',
                      'South Indian',
                      'East Indian',
                      'Western Radial'
                    ]
                        .map((style) => DropdownMenuItem(
                              value: style,
                              child: Text(style),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          chartStyle = value;
                        });
                      }
                    },
                  ),
                ),
                
                // Planet symbol language
                ListTile(
                  title: const Text('Planet Symbol Language'),
                  subtitle: Text(planetSymbolLanguage),
                  trailing: DropdownButton<String>(
                    value: planetSymbolLanguage,
                    items: ['English', 'Sanskrit', 'Hindi', 'Tamil']
                        .map((language) => DropdownMenuItem(
                              value: language,
                              child: Text(language),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          planetSymbolLanguage = value;
                        });
                      }
                    },
                  ),
                ),
                
                // Custom layout
                ListTile(
                  title: const Text('Custom Layout'),
                  subtitle: const Text('Customize chart appearance'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to custom layout screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Custom layout editor coming soon!'),
                        ),
                      );
                    },
                    child: const Text('Customize'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Account Settings Section
            ExpansionTile(
              title: const Text('Account Settings'),
              leading: const Icon(Icons.account_circle),
              initiallyExpanded: false,
              children: [
                // Username
                const ListTile(
                  title: Text('Username'),
                  subtitle: TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                
                // Password
                const ListTile(
                  title: Text('Password'),
                  subtitle: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                
                // Display name
                const ListTile(
                  title: Text('Display Name'),
                  subtitle: TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter display name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                
                // Profile picture placeholder
                ListTile(
                  title: const Text('Profile Picture'),
                  subtitle: const Text('Upload your profile picture'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement image picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image picker coming soon!'),
                        ),
                      );
                    },
                    child: const Text('Upload'),
                  ),
                ),
                
                // Cloud sync
                SwitchListTile(
                  title: const Text('Cloud Sync'),
                  subtitle: const Text('Sync charts across devices'),
                  value: cloudSyncEnabled,
                  onChanged: (value) {
                    setState(() {
                      cloudSyncEnabled = value;
                    });
                  },
                ),
                
                // Data encryption
                SwitchListTile(
                  title: const Text('Chart Data Encryption'),
                  subtitle: const Text('Encrypt saved chart data'),
                  value: dataEncryptionEnabled,
                  onChanged: (value) {
                    setState(() {
                      dataEncryptionEnabled = value;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Save settings button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implement settings save logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings saved successfully!'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCapitalize on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}