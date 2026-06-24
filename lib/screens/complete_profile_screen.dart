import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'package:fixoo_partner/screens/home_screen.dart';
import 'dart:ui';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _status = {
    'skills': false,
    'video': false,
    'aadhar_front': false,
    'aadhar_back': false,
    'pan': false,
  };

  final List<Map<String, dynamic>> _availableSkills = [
    {'name': 'Plumber', 'icon': LucideIcons.wrench},
    {'name': 'Electrician', 'icon': LucideIcons.zap},
    {'name': 'AC Repair', 'icon': LucideIcons.fan},
    {'name': 'Cleaning', 'icon': LucideIcons.sparkles},
    {'name': 'Carpentry', 'icon': LucideIcons.hammer},
    {'name': 'Painting', 'icon': LucideIcons.paintRoller},
    {'name': 'Pest Control', 'icon': LucideIcons.bug},
    {'name': 'Appliance Repair', 'icon': LucideIcons.washingMachine},
    {'name': 'Fan Repair', 'icon': LucideIcons.wind},
    {'name': 'Water Motor Repair', 'icon': LucideIcons.droplets},
    {'name': 'Water Purifier Repair', 'icon': LucideIcons.droplet},
    {'name': 'TV Repair', 'icon': LucideIcons.tv},
    {'name': 'Fridge Repair', 'icon': LucideIcons.snowflake},
    {'name': 'Washing Machine Repair', 'icon': LucideIcons.refreshCw},
    {'name': 'Laptop Repair', 'icon': LucideIcons.laptop},
    {'name': 'Mobile Repair', 'icon': LucideIcons.smartphone},
    {'name': 'Cooler', 'icon': LucideIcons.wind},
    {'name': 'Light', 'icon': LucideIcons.lightbulb},
  ];

  Set<String> _selectedSkills = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await SupabaseService.getProfileStatus();
      if (mounted) {
        setState(() {
          // Merge with current status to ensure no keys are missing
          _status = {..._status, ...status};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUpload(String type, {bool isVideo = false}) async {
    try {
      XFile? file;
      if (isVideo) {
        file = await _picker.pickVideo(source: ImageSource.gallery);
      } else {
        file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      }

      if (file == null) return;

      setState(() => _isLoading = true);

      if (isVideo) {
        await SupabaseService.uploadWorkVideo(file.path);
      } else {
        // Map UI labels to DB types
        String dbType = type;
        if (type == 'Aadhar Front') dbType = 'Aadhar Front';
        if (type == 'Aadhar Back') dbType = 'Aadhar Back';
        if (type == 'PAN Card') dbType = 'PAN Card';
        
        await SupabaseService.uploadDocument(dbType, file.path);
      }

      await _loadStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$type uploaded successfully!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSkills() async {
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one skill'))
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SupabaseService.updateSkills(_selectedSkills.toList());
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skills saved!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save skills: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _checkAndNavigate() async {
    final isComplete = await SupabaseService.isProfileComplete();
    if (isComplete && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all steps to continue'), backgroundColor: Colors.orange)
      );
    }
  }

  Future<void> _viewDocument(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040C18),
      body: Stack(
        children: [
          // Background Glows
          Positioned(top: -100, right: -50, child: _glow(const Color(0xFF00D1FF), 0.05, 300)),
          Positioned(bottom: -100, left: -50, child: _glow(const Color(0xFF0FF4C6), 0.03, 300)),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepTitle('Step 1: Your Expertise', 'Select the skills you possess'),
                        const SizedBox(height: 16),
                        _buildSkillsGrid(),
                        const SizedBox(height: 12),
                        _buildActionButton('SAVE SKILLS', (_status['skills'] ?? false) ? null : _saveSkills, _status['skills'] ?? false),
                        
                        const SizedBox(height: 40),
                        _buildStepTitle('Step 2: Proof of Work', 'Upload a short video of your recent work'),
                        const SizedBox(height: 16),
                        _buildUploadCard(
                          'Recent Work Video', 
                          LucideIcons.video, 
                          _status['video'] ?? false, 
                          () => _pickAndUpload('Work Video', isVideo: true),
                          viewUrl: _status['video_url'],
                        ),
                        
                        const SizedBox(height: 40),
                        _buildStepTitle('Step 3: Identity Verification', 'Upload your government ID documents'),
                        const SizedBox(height: 16),
                        _buildUploadCard(
                          'Aadhar Front', 
                          LucideIcons.idCard, 
                          _status['aadhar_front'] ?? false, 
                          () => _pickAndUpload('Aadhar Front'),
                          viewUrl: _status['aadhar_front_url'],
                        ),
                        const SizedBox(height: 12),
                        _buildUploadCard(
                          'Aadhar Back', 
                          LucideIcons.idCard, 
                          _status['aadhar_back'] ?? false, 
                          () => _pickAndUpload('Aadhar Back'),
                          viewUrl: _status['aadhar_back_url'],
                        ),
                        const SizedBox(height: 12),
                        _buildUploadCard(
                          'PAN Card', 
                          LucideIcons.contact, 
                          _status['pan'] ?? false, 
                          () => _pickAndUpload('PAN Card'),
                          viewUrl: _status['pan_url'],
                        ),
                        
                        const SizedBox(height: 60),
                        _buildFinalButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D1FF)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete Your Profile',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'We need a few details to verify your account and start sending you jobs.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
      ],
    );
  }

  Widget _buildSkillsGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _availableSkills.map((skill) {
        final isSelected = _selectedSkills.contains(skill['name']);
        return GestureDetector(
          onTap: (_status['skills'] ?? false) ? null : () {
            setState(() {
              if (isSelected) {
                _selectedSkills.remove(skill['name']);
              } else {
                _selectedSkills.add(skill['name']);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF00D1FF).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? const Color(0xFF00D1FF).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(skill['icon'], size: 16, color: isSelected ? const Color(0xFF00D1FF) : Colors.white54),
                const SizedBox(width: 8),
                Text(skill['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUploadCard(String label, IconData icon, bool isDone, VoidCallback onTap, {String? viewUrl}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone ? Colors.green.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDone ? Colors.green.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(isDone ? Icons.check : icon, color: isDone ? Colors.green : const Color(0xFF00D1FF), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                Text(isDone ? 'Uploaded Successfully' : 'Tap to upload', style: TextStyle(color: isDone ? Colors.green.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.3), fontSize: 12)),
              ],
            ),
          ),
          if (isDone)
            TextButton(
              onPressed: () => _viewDocument(viewUrl),
              child: const Text('VIEW', style: TextStyle(color: Color(0xFF00D1FF), fontSize: 12, fontWeight: FontWeight.w900)),
            )
          else
            IconButton(
              onPressed: onTap,
              icon: Icon(LucideIcons.upload, size: 18, color: Colors.white.withValues(alpha: 0.2)),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback? onTap, bool isDone) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDone ? Colors.green.withValues(alpha: 0.1) : const Color(0xFF00D1FF),
          foregroundColor: isDone ? Colors.green : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: Text(isDone ? 'SKILLS SAVED' : label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildFinalButton() {
    final requiredKeys = ['skills', 'video', 'aadhar_front', 'aadhar_back', 'pan'];
    bool allDone = requiredKeys.every((key) => _status[key] == true);
    
    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton(
        onPressed: _checkAndNavigate,
        style: ElevatedButton.styleFrom(
          backgroundColor: allDone ? const Color(0xFF00D1FF) : Colors.white.withValues(alpha: 0.05),
          foregroundColor: allDone ? Colors.black : Colors.white38,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Text('SUBMIT PROFILE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Widget _glow(Color color, double opacity, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox.expand()),
    );
  }
}
