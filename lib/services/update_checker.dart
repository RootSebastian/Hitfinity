import 'dart:async';
import 'dart:convert';
// `Abi` lives in dart:ffi (NOT dart:io) — this line is what fixes the
// `Undefined name 'Abi'` build error in earlier copies of this file.
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Over-the-air update channel backed by GitHub Releases.
///
/// Flow: you push a tag (e.g. `v1.3.0`) → the release workflow builds the
/// APKs and publishes a GitHub Release → installed apps call
/// [maybeCheckAndPrompt] on launch → users get a skinned "Update available"
/// dialog → one tap downloads the right APK for their CPU and hands it to
/// Android's installer. No uninstall, no repo visit.
///
/// Setup (see the README that shipped with this file):
///   1. Set [repoOwner] + [repoName] below.
///   2. `flutter pub add http package_info_plus open_filex url_launcher
///      path_provider shared_preferences`
///      (the last one is for `hit_settings.dart` from the v2.5 skin —
///      the settings store behind the Settings screen.)
///   3. Add `REQUEST_INSTALL_PACKAGES` (+ `INTERNET` if missing) to
///      android/app/src/main/AndroidManifest.xml.
///   4. Wire one line into your shell (see README).
///
/// The check runs once per app launch, silently no-ops when the user is
/// already on the latest tag, and never throws into your UI.
class UpdateChecker {
  /// Your GitHub user/org — EDIT ME.
  static const String repoOwner = 'RootSebastian';

  /// Your repo name — EDIT ME (no .git, no slashes).
  static const String repoName = 'Hitfinity';

  /// Skips the launch check after the first call this run.
  static bool _checkedThisRun = false;

  static Uri _apiUri() =>
      Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');

  // ────────────────────────────────────────────────────────────── public

