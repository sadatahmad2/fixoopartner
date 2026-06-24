import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fixoo_partner/services/supabase_service.dart';
import 'package:fixoo_partner/providers/partner_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class EditSkillsScreen extends StatefulWidget {
  final List<String> initialSkills;
  const EditSkillsScreen({super.key, required this.initialSkills});

  @override
  State<EditSkillsScreen> createState() => _EditSkillsScreenState();
}

class _EditSkillsScreenState extends State<EditSkillsScreen> {
  bool _isLoading = false;
  late Set<String> _selectedSkills;

  // Fixed list of skills for the marketplace
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

  @override
  void initState() {
    super.initState();
    _selectedSkills = Set.from(widget.initialSkills);
  }

  Future<void> _saveSkills() async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.updateSkills(_selectedSkills.toList());
      if (mounted) {
        // Refresh global state
        await Provider.of<PartnerProvider>(context, listen: false).fetchStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skills updated successfully!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update skills: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Skills', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: _glow(const Color(0xFF7B61FF), 0.03, 300)),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Select the services you provide. Customers will see your profile based on these skills.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _availableSkills.length,
                  itemBuilder: (context, index) {
                    final skill = _availableSkills[index];
                    final isSelected = _selectedSkills.contains(skill['name']);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedSkills.remove(skill['name']);
                          } else {
                            _selectedSkills.add(skill['name']);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00D1FF).withOpacity(0.1) : Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF00D1FF).withOpacity(0.5) : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF00D1FF).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(skill['icon'], color: isSelected ? const Color(0xFF00D1FF) : Colors.white54, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                skill['name'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFF00D1FF)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: GestureDetector(
                  onTap: _isLoading ? null : _saveSkills,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00D1FF), Color(0xFF7B61FF)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF00D1FF).withOpacity(0.2), blurRadius: 20)],
                    ),
                    child: Center(
                      child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('SAVE SKILLS', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double opacity, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(opacity)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox.expand()),
    );
  }
}
