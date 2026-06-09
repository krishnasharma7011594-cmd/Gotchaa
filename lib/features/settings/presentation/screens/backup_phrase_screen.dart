import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/security/recovery_key_service.dart';
import '../../../../core/theme/app_colors.dart';

class BackupPhraseScreen extends StatefulWidget {

  const BackupPhraseScreen({required this.uid, required this.onComplete, super.key});
  final String uid;
  final VoidCallback onComplete;

  @override
  State<BackupPhraseScreen> createState() => _BackupPhraseScreenState();
}

class _BackupPhraseScreenState extends State<BackupPhraseScreen> {
  final RecoveryKeyService _service = RecoveryKeyService();
  String _mnemonic = '';
  List<String> _words = [];
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final m = await _service.generateMnemonic();
    setState(() {
      _mnemonic = m;
      _words = m.split(' ');
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Secure Your Account',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn().slideX(),
              const SizedBox(height: 12),
              Text(
                'Write down these 12 words in order and keep them offline. This is the only way to recover your chats if you lose your phone.',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),
              
              // Mnemonic Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3,
                  ),
                  itemCount: _words.length,
                  itemBuilder: (context, index) => _buildWordTile(index + 1, _words[index]),
                ),
              ),
              
              const Spacer(),
              
              // Confirmation Checkbox
              CheckboxListTile(
                value: _isConfirmed,
                onChanged: (val) => setState(() => _isConfirmed = val ?? false),
                title: Text(
                  'I have written down my recovery phrase and stored it in a safe place.',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.electricBlue,
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isConfirmed ? () async {
                    await _service.deriveIdentityKey(_mnemonic, widget.uid);
                    widget.onComplete();
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Finish Setup',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

  Widget _buildWordTile(int index, String word) => Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '$index.',
            style: GoogleFonts.jetBrainsMono(color: AppColors.electricBlue, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            word,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).scale();
}