  /// Checks for a newer GitHub Release and shows the update dialog if one
  /// exists. Call once from your shell's `initState` (post-frame).
  ///
  /// [force] re-checks even if this run already checked, and surfaces a
  /// "You're up to date" / failure snackbar — use for a manual
  /// "Check for updates" row in settings.
  static Future<void> maybeCheckAndPrompt(BuildContext context,
      {bool force = false}) async {
    if (!force && _checkedThisRun) return;
    _checkedThisRun = true;

    final AppUpdate? update;
    try {
      update = await fetchUpdate();
    } catch (e) {
      debugPrint('[UpdateChecker] check failed: $e');
      if (force && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Update check failed — are you online?')));
      }
      return;
    }

    if (update == null) {
      if (force && context.mounted) {
        final info = await PackageInfo.fromPlatform();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You\'re up to date — v${info.version}')));
      }
      return;
    }

    if (context.mounted) await promptForUpdate(context, update);
  }

  /// Pure check — returns the newer release, or null if up to date / no
  /// releases yet. Throws on network errors (caller decides what to do).
  static Future<AppUpdate?> fetchUpdate() async {
    final info = await PackageInfo.fromPlatform();

    final res = await http.get(_apiUri(), headers: {
      'Accept': 'application/vnd.github+json',
    });
    if (res.statusCode == 404) return null; // no releases published yet
    if (res.statusCode != 200) {
      throw Exception('GitHub API returned ${res.statusCode}');
    }

    final data =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final tag = (data['tag_name'] ?? '').toString();
    if (tag.isEmpty) return null;
    final remote =
        tag.toLowerCase().startsWith('v') ? tag.substring(1) : tag;
    if (!_isNewer(remote, info.version)) return null;

    // Pick the APK that matches this device's CPU (split-per-ABI builds),
    // falling back to a universal build, then to any APK asset.
    final assets = (data['assets'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .where((a) =>
            (a['name'] ?? '').toString().toLowerCase().endsWith('.apk'))
        .toList();

    final want = _abiAssetToken();
    Map<String, dynamic>? pick;
    if (want != null) {
      for (final a in assets) {
        if ((a['name'] ?? '').toString().toLowerCase().contains(want)) {
          pick = a;
          break;
        }
      }
    }
    if (pick == null) {
      for (final a in assets) {
        if ((a['name'] ?? '')
            .toString()
            .toLowerCase()
            .contains('universal')) {
          pick = a;
          break;
        }
      }
    }
    pick ??= assets.isNotEmpty ? assets.first : null;

    return AppUpdate(
      tag: tag,
      version: remote,
      notes: _cleanNotes(data['body'] as String?),
      apkUrl:
          pick == null ? '' : (pick['browser_download_url'] ?? '').toString(),
      pageUrl: (data['html_url'] ?? '').toString(),
      sizeBytes: (pick?['size'] as num?)?.toInt() ?? 0,
    );
  }

  /// The skinned "Update available" dialog.
  static Future<void> promptForUpdate(
      BuildContext context, AppUpdate u) async {
    final scheme = Theme.of(context).colorScheme;
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;

    final canSelfInstall = Platform.isAndroid && u.apkUrl.isNotEmpty;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update_alt_rounded,
                color: scheme.primary, size: 22),
            const SizedBox(width: 10),
            const Text('Update available'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('v${info.version}',
                    style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text('v${u.version}',
                    style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800)),
                if (u.sizeBytes > 0) ...[
                  const Spacer(),
                  Text(_fmtMB(u.sizeBytes),
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 12)),
                ],
              ],
            ),
            if (u.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      u.notes,
                      style: const TextStyle(fontSize: 13, height: 1.45),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (canSelfInstall) {
                downloadAndInstall(context, u);
              } else {
                unawaited(launchUrl(Uri.parse(u.pageUrl),
                    mode: LaunchMode.externalApplication));
              }
            },
            icon: const Icon(Icons.download_rounded),
            label: Text(canSelfInstall ? 'Update now' : 'Get it on GitHub'),
          ),
        ],
      ),
    );
  }

  /// Downloads the APK with a progress dialog, then hands it to the system
  /// installer. The first-ever install asks the user to allow "Install
  /// unknown apps" for Hitfinity — that's Android's rule, not ours.
  static Future<void> downloadAndInstall(
      BuildContext context, AppUpdate u) async {
    final messenger = ScaffoldMessenger.of(context);
    final client = http.Client();
    var cancelled = false;
    var dialogOpen = false;

    final progress = ValueNotifier<double>(-1); // -1 = indeterminate
    final received = ValueNotifier<int>(0);

    void closeDialog() {
      if (dialogOpen && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      dialogOpen = false;
    }

    dialogOpen = true;
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadDialog(
        version: u.version,
        progress: progress,
        received: received,
        totalBytes: u.sizeBytes,
        onCancel: () {
          cancelled = true;
          client.close();
          closeDialog();
        },
      ),
    ));

    try {
      final res = await client.send(http.Request('GET', Uri.parse(u.apkUrl)));
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final total = res.contentLength ?? -1;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/hitfinity_${u.version}.apk');
      final sink = file.openWrite();
      try {
        await for (final chunk in res.stream) {
          sink.add(chunk);
          received.value += chunk.length;
          progress.value =
              total > 0 ? (received.value / total).clamp(0.0, 1.0) : -1;
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      closeDialog();
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        messenger.showSnackBar(SnackBar(
            content:
                Text('Couldn\'t open the installer: ${result.message}')));
      }
    } catch (e) {
      debugPrint('[UpdateChecker] download failed: $e');
      closeDialog();
      if (!cancelled && context.mounted) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Update download failed — try again later.')));
      }
    } finally {
      client.close();
      progress.dispose();
      received.dispose();
    }
  }

  // ─────────────────────────────────────────────────────────── helpers

  /// `1.10.0` vs `1.9.5` → true. Ignores build numbers (`1.3.0+4`).
  static bool _isNewer(String remote, String local) {
    List<int> parts(String v) => v
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp('^v'), '')
        .split('+')
        .first
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    final a = parts(remote);
    final b = parts(local);
    final n = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  /// Which split-per-ABI APK belongs to this device.
  /// NB: `Abi` comes from `dart:ffi` — keep that import at the top.
  static String? _abiAssetToken() {
    final a = Abi.current();
    if (a == Abi.androidArm64) return 'arm64-v8a';
    if (a == Abi.androidArm) return 'armeabi-v7a';
    if (a == Abi.androidX64) return 'x86_64';
    if (a == Abi.androidIA32) return 'x86';
    return null; // desktop / unknown → universal fallback
  }

  /// Strips the worst of GitHub's auto-generated markdown for the dialog.
  static String _cleanNotes(String? body) {
    if (body == null || body.trim().isEmpty) return '';
    var t = body
        .replaceAll(RegExp('<!--.*?-->', dotAll: true), '')
        .replaceAll(RegExp(r'`'), '')
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'[\*_]{1,3}'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
    final lines =
        t.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    t = lines.take(14).join('\n');
    if (t.length > 700) t = '${t.substring(0, 700)}…';
    return t;
  }

  static String _fmtMB(int bytes) =>
      bytes <= 0 ? '' : '${(bytes / 1048576).toStringAsFixed(1)} MB';
}

/// What the dialog consumes; also handy for a "what's new" list.
class AppUpdate {
  const AppUpdate({
    required this.tag,
    required this.version,
    required this.notes,
    required this.apkUrl,
    required this.pageUrl,
    required this.sizeBytes,
  });

  final String tag; // "v1.3.0"
  final String version; // "1.3.0"
  final String notes; // cleaned release body
  final String apkUrl; // direct asset URL ('' if no APK asset)
  final String pageUrl; // human-friendly release page
  final int sizeBytes;
}

/// Progress dialog shown while the APK streams in.
class _DownloadDialog extends StatelessWidget {
  const _DownloadDialog({
    required this.version,
    required this.progress,
    required this.received,
    required this.totalBytes,
    required this.onCancel,
  });

  final String version;
  final ValueNotifier<double> progress; // -1 = indeterminate
  final ValueNotifier<int> received;
  final int totalBytes;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Downloading update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('v$version · keep the app open',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 16),
          ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, p, _) => ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: p < 0 ? null : p,
                backgroundColor: scheme.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: received,
            builder: (context, bytes, _) => Text(
              totalBytes > 0
                  ? '${_mb(bytes)} / ${_mb(totalBytes)} MB'
                  : '${_mb(bytes)} MB',
              style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  static String _mb(int bytes) => (bytes / 1048576).toStringAsFixed(1);
}
