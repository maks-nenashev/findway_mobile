// =============================================================================
// FILE: lib/features/search/presentation/pages/search_page.dart
// LAYER: Presentation Layer (Page Orchestrator)
// RESPONSIBILITY: Main orchestrator managing page controllers, BLoC listeners,
//                 navigation state, and high-level layout routing.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:findway_mobile/injection_container.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_event.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_state.dart';
import 'package:findway_mobile/features/search/presentation/widgets/map/index_map_widget.dart';

import 'package:findway_mobile/features/search/presentation/pages/post_create_page.dart';
import 'package:findway_mobile/features/search/presentation/pages/post_card_page.dart';

import 'package:findway_mobile/features/chat/presentation/pages/inbox_page.dart';
import 'package:findway_mobile/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:findway_mobile/features/chat/presentation/bloc/chat_event.dart';
import 'package:findway_mobile/features/chat/presentation/bloc/notification_bloc.dart';

// MODULAR IMPORTS
import 'package:findway_mobile/features/search/presentation/widgets/navigation/custom_bottom_nav_bar.dart';
import 'package:findway_mobile/features/search/presentation/widgets/navigation/multi_color_post_button.dart';
import 'package:findway_mobile/features/search/presentation/widgets/title_layout/title_layout.dart';
import 'package:findway_mobile/features/search/presentation/widgets/filter_panel/filter_panel.dart';
import 'package:findway_mobile/features/search/presentation/widgets/search_results_grid.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _localActiveCategory = '';
  late ScrollController _mainScrollController;
  late ScrollController _titleScrollController;
  bool _isMenuVisible = true;

  double _radiusKm = 5.0;
  double? _searchLat;
  double? _searchLng;

  // Animal Controllers
  final TextEditingController _chipController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _insuranceController = TextEditingController();

  // Thing Controllers Map
  late final Map<String, TextEditingController> _thingControllers;

  @override
  void initState() {
    super.initState();
    _mainScrollController = ScrollController()..addListener(() => _handleScroll(_mainScrollController));
    _titleScrollController = ScrollController()..addListener(() => _handleScroll(_titleScrollController));

    _thingControllers = {
      'brand_model': TextEditingController(),
      'vin': TextEditingController(),
      'license_plate': TextEditingController(),
      'imei': TextEditingController(),
      'serial_number': TextEditingController(),
      'frame_number': TextEditingController(),
      'document_type': TextEditingController(),
      'document_number': TextEditingController(),
      'full_name': TextEditingController(),
      'color': TextEditingController(),
      'hallmark': TextEditingController(),
      'engraving': TextEditingController(),
      'key_type': TextEditingController(),
      'keychain_description': TextEditingController(),
      'contents_description': TextEditingController(),
      'additional_info': TextEditingController(),
    };
  }

  void _handleScroll(ScrollController controller) {
    if (!controller.hasClients) return;
    if (controller.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isMenuVisible) setState(() => _isMenuVisible = false);
    } else if (controller.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isMenuVisible) setState(() => _isMenuVisible = true);
    }
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _titleScrollController.dispose();

    _chipController.dispose();
    _passportController.dispose();
    _insuranceController.dispose();

    _thingControllers.forEach((_, controller) => controller.dispose());

    super.dispose();
  }

  void _resetGeoAndControllers() {
    _chipController.clear();
    _passportController.clear();
    _insuranceController.clear();
    _thingControllers.forEach((_, controller) => controller.clear());

    setState(() {
      _searchLat = null;
      _searchLng = null;
      _radiusKm = 5.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = sl<SearchBloc>();
        final String initialLocale = bloc.currentLocale.isNotEmpty ? bloc.currentLocale : 'uk';
        bloc.add(LoadFilters(category: '', locale: initialLocale));
        return bloc;
      },
      child: BlocConsumer<SearchBloc, SearchState>(
        buildWhen: (previous, current) {
          return current is FiltersLoaded ||
                 current is SearchSuccess ||
                 current is ResultsLoading ||
                 current is SearchLoading ||
                 current is SearchInitial ||
                 current is SearchError;
        },
        listener: (context, state) {
          if (state is FiltersLoaded) {
            setState(() {
              _localActiveCategory = state.currentCategory;
            });
          }
        },
        builder: (context, state) {
          final translations = _extractTranslations(state);
          final currentLocale = _extractLocale(context, state, translations);
          final searchResults = _extractResults(state);
          final filters = _extractFilters(state);
          final selectedFilterValues = _extractSelectedValues(state);
          final currentTabIndex = _extractTabIndex(state);

          final int currentPage = _extractCurrentPage(state);
          final int lastPage = _extractLastPage(state);
          final int totalCount = _extractTotalCount(state);

          final bool isTitlePage = _localActiveCategory.isEmpty;

          return Scaffold(
            extendBody: true,
            backgroundColor: const Color(0xFFF0F4F8),
            floatingActionButton: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _isMenuVisible ? Offset.zero : const Offset(0, 2.5),
              child: Transform.translate(
                offset: const Offset(0, 32),
                child: GestureDetector(
                  onTap: () async {
                    final String targetCategory = _localActiveCategory.isEmpty ? 'people' : _localActiveCategory;
                    
                    // 🛡 БЕЗОПАСНЫЙ ДОСТУП К АСИНХРОННОМУ КОНТЕКСТУ:
                    // Кэшируем ссылки на BLoC и Navigator до вызова await
                    final searchBloc = context.read<SearchBloc>();
                    final navigator = Navigator.of(context);

                    final result = await navigator.push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: searchBloc,
                          child: PostCreatePage(initialCategory: targetCategory),
                        ),
                      ),
                    );

                    if (!mounted) return;

                    if (result is int) {
                      searchBloc.add(LoadPostDetails(id: result, category: targetCategory, locale: searchBloc.currentLocale));
                      await navigator.push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(value: searchBloc, child: const PostCardPage()),
                        ),
                      );
                      if (!mounted) return;
                      searchBloc.add(LoadFilters(category: targetCategory, locale: searchBloc.currentLocale));
                    } else if (result == true) {
                      searchBloc.add(LoadFilters(category: targetCategory, locale: searchBloc.currentLocale));
                    }
                  },
                  child: const MultiColorPostButton(),
                ),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

            bottomNavigationBar: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _isMenuVisible ? Offset.zero : const Offset(0, 2.0),
              child: BlocBuilder<NotificationBloc, int>(
                builder: (context, unreadCount) {
                  return CustomBottomNavBar(
                    currentIndex: currentTabIndex,
                    currentLocale: currentLocale,
                    translations: translations,
                    unreadCount: unreadCount,
                    onTap: (index) {
                      if (index == 0) {
                        context.read<SearchBloc>().add(ChangeTab(0));
                      } else if (index == 3) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => sl<ChatBloc>()..add(FetchInbox(locale: currentLocale)),
                              child: InboxPage(currentLocale: currentLocale),
                            ),
                          ),
                        );
                      } else if (index == 4) {
                        Navigator.pushNamed(
                          context,
                          '/profile',
                          arguments: {
                            'locale': currentLocale,
                          },
                        );
                      } else {
                        context.read<SearchBloc>().add(ChangeTab(index));
                      }
                    },
                  );
                },
              ),
            ),

            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isTitlePage
                ? TitleLayout(
                    scrollController: _titleScrollController,
                    translations: translations,
                    currentLocale: currentLocale,
                    onCategorySelected: (cat) {
                      setState(() => _localActiveCategory = cat);
                      final bloc = context.read<SearchBloc>();
                      bloc.add(LoadFilters(category: cat, locale: bloc.currentLocale));
                    },
                  )
                : Stack(
                    key: const ValueKey('ModelLayout'),
                    children: [
                      CustomScrollView(
                        controller: _mainScrollController,
                        slivers: [
                          _buildSliverAppBar(context),

                          SliverToBoxAdapter(
                            child: FilterPanel(
                              state: state,
                              translations: translations,
                              currentLocale: currentLocale,
                              filters: filters,
                              selectedFilterValues: selectedFilterValues,
                              activeCategory: _localActiveCategory,
                              onCategoryChanged: (cat) {
                                setState(() => _localActiveCategory = cat);
                                final bloc = context.read<SearchBloc>();
                                bloc.add(LoadFilters(category: cat, locale: bloc.currentLocale));
                              },
                              chipController: _chipController,
                              passportController: _passportController,
                              insuranceController: _insuranceController,
                              thingControllers: _thingControllers,
                              radiusKm: _radiusKm,
                              searchLat: _searchLat,
                              searchLng: _searchLng,
                              onRadiusChanged: (rad) => setState(() => _radiusKm = rad),
                              onLocationSet: (lat, lng) => setState(() {
                                _searchLat = lat;
                                _searchLng = lng;
                              }),
                              onResetGeoAndControllers: _resetGeoAndControllers,
                            ),
                          ),

                          if (searchResults.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: IndexMapWidget(
                                  results: searchResults,
                                  radiusKm: double.tryParse(
                                    selectedFilterValues['radius_km']?.toString() ?? '10',
                                  ),
                                  translations: translations,
                                  onLocationFound: (userLocation) {
                                    final searchBloc = context.read<SearchBloc>();
                                    final double? radius = double.tryParse(
                                      selectedFilterValues['radius_km']?.toString() ?? '10',
                                    );

                                    searchBloc.add(
                                      SearchFilterChanged(
                                        lat: userLocation.latitude,
                                        lng: userLocation.longitude,
                                        radiusKm: radius,
                                      ),
                                    );
                                  },
                                  onMarkerTap: (id, category) async {
                                    final bloc = context.read<SearchBloc>();
                                    bloc.add(LoadPostDetails(id: id, category: category, locale: currentLocale));

                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BlocProvider.value(
                                          value: bloc,
                                          child: const PostCardPage(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                          if (searchResults.isNotEmpty)
                            SearchResultsGrid(
                              results: searchResults,
                              currentLocale: currentLocale,
                              currentPage: currentPage,
                              lastPage: lastPage,
                              totalCount: totalCount,
                            )
                          else if (state is! SearchLoading && state is! ResultsLoading)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  translations['no_results'] ?? 'No results found',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),

                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 180.0 + MediaQuery.of(context).padding.bottom,
                            ),
                          ),
                        ],
                      ),

                      if (state is SearchLoading || state is ResultsLoading)
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF00F2FF)),
                          ),
                        ),
                    ],
                  ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF0F4F8),
      elevation: 0,
      floating: true,
      title: Padding(
        padding: const EdgeInsets.only(left: 5.0),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _localActiveCategory = '';
            });
            final bloc = context.read<SearchBloc>();
            bloc.add(LoadFilters(category: '', locale: bloc.currentLocale));
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Image.asset(
              'assets/images/logo1.png',
              height: 65,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _extractTranslations(SearchState state) {
    if (state is FiltersLoaded) return state.uiTranslations;
    if (state is SearchSuccess) return state.uiTranslations;
    if (state is ResultsLoading) return state.uiTranslations;
    if (state is SearchLoading) return state.uiTranslations;
    return {};
  }

  String _extractLocale(BuildContext context, SearchState state, Map<String, dynamic> translations) {
    if (state.currentLocale.isNotEmpty) return state.currentLocale;
    return translations['locale_code']?.toString() ?? 'uk';
  }

  List<dynamic> _extractResults(SearchState state) {
    if (state is FiltersLoaded) return state.results;
    if (state is SearchSuccess) return state.results;
    if (state is ResultsLoading) return state.results;
    return [];
  }

  dynamic _extractFilters(SearchState state) {
    if (state is FiltersLoaded) return state.filters;
    if (state is ResultsLoading) return state.filters;
    if (state is SearchSuccess) return state.filters;
    return null;
  }

  Map<String, dynamic> _extractSelectedValues(SearchState state) {
    if (state is FiltersLoaded) return state.selectedValues.cast<String, dynamic>();
    if (state is SearchSuccess) return state.selectedValues.cast<String, dynamic>();
    if (state is ResultsLoading) return state.selectedValues.cast<String, dynamic>();
    return {};
  }

  int _extractTabIndex(SearchState state) {
    if (state is FiltersLoaded) return state.tabIndex;
    if (state is SearchSuccess) return state.tabIndex;
    if (state is ResultsLoading) return state.tabIndex;
    return 1;
  }

  int _extractCurrentPage(SearchState state) {
    if (state is SearchSuccess) return state.currentPage;
    if (state is FiltersLoaded) return state.currentPage;
    return 1;
  }

  int _extractLastPage(SearchState state) {
    if (state is SearchSuccess) return state.lastPage;
    if (state is FiltersLoaded) return state.lastPage;
    return 1;
  }

  int _extractTotalCount(SearchState state) {
    if (state is SearchSuccess) return state.totalCount;
    if (state is FiltersLoaded) return state.totalCount;
    return 0;
  }
}