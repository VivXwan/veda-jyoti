import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SavedChartsPage extends StatelessWidget {
  const SavedChartsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page header
          Text(
            'Saved Charts',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Empty state - use SizedBox with height instead of Expanded
          SizedBox(
            height: 400, // Fixed height instead of Expanded
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.folder_open_outlined,
                      size: 60,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'No saved charts yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Charts you create will appear here.\nYou can save, organize, and export your charts.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Create first chart button
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go('/new-chart');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Your First Chart'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Future: When charts exist, show a grid/list here
          // This is a placeholder for the actual saved charts grid
          // Container(
          //   child: GridView.builder(
          //     shrinkWrap: true,
          //     physics: const NeverScrollableScrollPhysics(),
          //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          //       crossAxisCount: 2,
          //       childAspectRatio: 1.2,
          //       crossAxisSpacing: 16,
          //       mainAxisSpacing: 16,
          //     ),
          //     itemCount: 0, // Will be replaced with actual chart count
          //     itemBuilder: (context, index) {
          //       return Card(
          //         child: InkWell(
          //           onTap: () {
          //             // Open chart details/view
          //           },
          //           child: Padding(
          //             padding: const EdgeInsets.all(12.0),
          //             child: Column(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 // Chart preview thumbnail
          //                 Container(
          //                   height: 80,
          //                   width: double.infinity,
          //                   decoration: BoxDecoration(
          //                     color: Theme.of(context).colorScheme.surfaceVariant,
          //                     borderRadius: BorderRadius.circular(8),
          //                   ),
          //                   child: const Icon(Icons.donut_large),
          //                 ),
          //                 const SizedBox(height: 8),
          //                 // Chart title
          //                 Text(
          //                   'Chart Name',
          //                   style: Theme.of(context).textTheme.titleSmall,
          //                   maxLines: 1,
          //                   overflow: TextOverflow.ellipsis,
          //                 ),
          //                 // Chart date
          //                 Text(
          //                   'Date Created',
          //                   style: Theme.of(context).textTheme.bodySmall,
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ),
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}