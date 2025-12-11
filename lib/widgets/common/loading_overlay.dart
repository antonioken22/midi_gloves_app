import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/loading_provider.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  const LoadingOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Consumer<LoadingProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Material(
                color: Colors.black45, // Semi-transparent background
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }
}
