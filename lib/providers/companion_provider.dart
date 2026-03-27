import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CompanionEmotion { neutral, happy, thinking, worried, error }

class CompanionState {
  final bool isVisible;
  final String message;
  final CompanionEmotion emotion;

  CompanionState({
    required this.isVisible,
    required this.message,
    required this.emotion,
  });

  CompanionState copyWith({
    bool? isVisible,
    String? message,
    CompanionEmotion? emotion,
  }) {
    return CompanionState(
      isVisible: isVisible ?? this.isVisible,
      message: message ?? this.message,
      emotion: emotion ?? this.emotion,
    );
  }
}

class CompanionNotifier extends StateNotifier<CompanionState> {
  Timer? _hideTimer;
  bool _disposed = false;

  CompanionNotifier()
      : super(CompanionState(
          isVisible: true,
          message: "Hi, I'm here for you.",
          emotion: CompanionEmotion.happy,
        )) {
    _startTimer(const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _disposed = true;
    _hideTimer?.cancel();
    super.dispose();
  }

  void show({required String message, CompanionEmotion emotion = CompanionEmotion.neutral, Duration? autoHide, bool forcePersist = false}) {
    _hideTimer?.cancel();
    state = state.copyWith(isVisible: true, message: message, emotion: emotion);

    if (autoHide != null) {
      _startTimer(autoHide);
    } else if (!forcePersist) {
      _startTimer(const Duration(seconds: 4));
    }
  }

  void hide() {
    _hideTimer?.cancel();
    state = state.copyWith(isVisible: false);
  }

  void _startTimer(Duration duration) {
    _hideTimer?.cancel();
    _hideTimer = Timer(duration, () {
      if (_disposed) return;
      hide();
    });
  }
}

final companionProvider = StateNotifierProvider<CompanionNotifier, CompanionState>((ref) {
  return CompanionNotifier();
});
