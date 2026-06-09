import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/circle_model.dart';
import '../providers/circles_feed_provider.dart';
import '../providers/circles_onboarding_provider.dart';

class CirclesCreateScreen extends ConsumerStatefulWidget {
  const CirclesCreateScreen({super.key});

  @override
  ConsumerState<CirclesCreateScreen> createState() =>
      _CirclesCreateScreenState();
}

class _CirclesCreateScreenState extends ConsumerState<CirclesCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _tagsController = TextEditingController();

  String _selectedCategory = 'Pickleball';
  final String _selectedCity = 'New Delhi';
  int _memberLimit = 15;
  bool _isPrivate = false;
  bool _isApprovalRequired = false;
  bool _checkingLimits = true;
  bool _canCreate = false;

  final List<String> _categories = [
    'Parties',
    'Pickleball',
    'Gaming',
    'Study Groups',
    'Travelers',
    'Language Exchange',
    'Music',
    'Fitness',
    'Startups',
    'Anime',
    'Photography'
  ];

  @override
  void initState() {
    super.initState();
    _checkUserLimits();
  }

  Future<void> _checkUserLimits() async {
    final service = ref.read(circlesFirestoreServiceProvider);
    final allowed = await service.canCreateCircle();
    setState(() {
      _canCreate = allowed;
      _checkingLimits = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationNameController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final service = ref.read(circlesFirestoreServiceProvider);

    // Exact GPS coordinates are masked/stored in GeoPoint
    final newCircle = CircleModel(
      id: '',
      title: _titleController.text,
      description: _descController.text,
      category: _selectedCategory,
      city: _selectedCity,
      coverImageUrl:
          'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=500', // Default gorgeous meetup cover
      hostId: '',
      eventDate: DateTime.now().add(const Duration(days: 2)),
      memberLimit: _memberLimit,
      locationName: _locationNameController.text,
      locationLatLng: const GeoPoint(
          28.6139, 77.2090), // Connaught Place general coordinates
      ageGroup: 'Any',
      language: 'English',
      isPrivate: _isPrivate,
      isApprovalRequired: _isApprovalRequired,
      memberIds: [],
      isActive: true,
      tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
      createdAt: DateTime.now(),
    );

    try {
      await service.createCircle(newCircle);
      // Refresh feed
      ref.read(circlesFeedProvider.notifier).fetchFeed(refresh: true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                '🎉 Circle created successfully! You gained +20 Host Karma.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLimits) {
      return Scaffold(
        backgroundColor: context.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_canCreate) {
      return Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: context.bg,
          title: Text('Create Circle',
              style: GoogleFonts.outfit(color: Colors.white)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.karmaOrange, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Creation Cap Reached!',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'To prevent spam, Gotchaa restricts users to a maximum of 3 active circles at any given time.',
                  style: GoogleFonts.inter(color: context.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        title: Text('New Circle Vibe',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Circle Title',
                  labelStyle: TextStyle(color: context.textSecondary),
                  filled: true,
                  fillColor: context.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Vibe Description',
                  labelStyle: TextStyle(color: context.textSecondary),
                  filled: true,
                  fillColor: context.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Category selector
              DropdownButtonFormField<String>(
                dropdownColor: context.surface,
                initialValue: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style: const TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: context.textSecondary),
                  filled: true,
                  fillColor: context.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Public Location Name
              TextFormField(
                controller: _locationNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Meetup Location Name (Public Info)',
                  labelStyle: TextStyle(color: context.textSecondary),
                  helperText:
                      'e.g. "Connaught Place Coffee, Delhi". Exact GPS points are hidden from non-members.',
                  helperStyle: TextStyle(color: context.textSecondary),
                  filled: true,
                  fillColor: context.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Location name is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Vibe Tags (Comma Separated)',
                  labelStyle: TextStyle(color: context.textSecondary),
                  hintText: 'e.g. casual, sports, chill',
                  hintStyle: TextStyle(color: context.textSecondary),
                  filled: true,
                  fillColor: context.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Member limit slider
              Text(
                'Member Limit: $_memberLimit people',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: _memberLimit.toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                activeColor: AppColors.electricBlue,
                onChanged: (val) {
                  setState(() => _memberLimit = val.round());
                },
              ),
              const SizedBox(height: 16),

              // Private switch
              SwitchListTile(
                value: _isPrivate,
                onChanged: (val) => setState(() => _isPrivate = val),
                title: Text('Private Circle',
                    style: GoogleFonts.outfit(color: Colors.white)),
                subtitle: Text(
                    'Search engine will hide this circle from public discover feeds.',
                    style: GoogleFonts.inter(
                        color: context.textSecondary, fontSize: 11)),
                activeThumbColor: AppColors.electricBlue,
              ),

              // Approval required switch
              SwitchListTile(
                value: _isApprovalRequired,
                onChanged: (val) => setState(() => _isApprovalRequired = val),
                title: Text('Require host approval to join',
                    style: GoogleFonts.outfit(color: Colors.white)),
                subtitle: Text(
                    'New applicants must be accepted by you to view precise coordinates.',
                    style: GoogleFonts.inter(
                        color: context.textSecondary, fontSize: 11)),
                activeThumbColor: AppColors.electricBlue,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Launch Circle',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
