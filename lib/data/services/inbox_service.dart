import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Message type enum ────────────────────────────────────────────────
enum InboxMessageType {
  duckAfkLevelUp,
  duckAfkReady,
  questsRefreshed,
  allQuestsComplete,
  streakMilestone,
  streakTierPromoted,
  challengeProgress,
  seasonalPackAvailable,
  seasonalPackExpiring,
  friendRequest,
  friendAccepted,
  weeklyLeagueResult,
  welcomeBack,
  levelUp,
  goalStreak,
  general,
}

extension InboxMessageTypeX on InboxMessageType {
  IconData get icon {
    switch (this) {
      case InboxMessageType.duckAfkLevelUp:
      case InboxMessageType.duckAfkReady:
        return Icons.pets_rounded;
      case InboxMessageType.questsRefreshed:
        return Icons.assignment_turned_in_rounded;
      case InboxMessageType.allQuestsComplete:
        return Icons.stars_rounded;
      case InboxMessageType.streakMilestone:
      case InboxMessageType.goalStreak:
        return Icons.local_fire_department_rounded;
      case InboxMessageType.streakTierPromoted:
        return Icons.military_tech_rounded;
      case InboxMessageType.challengeProgress:
        return Icons.emoji_events_rounded;
      case InboxMessageType.seasonalPackAvailable:
      case InboxMessageType.seasonalPackExpiring:
        return Icons.card_giftcard_rounded;
      case InboxMessageType.friendRequest:
      case InboxMessageType.friendAccepted:
        return Icons.person_add_rounded;
      case InboxMessageType.weeklyLeagueResult:
        return Icons.leaderboard_rounded;
      case InboxMessageType.welcomeBack:
        return Icons.waving_hand_rounded;
      case InboxMessageType.levelUp:
        return Icons.arrow_upward_rounded;
      case InboxMessageType.general:
        return Icons.mail_rounded;
    }
  }

  Color get color {
    switch (this) {
      case InboxMessageType.duckAfkLevelUp:
      case InboxMessageType.duckAfkReady:
        return const Color(0xFF6CCCD1);
      case InboxMessageType.questsRefreshed:
        return const Color(0xFF36708B);
      case InboxMessageType.allQuestsComplete:
        return const Color(0xFFFFD700);
      case InboxMessageType.streakMilestone:
      case InboxMessageType.goalStreak:
        return const Color(0xFFFF9800);
      case InboxMessageType.streakTierPromoted:
        return const Color(0xFFCD7F32);
      case InboxMessageType.challengeProgress:
        return const Color(0xFF4CAF50);
      case InboxMessageType.seasonalPackAvailable:
      case InboxMessageType.seasonalPackExpiring:
        return const Color(0xFFE91E63);
      case InboxMessageType.friendRequest:
      case InboxMessageType.friendAccepted:
        return const Color(0xFF2196F3);
      case InboxMessageType.weeklyLeagueResult:
        return const Color(0xFF9C27B0);
      case InboxMessageType.welcomeBack:
        return const Color(0xFF4CAF50);
      case InboxMessageType.levelUp:
        return const Color(0xFF36708B);
      case InboxMessageType.general:
        return const Color(0xFF5A6B7C);
    }
  }
}

// ── Message model ────────────────────────────────────────────────────
class InboxMessage {
  final String id;
  final InboxMessageType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? actionRoute;

  const InboxMessage({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
    this.actionRoute,
  });

  InboxMessage copyWith({bool? isRead}) => InboxMessage(
        id: id,
        type: type,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        actionRoute: actionRoute,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'actionRoute': actionRoute,
      };

  factory InboxMessage.fromJson(Map<String, dynamic> json) => InboxMessage(
        id: json['id'] as String,
        type: InboxMessageType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => InboxMessageType.general,
        ),
        title: json['title'] as String,
        body: json['body'] as String,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        actionRoute: json['actionRoute'] as String?,
      );
}

// ── Service ──────────────────────────────────────────────────────────
class InboxService {
  static const _key = 'waddle_inbox_messages';
  static const _maxMessages = 50;

  final SharedPreferences _prefs;

  InboxService({required SharedPreferences prefs}) : _prefs = prefs;

  // ── Read ─────────────────────────────────────────────────────────
  List<InboxMessage> getAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List)
        .map((e) => InboxMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<InboxMessage> getUnread() => getAll().where((m) => !m.isRead).toList();

  int get unreadCount => getUnread().length;

  // ── Write ────────────────────────────────────────────────────────
  Future<void> addMessage(InboxMessage message) async {
    final messages = getAll();
    messages.insert(0, message);
    // Trim to max size
    final trimmed = messages.length > _maxMessages
        ? messages.sublist(0, _maxMessages)
        : messages;
    await _save(trimmed);
  }

  /// Convenience to create + add a message in one call.
  Future<void> add({
    required InboxMessageType type,
    required String title,
    required String body,
    String? actionRoute,
  }) async {
    final msg = InboxMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_${type.name}',
      type: type,
      title: title,
      body: body,
      createdAt: DateTime.now(),
      actionRoute: actionRoute,
    );
    await addMessage(msg);
  }

  Future<void> markRead(String messageId) async {
    final messages = getAll();
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;
    messages[idx] = messages[idx].copyWith(isRead: true);
    await _save(messages);
  }

  Future<void> markAllRead() async {
    final messages = getAll().map((m) => m.copyWith(isRead: true)).toList();
    await _save(messages);
  }

  Future<void> deleteMessage(String messageId) async {
    final messages = getAll();
    messages.removeWhere((m) => m.id == messageId);
    await _save(messages);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_key);
  }

  /// Remove messages older than [days].
  Future<void> clearOld({int days = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final messages = getAll();
    messages.removeWhere((m) => m.createdAt.isBefore(cutoff));
    await _save(messages);
  }

  // ── Internal ─────────────────────────────────────────────────────
  Future<void> _save(List<InboxMessage> messages) async {
    final json = jsonEncode(messages.map((m) => m.toJson()).toList());
    await _prefs.setString(_key, json);
  }
}
