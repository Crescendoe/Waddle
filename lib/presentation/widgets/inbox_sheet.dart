import 'package:flutter/material.dart';
import 'package:waddle/core/di/injection.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/inbox_service.dart';
import 'package:waddle/presentation/widgets/common.dart';

/// Opens the inbox bottom sheet. Call this from the bell icon tap.
Future<void> showInboxSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _InboxSheet(),
  );
}

class _InboxSheet extends StatefulWidget {
  const _InboxSheet();

  @override
  State<_InboxSheet> createState() => _InboxSheetState();
}

class _InboxSheetState extends State<_InboxSheet> {
  late final InboxService _inbox;
  late List<InboxMessage> _messages;

  @override
  void initState() {
    super.initState();
    _inbox = getIt<InboxService>();
    _messages = _inbox.getAll();
  }

  void _refresh() {
    setState(() => _messages = _inbox.getAll());
  }

  Future<void> _markAllRead() async {
    await _inbox.markAllRead();
    _refresh();
  }

  Future<void> _markRead(InboxMessage msg) async {
    if (!msg.isRead) {
      await _inbox.markRead(msg.id);
      _refresh();
    }
  }

  Future<void> _delete(String id) async {
    await _inbox.deleteMessage(id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final tc = ActiveThemeColors.of(context);
    final unreadCount = _messages.where((m) => !m.isRead).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.inbox_rounded, size: 22, color: tc.primary),
                const SizedBox(width: 8),
                Text(
                  'Inbox',
                  style: AppTextStyles.headlineSmall,
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: tc.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount new',
                      style: TextStyle(
                        color: tc.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: _markAllRead,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      'Mark all read',
                      style: TextStyle(
                        color: tc.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Divider
          Divider(
            height: 1,
            color: AppColors.textHint.withValues(alpha: 0.12),
          ),

          // Messages list
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_email_read_rounded,
                    size: 48,
                    color: AppColors.textHint.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All caught up!',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New messages will show up here.',
                    style: TextStyle(
                      color: AppColors.textHint.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shrinkWrap: true,
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _InboxMessageTile(
                    message: msg,
                    onTap: () => _markRead(msg),
                    onDismissed: () => _delete(msg.id),
                  );
                },
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// ── Individual message tile ──────────────────────────────────────────
class _InboxMessageTile extends StatelessWidget {
  final InboxMessage message;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _InboxMessageTile({
    required this.message,
    required this.onTap,
    required this.onDismissed,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = message.type.color;
    final isUnread = !message.isRead;

    return Dismissible(
      key: ValueKey(message.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isUnread
                ? typeColor.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: isUnread ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  message.type.icon,
                  size: 18,
                  color: typeColor.withValues(alpha: isUnread ? 1 : 0.5),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.title,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                              color: isUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread
                            ? AppColors.textSecondary
                            : AppColors.textHint,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
