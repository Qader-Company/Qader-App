import 'package:flutter/material.dart';

/// A local fallback for missing or unavailable profile photos.
class AvatarPlaceholder extends StatelessWidget {
  const AvatarPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipOval(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0FAFF), Color(0xFFD6ECF8)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest.shortestSide;
              return Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Container(
                      width: size * 0.78,
                      height: size * 0.78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70),
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: size * 0.66,
                      color: const Color(0xFF5386A4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
