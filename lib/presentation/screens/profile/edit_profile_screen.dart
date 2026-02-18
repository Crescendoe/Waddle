import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/domain/entities/user_entity.dart';
import 'package:waddle/presentation/blocs/auth/auth_cubit.dart';
import 'package:waddle/presentation/blocs/auth/auth_state.dart';
import 'package:waddle/presentation/widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isPublic = true;
  bool _saving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final user = authState is Authenticated ? authState.user : null;

    _usernameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _isPublic = user?.isPublicProfile ?? true;

    _usernameController.addListener(_onChanged);
    _bioController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is Authenticated ? authState.user : null;

        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text('Edit Profile', style: AppTextStyles.headlineSmall),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (_hasChanges || _saving)
                  TextButton(
                    onPressed: _saving ? null : () => _save(context, user),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save',
                            style: AppTextStyles.labelLarge.copyWith(
                              fontSize: 15,
                            ),
                          ),
                  ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Photo
                    _buildPhotoSection(user),
                    const SizedBox(height: 28),
                    // Username
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person_rounded,
                      maxLength: 25,
                    ),
                    const SizedBox(height: 16),
                    // Bio
                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      icon: Icons.edit_note_rounded,
                      maxLength: 120,
                      maxLines: 3,
                      hint: 'Tell others about your hydration journey...',
                    ),
                    const SizedBox(height: 24),
                    // Privacy toggle
                    _buildPrivacyToggle(),
                    const SizedBox(height: 16),
                    // Info text
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.textHint),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Public profiles can be found by other users '
                              'and receive friend requests.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Photo Section ──────────────────────────────────────────
  Widget _buildPhotoSection(UserEntity? user) {
    return Center(
      child: GestureDetector(
        onTap: () => _showImagePicker(context),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: _resolveImage(user?.profileImageUrl),
              child: _resolveImage(user?.profileImageUrl) == null
                  ? MascotImage(
                      assetPath: AppConstants.mascotWave,
                      size: 72,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Text Field ─────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLength = 50,
    int maxLines = 1,
    String? hint,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.primary, size: 22),
          labelText: label,
          labelStyle:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          hintText: hint,
          hintStyle:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterStyle: AppTextStyles.bodySmall.copyWith(fontSize: 10),
          fillColor: Colors.transparent,
          filled: true,
        ),
      ),
    );
  }

  // ── Privacy Toggle ─────────────────────────────────────────
  Widget _buildPrivacyToggle() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            _isPublic ? Icons.public_rounded : Icons.lock_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public Profile',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  _isPublic
                      ? 'Anyone can find you and send friend requests'
                      : 'Only you can see your profile',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isPublic,
            onChanged: (val) {
              setState(() {
                _isPublic = val;
                _hasChanges = true;
              });
            },
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ── Save ───────────────────────────────────────────────────
  Future<void> _save(BuildContext context, UserEntity? user) async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);

    await context.read<AuthCubit>().updateProfile(
          username: username,
          bio: _bioController.text.trim(),
          isPublicProfile: _isPublic,
        );

    if (mounted) {
      setState(() {
        _saving = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  // ── Image Picker ───────────────────────────────────────────
  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Change Profile Photo', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primary),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text('Remove Photo'),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthCubit>().updateProfile(profileImageUrl: '');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 70,
      );
      if (picked == null) return;

      final bytes = await File(picked.path).readAsBytes();
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';

      if (mounted) {
        context.read<AuthCubit>().updateProfile(profileImageUrl: dataUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  ImageProvider? _resolveImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }
}
