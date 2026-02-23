import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  int _maxMembers = 12;
  int _privacyIndex = 0;
  bool _online = true;
  bool _inPerson = true;

  final List<String> _privacy = ['🔓 Open', '🔒 Request to Join', '🔑 Invite Only'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.brand),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Post', style: TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text('Set up your study group and invite peers to join 🎓',
                  style: TextStyle(fontSize: 13, color: AppColors.text2)),
            ),

            FormFieldCard(label: 'Group Name', isActive: true, child: const Text('MATH201 Study Squad',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text))),

            FormFieldCard(label: 'Course Code', child: const Text('MATH 201 – Calculus II',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text))),

            FormFieldCard(label: 'Description', child: const Text(
              'Focused exam prep group for MATH201 students. We work through past papers, share notes and help each other understand difficult concepts.',
              style: TextStyle(fontSize: 13, color: AppColors.text, height: 1.5),
            )),

            // Max members + meeting mode row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MAX MEMBERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 0.8)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() { if (_maxMembers > 2) _maxMembers--; }),
                                child: Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(color: AppColors.brandPale, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.remove, size: 16, color: AppColors.brand),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('$_maxMembers', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _maxMembers++),
                                child: Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MEETING MODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 0.8)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6, runSpacing: 6,
                            children: [
                              _ModeChip(label: 'In-person', active: _inPerson, onTap: () => setState(() => _inPerson = !_inPerson)),
                              _ModeChip(label: 'Online', active: _online, onTap: () => setState(() => _online = !_online)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Meeting schedule
            FormFieldCard(
              label: 'Meeting Schedule',
              child: Column(
                children: [
                  _ScheduleRow(day: '📅 Tuesday', time: '4:00 PM – 6:00 PM'),
                  const SizedBox(height: 8),
                  _ScheduleRow(day: '📅 Thursday', time: '4:00 PM – 6:00 PM'),
                  const SizedBox(height: 8),
                  const Text('+ Add another time slot', style: TextStyle(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Location
            FormFieldCard(
              label: 'Location',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📍 University Library – Room 3', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text)),
                  const SizedBox(height: 6),
                  const Text('📎 Pin on map', style: TextStyle(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Privacy
            FormFieldCard(
              label: 'Group Privacy',
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: List.generate(_privacy.length, (i) {
                  final active = i == _privacyIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _privacyIndex = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppColors.brand : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppColors.brand : AppColors.border, width: 1.5),
                      ),
                      child: Text(
                        _privacy[i],
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.text2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 8),
            SBPrimaryButton(label: '🚀 Create Group', onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ModeChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.brand : AppColors.border, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.text2)),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String day;
  final String time;
  const _ScheduleRow({required this.day, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
        Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand)),
      ],
    );
  }
}
