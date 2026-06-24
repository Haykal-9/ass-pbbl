import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/app_locale.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_snackbar.dart';
import 'auth_gate.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onPrefsChanged;

  const ProfileScreen({super.key, this.onPrefsChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = DatabaseHelper();
  final _prefs = PreferencesService();
  final _session = SessionService();

  AppUser? _user;
  bool _loading = true;
  String _bahasa = 'ID';
  String _mataUang = 'IDR';
  String _sortBy = 'terbaru';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await _session.getCurrentUserId();
    final user = userId == null ? null : await _db.getAppUserById(userId);
    final allPrefs = await _prefs.loadAllPrefs();
    if (!mounted) return;
    setState(() {
      _user = user;
      _bahasa = allPrefs['bahasa'] as String;
      _mataUang = allPrefs['mata_uang'] as String;
      _sortBy = allPrefs['sort_by'] as String;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await _session.clearCurrentUserId();
    if (!mounted) return;
    showSuccessSnackbar(context, 'Berhasil keluar');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  Future<String?> _pickAvatarImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return null;

    if (kIsWeb) {
      return picked.path;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'photos'));
    await photosDir.create(recursive: true);
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = p.join(photosDir.path, fileName);
    await File(picked.path).copy(destPath);
    return destPath;
  }

  Future<void> _editProfile() async {
    if (_user == null) return;

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: _user!.displayName);
    final usernameCtrl = TextEditingController(text: _user!.username);
    final bioCtrl = TextEditingController(text: _user!.bio);
    String? avatarPath = _user!.avatarPath;
    bool saving = false;

    Future<void> saveSheet(StateSetter setSheetState) async {
      if (!(formKey.currentState?.validate() ?? false)) return;

      final displayName = nameCtrl.text.trim();
      final username = usernameCtrl.text.trim().toLowerCase();
      final bio = bioCtrl.text.trim();

      setSheetState(() => saving = true);

      final existing = await _db.getAppUserByUsername(username);
      if (!mounted) return;
      if (existing != null && existing.id != _user!.id) {
        setSheetState(() => saving = false);
        showErrorSnackbar(context, 'Username sudah dipakai');
        return;
      }

      final updatedUser = _user!.copyWith(
        displayName: displayName,
        username: username,
        bio: bio,
        avatarPath: avatarPath,
      );

      await _db.updateAppUser(updatedUser);
      if (!mounted) return;

      setState(() {
        _user = updatedUser;
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnackbar(context, 'Profil berhasil diperbarui');
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final hasAvatar = avatarPath != null && avatarPath!.isNotEmpty && !kIsWeb && File(avatarPath!).existsSync();

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottomInset),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ubah Profil',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                              backgroundImage: hasAvatar ? FileImage(File(avatarPath!)) : null,
                              child: !hasAvatar ? Icon(Icons.person, size: 40, color: colorScheme.primary) : null,
                            ),
                            Material(
                              color: colorScheme.primary,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 18),
                                color: colorScheme.onPrimary,
                                tooltip: 'Ubah foto profil',
                                onPressed: () async {
                                  final pickedPath = await _pickAvatarImage();
                                  if (pickedPath == null || !mounted) return;
                                  setSheetState(() {
                                    avatarPath = pickedPath;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama lengkap',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Username wajib diisi';
                          if (text.length < 3) return 'Username minimal 3 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: bioCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: saving ? null : () => saveSheet(setSheetState),
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(saving ? 'Menyimpan...' : 'Simpan Perubahan'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: saving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    usernameCtrl.dispose();
    bioCtrl.dispose();
  }

  Future<void> _confirmLogout() async {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.logout_rounded, color: colorScheme.error, size: 36),
        title: const Text('Yakin ingin keluar?'),
        content: const Text(
          'Kamu akan keluar dari akun ini. '
          'Pastikan semua data sudah tersimpan sebelum keluar.',
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _profileCard(),
          ),
          const SizedBox(height: 12),
          SettingsScreen(
            onPrefsChanged: widget.onPrefsChanged,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
          // Tombol logout di paling bawah halaman (scrollable)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _confirmLogout,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarPath = _user?.avatarPath;
    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty && !kIsWeb && File(avatarPath).existsSync();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _editProfile,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar dengan overlay kamera
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                    backgroundImage: hasAvatar ? FileImage(File(avatarPath!)) : null,
                    child: !hasAvatar
                        ? Icon(Icons.person, size: 36, color: colorScheme.primary)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).cardColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user?.displayName ?? 'WanderList User',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${_user?.username ?? 'wanderlist'}',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (_user?.bio != null && _user!.bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _user!.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Ketuk untuk mengubah profil',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

}