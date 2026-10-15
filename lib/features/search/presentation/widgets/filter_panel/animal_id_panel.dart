// =============================================================================
// FILE: lib/features/search/presentation/widgets/filter_panel/animal_id_panel.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: Renders specialized animal ID search parameters (chip, passport).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_event.dart';

class AnimalIdPanel extends StatelessWidget {
  final TextEditingController chipController;
  final TextEditingController passportController;
  final TextEditingController insuranceController;
  final Map<String, dynamic> trans;

  const AnimalIdPanel({
    required this.chipController,
    required this.passportController,
    required this.insuranceController,
    required this.trans,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF0F172A);
    const Color borderCyan = Color(0xFF00F2FF);

    final String titleText = trans['animal_identifiers'] ??
        trans['senses.index.animal_identifiers'] ??
        'ІДЕНТИФІКАТОРИ ТВАРИНИ';
    final String chipHint = trans['chip_number'] ?? 'Microchip ID (e.g. 98512...)';
    final String passportHint = trans['passport_number'] ?? 'Passport / Reg №';
    final String insuranceHint = trans['insurance_policy'] ?? 'Insurance Policy №';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText.toUpperCase(),
            style: const TextStyle(
              color: borderCyan,
              fontFamily: 'Orbitron',
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _idTextField(context, chipController, chipHint, 'q[animal_metadata_chip_number]'),
          const SizedBox(height: 8),
          _idTextField(context, passportController, passportHint, 'q[animal_metadata_passport_number]'),
          const SizedBox(height: 8),
          _idTextField(context, insuranceController, insuranceHint, 'q[animal_metadata_insurance_policy_id]'),
        ],
      ),
    );
  }

  Widget _idTextField(
    BuildContext context,
    TextEditingController controller,
    String hint,
    String filterKey,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF00F2FF)),
        ),
      ),
      onChanged: (val) {
        context.read<SearchBloc>().add(UpdateFilterValue(filterId: filterKey, value: val));
      },
    );
  }
}