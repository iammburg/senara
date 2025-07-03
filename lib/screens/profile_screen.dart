import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
          stream: _authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = snapshot.data;
            if (user != null) {
              // User is signed in
              return _buildSignedInProfile();
            } else {
              // User is not signed in
              return _buildSignInScreen();
            }
          },
        ),
      ),
    );
  }

  Widget _buildSignedInProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  backgroundImage: _authService.userPhotoURL != null
                      ? NetworkImage(_authService.userPhotoURL!)
                      : null,
                  child: _authService.userPhotoURL == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _authService.userDisplayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _authService.userEmail ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Edit Profil',
            onTap: () {
              // TODO: Implement edit profile
            },
          ),
          _buildMenuItem(
            icon: Icons.history,
            title: 'Riwayat Scan',
            onTap: () {
              // TODO: Navigate to history
            },
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Pengaturan',
            onTap: () {
              // TODO: Implement settings
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Bantuan & Dukungan',
            onTap: () {
              // TODO: Implement help
            },
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Keluar',
            onTap: _signOut,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSignInScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sign_language, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          const Text(
            'Selamat Datang di Senara',
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'Lexend',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aplikasi penerjemah bahasa isyarat SIBI.\nSilakan masuk untuk menyimpan riwayat scan Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Inter',
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'Masuk dengan Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Show info about why login is needed
              _showLoginInfoDialog();
            },
            child: Text(
              'Mengapa perlu login?',
              style: TextStyle(color: Colors.grey[600], fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontSize: 16,
          fontFamily: 'Inter',
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        // User canceled sign-in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('LoginDibatalkan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Sign-in successful
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil masuk!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Gagal masuk';

        // More specific error messages
        if (e.toString().contains('sign_in_failed')) {
          errorMessage =
              'Google Sign-In gagal. Pastikan SHA-1 fingerprint sudah ditambahkan ke Firebase Console.';
        } else if (e.toString().contains('network_error')) {
          errorMessage = 'Tidak ada koneksi internet';
        } else if (e.toString().contains('sign_in_cancelled')) {
          errorMessage = 'Login dibatalkan';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Berhasil keluar')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal keluar: $e')));
    }
  }

  void _showLoginInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Mengapa perlu login?',
          style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Dengan login, Anda dapat:\n\n'
          '• Menyimpan riwayat hasil scan bahasa isyarat\n'
          '• Mengakses data dari berbagai perangkat\n'
          '• Membackup session scan Anda\n\n'
          'Data Anda akan tersimpan dengan aman di cloud.',
          style: TextStyle(fontFamily: 'Inter', color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}
