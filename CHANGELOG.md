# Changelog

## 0.9.7+9 — March 5, 2026

### Bug Fixes
- **Challenge completion bug** — Challenges no longer falsely show as completed when simply active. `challengeActive[i]` is now only set to `true` upon actual completion, not on start. This also fixes ducks prematurely unlocking for challenge-specific unlock conditions.
- **Android notifications** — Fixed scheduled notifications never appearing:
  - Replaced broken full-color notification icon with `@mipmap/ic_launcher`.
  - Added runtime `USE_EXACT_ALARM` permission request for Android 12+.
  - Added missing `ScheduledNotificationBootReceiver` and `ScheduledNotificationReceiver` to AndroidManifest.
  - Goal-reached and halfway notifications now suppress while the app is in the foreground.
- **Seasonal inbox alerts** — Seasonal pack notifications no longer repeat every day; they are now sent once per pack instead of once per day.
- **Daily quest reward toast** — Claiming a quest now shows actual earned amounts (including duck bonuses, double-XP, etc.) via a `WaddleToast` instead of a generic `SnackBar` with base template values. Completing all daily quests shows the bonus XP and drops separately.

### New Features
- **Home screen active challenge card** — The challenge card at the bottom of the home screen now shows the challenge title, a color-coded progress bar, and days remaining. Tapping it opens a full detail modal with:
  - Hero header with challenge art, ACTIVE badge, progress bar, and day counter.
  - Full description, rules, and health factoids.
  - Off Limits / Allowed Drinks sections.
  - Completion rewards (XP + drops).
  - Give Up button with confirmation dialog.
- **Duck collection cards rework** — Duck cards now display in a 2-column grid with rich detail:
  - Bond level indicator (Lv. X or gold MAX at level 10).
  - AFK bond progress gauge toward next level.
  - Time remaining until next auto-level (or "Place on home to bond" hint).
  - Passive bonus row with icon, label, and current scaled value.
  - Locked ducks show unlock requirement text.

### iOS Setup
- Bumped iOS deployment target to 14.0.
- Created Podfile, configured entitlements for push notifications and IAP.
- Updated AppDelegate for Firebase + APNs integration.
- Added Codemagic CI/CD workflows (release, debug/sideload, Android release).
- Added GitHub Actions backup workflow.
- Configured sideloadable IPA packaging for testing without an Apple Developer account.

---

## 0.9.6+8

Initial tracked version.
