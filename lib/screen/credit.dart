import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../model/department.dart';
import '../model/widgets.dart';

final scholoarshipProvider = StateProvider<String>((ref) => 'Default');
final Map<String, int> items = {'BoT': 1750, 'VMSP': 1400, 'Default': 2200};

final discountProvider = StateProvider<bool>((ref) => false);

class CreditCalculation extends ConsumerStatefulWidget {
  const CreditCalculation({super.key});

  @override
  ConsumerState<CreditCalculation> createState() => _CreditCalculationState();
}

class _CreditCalculationState extends ConsumerState<CreditCalculation> {
  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar(context, "Credit & Cost"),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // Top controls (Scholarship & Department)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scholarship',
                            style: GoogleFonts.inter(color: isDark(context) ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Consumer(
                            builder: (context, ref, child) {
                              return RoundedField(
                                child: DropdownField(
                                  ProviderName: scholoarshipProvider,
                                  item: items.keys.toList(),
                                ),
                              );
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Department',
                            style: GoogleFonts.inter(color: isDark(context) ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Consumer(
                            builder: (context, ref, child) {
                              return RoundedField(
                                child: DropdownField(
                                  ProviderName: departmentProvider,
                                  item: department.keys.toList(),
                                  hintText: "Select Dept",
                                  onChangeExtra: (ref, newValue) {
                                    ref.watch(subjectProvider.notifier).state = [];
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Subject Search
                if (ref.watch(departmentProvider) != null)
                  Consumer(
                    builder: (context, ref, child) {
                      return RoundedField(
                        child: SubjectAutoComplete(
                          departmentProvider: departmentProvider,
                          departmentMap: department,
                          subjectProvider: subjectProvider,
                          fieldDecoration: fieldDecoration,
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
                    },
                  ),
                  
                const SizedBox(height: 16),
                
                // Selected Subjects List
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final selected = ref.watch(subjectProvider);
                      
                      if (selected.isEmpty && ref.watch(departmentProvider) != null) {
                         return Center(
                           child: Text(
                             "Search and add subjects above",
                             style: GoogleFonts.inter(color: Colors.black45, fontStyle: FontStyle.italic),
                           ).animate().fadeIn(delay: 300.ms),
                         );
                      }
                      
                      return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: selected.length,
                        itemBuilder: (context, index) {
                          final subject = selected[index];
                          return _subjectTile(subject, ref).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2);
                        },
                      );
                    },
                  ),
                ),
                
                // Cost Summary Card (Receipt style)
                Consumer(
                  builder: (context, ref, child) {
                    final selected = ref.watch(subjectProvider);
                    if (selected.isEmpty) return const SizedBox.shrink();
                    
                    final totalCredit = selected.fold<double>(0, (prev, subject) => prev + subject.Credit);
                    final rate = items[ref.watch(scholoarshipProvider)] ?? 0;
                    double totalCost = rate * totalCredit;
                    final hasDiscount = ref.watch(discountProvider);
                    
                    if (hasDiscount) {
                      totalCost *= 0.95;
                    }
                    
                    return GlassContainer(
                      margin: const EdgeInsets.only(bottom: 20, top: 10),
                      padding: const EdgeInsets.all(20),
                      borderColor: primaryColor.withValues(alpha: 0.3),
                      child: Column(
                        children: [
                          _infoRow(context, 'Total Credits', totalCredit.toStringAsFixed(1), false),
                          const Divider(height: 16, color: Colors.black12),
                          _infoRow(context, 'Rate per Credit', '৳${rate.toStringAsFixed(0)}', false),
                          const Divider(height: 16, color: Colors.black12),
                          
                          // Discount Toggle
                          GestureDetector(
                            onTap: () {
                              ref.read(discountProvider.notifier).state = !ref.read(discountProvider);
                            },
                            child: Row(
                              children: [
                                Checkbox(
                                  value: ref.watch(discountProvider),
                                  onChanged: (value) {
                                    ref.read(discountProvider.notifier).state = value ?? false;
                                  },
                                  activeColor: secondaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                Text(
                                  'Apply 5% Sibling/Spouse Discount',
                                  style: GoogleFonts.inter(color: isDark(context) ? Colors.white : Colors.black87, fontWeight: FontWeight.w500, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Final Cost
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Cost',
                                  style: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                Text(
                                  '৳${totalCost.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 22),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _subjectTile(Subject subject, WidgetRef ref) => GlassContainer(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            subject.Code,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.Title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(color: isDark(context) ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                'Cr: ${subject.Credit}',
                style: GoogleFonts.inter(color: isDark(context) ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w500, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            final update = ref.read(subjectProvider.notifier).state..remove(subject);
            ref.read(subjectProvider.notifier).state = [...update];
          },
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
        ),
      ],
    ),
  );

  Widget _infoRow(BuildContext context, String label, String value, bool isBold) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          color: isDark(context) ? Colors.white : Colors.black87,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      Text(
        value,
        style: GoogleFonts.inter(
          color: isDark(context) ? Colors.white : Colors.black87,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ],
  );
}
