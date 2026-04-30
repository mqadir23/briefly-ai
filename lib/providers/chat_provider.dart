import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/summary.dart';
import '../services/api_service.dart';
import 'history_provider.dart';
import 'preferences_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;
  ChatNotifier(this._ref) : super([]);

  // Send any input type to the API and stream the result back as a chat message
  Future<void> send({
    required String content,
    required InputType inputType,
  }) async {
    final userMsg = ChatMessage(
      id:        DateTime.now().millisecondsSinceEpoch.toString(),
      role:      MessageRole.user,
      content:   content,
      inputType: inputType,
      timestamp: DateTime.now(),
    );
    final loadingMsg = ChatMessage(
      id:        'loading',
      role:      MessageRole.assistant,
      content:   '',
      inputType: InputType.text,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = [...state, userMsg, loadingMsg];

    final prefs   = _ref.read(preferencesProvider);
    final result  = await ApiService.instance.summarise(
      content:   content,
      inputType: inputType.name,
      eli5:      prefs.eli5Mode,
    );

    if (result.isSuccess) {
      final r = result.data!;
      final summary = Summary(
        id:             userMsg.id,
        originalText:   content,
        headline:       r.headline,
        bullets:        r.bullets,
        sourceUrl:      r.sourceUrl,
        sentiment:      r.sentiment,
        sentimentScore: r.sentimentScore,
        createdAt:      DateTime.now(),
        inputType:      inputType.name,
      );
      // Persist to Hive
      await _ref.read(historyProvider.notifier).add(summary);

      final assistantMsg = ChatMessage(
        id:        '${userMsg.id}_resp',
        role:      MessageRole.assistant,
        content:   r.headline,
        inputType: InputType.text,
        timestamp: DateTime.now(),
        summary:   summary,
      );
      state = [
        ...state.where((m) => m.id != 'loading'),
        assistantMsg,
      ];
    } else {
      final errorMsg = ChatMessage(
        id:        '${userMsg.id}_err',
        role:      MessageRole.assistant,
        content:   '',
        inputType: InputType.text,
        timestamp: DateTime.now(),
        error:     result.error,
      );
      state = [
        ...state.where((m) => m.id != 'loading'),
        errorMsg,
      ];
    }
  }

  // Translate an existing summary message in-place
  Future<void> translate({
    required String messageId,
    required String headline,
    required List<String> bullets,
    required String targetLanguage,
  }) async {
    final result = await ApiService.instance.translate(
      headline: headline,
      bullets:  bullets,
      targetLanguage: targetLanguage,
    );
    if (!result.isSuccess) return;
    final r = result.data!;
    state = state.map((m) {
      if (m.id != messageId || m.summary == null) return m;
      final updated = m.summary!.copyWith(
        translatedHeadline: r.translatedHeadline,
        translatedBullets:  r.translatedBullets,
        translatedTo:       targetLanguage,
      );
      return m.copyWith(summary: updated);
    }).toList();
  }

  /// Reverts a translated message back to its original language in-place.
  void revertTranslation(String messageId) {
    state = state.map((m) {
      if (m.id != messageId || m.summary == null) return m;
      return m.copyWith(summary: m.summary!.clearTranslation());
    }).toList();
  }

  void clearChat() => state = [];
}
