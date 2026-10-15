import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:findway_mobile/features/search/presentation/bloc/search_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_event.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final int totalCount;

  const PaginationBar({
    required this.currentPage,
    required this.lastPage,
    required this.totalCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF1E293B);
    const Color neonOrange = Color(0xFFFF8A00);
    const Color neonBlue = Color(0xFF00F2FF);

    final bool canGoPrevious = currentPage > 1;
    final bool canGoNext = currentPage < lastPage;

    debugPrint(
      '[PAGINATION] Widget build: '
      'currentPage=$currentPage, '
      'lastPage=$lastPage, '
      'totalCount=$totalCount, '
      'canGoPrevious=$canGoPrevious, '
      'canGoNext=$canGoNext',
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: darkSlate,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous page
          IconButton(
            onPressed: canGoPrevious
                ? () {
                    debugPrint(
                      '[PAGINATION] Previous tapped: '
                      'currentPage=$currentPage, '
                      'lastPage=$lastPage',
                    );

                    final int targetPage = currentPage - 1;

                    debugPrint(
                      '[PAGINATION] Dispatching '
                      'ChangePage($targetPage)',
                    );

                    context.read<SearchBloc>().add(
                      ChangePage(targetPage),
                    );
                  }
                : null,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
            ),
            color: canGoPrevious ? neonBlue : Colors.white24,
          ),

          // Page counter
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$currentPage / $lastPage',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Total: $totalCount',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          // Next page
          IconButton(
            onPressed: canGoNext
                ? () {
                    debugPrint(
                      '[PAGINATION] Next tapped: '
                      'currentPage=$currentPage, '
                      'lastPage=$lastPage, '
                      'totalCount=$totalCount',
                    );

                    final int targetPage = currentPage + 1;

                    debugPrint(
                      '[PAGINATION] Dispatching '
                      'ChangePage($targetPage)',
                    );

                    context.read<SearchBloc>().add(
                      ChangePage(targetPage),
                    );
                  }
                : null,
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 18,
            ),
            color: canGoNext ? neonOrange : Colors.white24,
          ),
        ],
      ),
    );
  }
}
