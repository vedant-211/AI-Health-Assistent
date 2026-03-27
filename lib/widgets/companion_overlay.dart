import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../providers/companion_provider.dart';
import '../theme/app_styles.dart';

class GlobalCompanionOverlay extends ConsumerWidget {
  const GlobalCompanionOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionProvider);

    final companionAnim = 'assets/lottie/companion_breathe.json';

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      bottom: state.isVisible ? 120 : -150, // Float slightly above bottom nav
      right: 20,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: state.isVisible ? 1.0 : 0.0,
        child: Material(
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Chat Bubble
              if (state.message.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxWidth: 220),
                  margin: const EdgeInsets.only(bottom: 24, right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppStyles.bgSurface.withOpacity(0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(4),
                    ),
                    border: AppStyles.glassBorder,
                    boxShadow: AppStyles.glowShadow, // Moonly glow
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Text(
                        state.message,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 13, 
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),

              // Companion Avatar
              GestureDetector(
                onTap: () => ref.read(companionProvider.notifier).hide(),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppStyles.primaryBlue.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Lottie.asset(
                      companionAnim,
                      fit: BoxFit.cover,
                      animate: state.emotion != CompanionEmotion.error,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppStyles.primaryGradient,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
