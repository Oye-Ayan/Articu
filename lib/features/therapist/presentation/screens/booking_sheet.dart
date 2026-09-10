import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/therapist_model.dart';
import '../cubit/therapist_cubit.dart';
import '../cubit/therapist_state.dart';

class BookingSheet extends StatefulWidget {
  final TherapistModel therapist;

  const BookingSheet({super.key, required this.therapist});

  static Future<void> show(BuildContext context, TherapistModel therapist) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<TherapistCubit>(),
        child: BookingSheet(therapist: therapist),
      ),
    );
  }

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  late String _selectedSlot;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.therapist.availableSlots.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocBuilder<TherapistCubit, TherapistState>(
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 24.h,
            bottom: 24.h + bottomInset,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Book 1-on-1 Consultation',
                    style: AppTextStyles.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Therapist Quick Info
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22.r,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        widget.therapist.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.therapist.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.therapist.hourlyRate,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),

              Text(
                'Select Time Slot',
                style: AppTextStyles.titleSmall,
              ),
              SizedBox(height: 10.h),

              // Slot Chips
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: widget.therapist.availableSlots.map((slot) {
                  final isSelected = _selectedSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceVariant,
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedSlot = slot);
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 18.h),

              AppTextField(
                controller: _notesController,
                hintText: 'e.g. Stuttering during presentations, fast speech rate...',
                labelText: 'Focus Area / Goals (Optional)',
                maxLines: 2,
              ),
              SizedBox(height: 24.h),

              AppButton(
                text: 'Confirm Consultation Session',
                isLoading: state.isBooking,
                onTap: () async {
                  final navigator = Navigator.of(context);
                  await context.read<TherapistCubit>().bookSession(
                        slot: _selectedSlot,
                        contactNote: _notesController.text,
                      );
                  if (!mounted) return;
                  navigator.pop();
                },
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }
}
