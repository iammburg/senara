import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child:
                          Icon(Icons.person_2, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ilham Ndaru',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ilhamprabowo009@gmail.com',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Buku Terbaca', '23'),
                  _buildStatItem('Dalam Progres', '3'),
                  _buildStatItem('Wishlist', '15'),
                ],
              ),
              const SizedBox(height: 32),
              _buildMenuItem(
                icon: Icons.person_2_outlined,
                title: 'Edit Profil',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.bookmark_border,
                title: 'Wishlist',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.download_outlined,
                title: 'Buku Didownload',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Pengaturan',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Bantuan & Dukungan',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Keluar',
                onTap: () {},
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontFamily: 'Lexend',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.black87,
      ),
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
}
