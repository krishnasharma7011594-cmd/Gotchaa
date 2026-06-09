import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/screens/main_shell.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      leading: const BackButton(color: Colors.black),
      elevation: 0,
      backgroundColor: Colors.white,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete your Profile',
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tell the world who you are. You can always change this later.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),

            // Profile Photo
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Inputs
            _buildLabel('Username'),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: 'e.g. alex_gotcha',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixText: '@ ',
                prefixStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel('Bio'),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write something interesting about yourself...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Karma Welcome
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.electricGradientDark,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Gift!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'You\'ve earned 500 Karma Points for joining Gotchaa.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '🔥 500',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainShell()),
                  (route) => false,
                );
              },
              child: const Text('Start Explorig Gotchaa'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black87,
      ),
    ),
  );
}
