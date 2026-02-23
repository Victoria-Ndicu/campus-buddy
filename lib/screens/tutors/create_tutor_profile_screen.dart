import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class CreateTutorProfileScreen extends StatefulWidget {
  const CreateTutorProfileScreen({super.key});

  @override
  State<CreateTutorProfileScreen> createState() => _CreateTutorProfileScreenState();
}

class _CreateTutorProfileScreenState extends State<CreateTutorProfileScreen> {
  final Set<String> _selectedSubjects = {'Calculus', 'Statistics'};
  double _rate = 25;
  bool _onlineMode = true;
  bool _inPersonMode = true;
  final Set<int> _availableDays = {1, 2, 4, 5}; // Tue, Wed, Fri, Sat

  final List<String> _subjects = ['Calculus', 'Statistics', 'Physics', 'Chemistry', 'Economics', 'CS', 'Linear Algebra', 'Probability'];
  final List<String> _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _daysFull = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.brand),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Become a Tutor'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: Text('Step 2/4', style: TextStyle(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w600))),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.5,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                  minHeight: 5,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Expertise', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 4),
                  const Text('Tell students what you can help them with', style: TextStyle(fontSize: 12, color: AppColors.text2)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subjects
            FormFieldCard(
              label: 'Subjects (select all that apply)',
              isActive: true,
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: [
                  ..._subjects.map((s) {
                    final selected = _selectedSubjects.contains(s);
                    return GestureDetector(
                      onTap: () => setState(() => selected ? _selectedSubjects.remove(s) : _selectedSubjects.add(s)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.brand : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? AppColors.brand : AppColors.border, width: 1.5),
                        ),
                        child: Text(
                          selected ? '$s ✓' : s,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.text2),
                        ),
                      ),
                    );
                  }),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 1.5, style: BorderStyle.solid),
                    ),
                    child: const Text('+ Add Custom', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text2)),
                  ),
                ],
              ),
            ),

            // Rate and session mode
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  // Rate slider
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
                          const Text('HOURLY RATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 0.8)),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(text: '\$${_rate.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.brand)),
                                const TextSpan(text: ' /hr', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                              ],
                            ),
                          ),
                          Slider(
                            value: _rate, min: 5, max: 100,
                            activeColor: AppColors.brand,
                            inactiveColor: AppColors.border,
                            onChanged: (v) => setState(() => _rate = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Session mode
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SESSION MODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.text3, letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => setState(() => _onlineMode = !_onlineMode),
                          child: Row(
                            children: [
                              Container(
                                width: 16, height: 16,
                                decoration: BoxDecoration(color: _onlineMode ? AppColors.brand : AppColors.border, borderRadius: BorderRadius.circular(4)),
                                child: _onlineMode ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 6),
                              const Text('Online', style: TextStyle(fontSize: 12, color: AppColors.text)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => setState(() => _inPersonMode = !_inPersonMode),
                          child: Row(
                            children: [
                              Container(
                                width: 16, height: 16,
                                decoration: BoxDecoration(color: _inPersonMode ? AppColors.brand : AppColors.border, borderRadius: BorderRadius.circular(4)),
                                child: _inPersonMode ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 6),
                              const Text('In-person', style: TextStyle(fontSize: 12, color: AppColors.text)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Qualifications
            FormFieldCard(
              label: 'Qualifications',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BSc Mathematics, University of Nairobi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.text)),
                  const SizedBox(height: 8),
                  const Text('+ Add another qualification', style: TextStyle(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // Weekly Availability
            FormFieldCard(
              label: 'Weekly Availability',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final avail = _availableDays.contains(i);
                  return GestureDetector(
                    onTap: () => setState(() => avail ? _availableDays.remove(i) : _availableDays.add(i)),
                    child: Column(
                      children: [
                        Text(_days[i], style: TextStyle(fontSize: 10, color: avail ? AppColors.brand : AppColors.text3)),
                        const SizedBox(height: 4),
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: avail ? AppColors.brand : AppColors.surface3,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(avail ? '✓' : '–', style: TextStyle(fontSize: 11, color: avail ? Colors.white : AppColors.text3, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 8),
            SBPrimaryButton(label: 'Continue →', onTap: () => Navigator.pop(context)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
