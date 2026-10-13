// =============================================================================
// FILE: lib/features/search/presentation/pages/search_page.dart
// LAYER: Presentation Layer (Page)
// RESPONSIBILITY: Main search dashboard rendering category feeds, interactive
//                 OpenStreetMap index maps, PostGIS radius filters, and
//                 dynamic ID panels synchronized with chosen subcategories.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:findway_mobile/injection_container.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_event.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_state.dart';
import 'package:findway_mobile/features/search/presentation/widgets/filter_builder.dart';
import 'package:findway_mobile/features/search/presentation/widgets/articles_card.dart';
import 'package:findway_mobile/features/search/presentation/widgets/locale_selector.dart';
import 'package:findway_mobile/features/search/presentation/widgets/map/index_map_widget.dart';

import 'package:findway_mobile/features/search/presentation/pages/post_create_page.dart'; 
import 'package:findway_mobile/features/search/presentation/pages/post_card_page.dart'; 

import 'package:findway_mobile/features/chat/presentation/pages/inbox_page.dart';
import 'package:findway_mobile/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:findway_mobile/features/chat/presentation/bloc/chat_event.dart';
import 'package:findway_mobile/features/chat/presentation/bloc/notification_bloc.dart';

// =============================================================================
// 1. CATEGORY MODEL
// =============================================================================
class FindWayCategory {
  final String title;
  final String description;
  final String imagePath;
  final String modelsInfo;
  final Color accentColor;

  const FindWayCategory({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.modelsInfo,
    required this.accentColor,
  });
}

// =============================================================================
// 2. MAIN SEARCH PAGE WIDGET & STATE
// =============================================================================
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

  bool _isAdvancedIdOpen = false;
  bool _isGeoPanelOpen = false;

  double _radiusKm = 5.0;
  double? _searchLat;
  double? _searchLng;

  // Animal Controllers
  final TextEditingController _chipController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _insuranceController = TextEditingController();

  // Thing Controllers (All 16 fields)
  final TextEditingController _brandModelController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _frameNumberController = TextEditingController();
  final TextEditingController _docTypeController = TextEditingController();
  final TextEditingController _docNumberController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _hallmarkController = TextEditingController();
  final TextEditingController _engravingController = TextEditingController();
  final TextEditingController _keyTypeController = TextEditingController();
  final TextEditingController _keychainDescController = TextEditingController();
  final TextEditingController _contentsDescController = TextEditingController();
  final TextEditingController _additionalInfoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mainScrollController = ScrollController()..addListener(() => _handleScroll(_mainScrollController));
    _titleScrollController = ScrollController()..addListener(() => _handleScroll(_titleScrollController));
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

    _brandModelController.dispose();
    _vinController.dispose();
    _licensePlateController.dispose();
    _imeiController.dispose();
    _serialNumberController.dispose();
    _frameNumberController.dispose();
    _docTypeController.dispose();
    _docNumberController.dispose();
    _fullNameController.dispose();
    _colorController.dispose();
    _hallmarkController.dispose();
    _engravingController.dispose();
    _keyTypeController.dispose();
    _keychainDescController.dispose();
    _contentsDescController.dispose();
    _additionalInfoController.dispose();

    super.dispose();
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
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<SearchBloc>(),
                          child: PostCreatePage(initialCategory: targetCategory),
                        ),
                      ),
                    );

                    if (mounted) {
                      final bloc = context.read<SearchBloc>();
                      if (result is int) {
                        bloc.add(LoadPostDetails(id: result, category: targetCategory, locale: bloc.currentLocale));
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider.value(value: bloc, child: PostCardPage()),
                          ),
                        );
                        if (mounted) bloc.add(LoadFilters(category: targetCategory, locale: bloc.currentLocale));
                      } else if (result == true) {
                        bloc.add(LoadFilters(category: targetCategory, locale: bloc.currentLocale));
                      }
                    }
                  },
                  child: _buildMultiColorPostButton(),
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
                        Navigator.pushNamed(context, '/profile');
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
                ? _buildTitleLayout(context, translations) 
                : Stack( 
                    key: const ValueKey('ModelLayout'),
                    children: [
                      CustomScrollView(
                        controller: _mainScrollController,
                        slivers: [
                          _buildSliverAppBar(),
                          SliverToBoxAdapter(
                            child: _buildFilterPanel(
                              context, state, translations, currentLocale,
                              filters, selectedFilterValues, _localActiveCategory,
                            ),
                          ),

                          if (searchResults.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: IndexMapWidget(
                                  results: searchResults,
                                  translations: translations,
                                  onMarkerTap: (id, category) {
                                    final bloc = context.read<SearchBloc>();
                                    bloc.add(LoadPostDetails(id: id, category: category, locale: currentLocale));
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BlocProvider.value(value: bloc, child: PostCardPage()),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                          if (searchResults.isNotEmpty)
                            _buildResultsGrid(searchResults, currentLocale)
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
                          const SliverToBoxAdapter(child: SizedBox(height: 120)),
                        ],
                      ),
                      if (state is SearchLoading)
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF0F4F8),
      elevation: 0,
      floating: true,
      title: Padding(
        padding: const EdgeInsets.only(left: 5.0), 
        child: Image.asset(
          'assets/images/logo1.png',
          height: 65, 
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTitleLayout(BuildContext context, Map<String, dynamic> trans) {
    final categories = _getLocalizedCategories(trans);
    return CustomScrollView(
      controller: _titleScrollController,
      slivers: [
        _buildSliverAppBar(),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return CategoryCard(
                  category: categories[index],
                  onTap: () {
                    context.read<SearchBloc>().add(
                      LoadFilters(category: _getRawCategoryName(index), locale: '')
                    );
                  },
                );
              },
              childCount: categories.length,
            ),
          ),
        ),
      ],
    );
  }

  List<FindWayCategory> _getLocalizedCategories(Map<String, dynamic> trans) {
    return [
      FindWayCategory(
        title: trans['title_one'] ?? 'People',
        accentColor: const Color(0xFF00F2FF),
        modelsInfo: 'Models EfficientNet-B0, ArcFace & NLP | ACTIVE',
        description: trans['description_one'] ?? '',
        imagePath: 'assets/images/peop.png',
      ),
      FindWayCategory(
        title: trans['title_two'] ?? 'Animals',
        accentColor: const Color(0xFFFF8A00),
        modelsInfo: 'Models EfficientNet-B0, NLP | ACTIVE',
        description: trans['description_two'] ?? '',
        imagePath: 'assets/images/cat.png',
      ),
      FindWayCategory(
        title: trans['title_three'] ?? 'Things',
        accentColor: const Color(0xFF2ECC71),
        modelsInfo: 'Models EfficientNet-B0, NLP | ACTIVE',
        description: trans['description_three'] ?? '',
        imagePath: 'assets/images/things.png',
      ),
    ];
  }

  String _getRawCategoryName(int index) {
    switch (index) {
      case 0: return 'people';
      case 1: return 'animals';
      case 2: return 'things';
      default: return 'people';
    }
  }

  Widget _buildMultiColorPostButton() {
    return Transform.translate(
      offset: const Offset(0, -4),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Color(0xFF23E5DB),
                Color(0xFF002F34),
                Color(0xFF6A11CB),
                Color(0xFFFF5F6D),
                Color(0xFFFFCE32),
                Color(0xFF23E5DB)
              ],
              stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 38, color: Color(0xFF002F34)),
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // FILTER PANEL WITH ID & GEO UNDER DROPDOWNS
  // =============================================================================
  Widget _buildFilterPanel(
    BuildContext context, 
    SearchState state, 
    Map<String, dynamic> translations, 
    String currentLocale, 
    dynamic filters, 
    Map<String, dynamic> selectedFilterValues, 
    String activeCategory
  ) {
    const Color darkSlate = Color(0xFF1E293B);
    const Color neonBlue = Color(0xFF00F2FF);
    final bool isAnimalCategory = activeCategory == 'animals';
    final bool isThingCategory = activeCategory == 'things';
    final bool hasIdPanel = isAnimalCategory || isThingCategory;

    final String? selectedSubCategoryLabel = _getSelectedSubCategoryLabel(filters, selectedFilterValues);
    final int fieldsCount = _getFieldsCountForCategory(selectedSubCategoryLabel);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkSlate, 
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: darkSlate, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryButtons(context, activeCategory, translations, currentLocale),
            const SizedBox(height: 20),

            _buildSearchField(context, translations),
            const SizedBox(height: 16),

            if (filters != null) ...[
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true, 
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 10),
                    floatingLabelStyle: const TextStyle(color: neonBlue, fontWeight: FontWeight.bold, fontSize: 16),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkSlate)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: neonBlue, width: 2)),
                  ),
                ),
                child: FilterBuilder(
                  filters: filters,
                  selectedValues: selectedFilterValues,
                  currentCategory: activeCategory,
                  onFilterChanged: (id, val) => context.read<SearchBloc>().add(UpdateFilterValue(filterId: id, value: val)),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                if (hasIdPanel) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _isAdvancedIdOpen = !_isAdvancedIdOpen),
                      icon: const Icon(Icons.security, size: 16),
                      label: Text(
                        fieldsCount > 0 ? 'ID ($fieldsCount)' : 'ID',
                        style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00F2FF),
                        side: const BorderSide(color: Color(0xFF00F2FF)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _isGeoPanelOpen = !_isGeoPanelOpen),
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text('Geo', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF8A00),
                      side: const BorderSide(color: Color(0xFFFF8A00)),
                    ),
                  ),
                ),
              ],
            ),

            if (isAnimalCategory && _isAdvancedIdOpen) 
              _buildAdvancedAnimalIdPanel(context, translations),

            if (isThingCategory && _isAdvancedIdOpen) 
              _buildAdvancedThingIdPanel(context, translations, selectedSubCategoryLabel),

            if (_isGeoPanelOpen) 
              _buildGeoPanel(context, translations),

            const SizedBox(height: 16),

            if (filters != null)
              _buildApplyFiltersButton(context, translations),

            if (state is SearchSuccess) 
              _buildResetFiltersButton(context, currentLocale, activeCategory, translations),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedAnimalIdPanel(BuildContext context, Map<String, dynamic> trans) {
    const Color darkBg = Color(0xFF0F172A);
    const Color borderCyan = Color(0xFF00F2FF);

    final String titleText = trans['animal_identifiers'] ?? trans['senses.index.animal_identifiers'] ?? 'ІДЕНТИФІКАТОРИ ТВАРИНИ';
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
            style: const TextStyle(color: borderCyan, fontFamily: 'Orbitron', fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _idTextField(_chipController, chipHint, 'q[animal_metadata_chip_number]'),
          const SizedBox(height: 8),
          _idTextField(_passportController, passportHint, 'q[animal_metadata_passport_number]'),
          const SizedBox(height: 8),
          _idTextField(_insuranceController, insuranceHint, 'q[animal_metadata_insurance_policy_id]'),
        ],
      ),
    );
  }

  Widget _buildAdvancedThingIdPanel(
    BuildContext context, 
    Map<String, dynamic> trans, 
    String? subCategoryLabel
  ) {
    const Color darkBg = Color(0xFF0F172A);
    const Color borderCyan = Color(0xFF00F2FF);

    final List<String> fields = _getFieldsForCategoryLabel(subCategoryLabel);

    if (fields.isEmpty) {
      final String prompt = trans['thing_metadata.select_category_prompt'] ?? 
                            trans['select_category_prompt'] ?? 
                            'Select a category to view specific parameters (VIN, IMEI, frame number, documents, etc.).';
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: borderCyan, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                prompt,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final String titleText = subCategoryLabel != null
        ? 'IDENTIFIERS: ${subCategoryLabel.toUpperCase()}'
        : (trans['thing_metadata.title'] ?? 'THING IDENTIFIERS');

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
            style: const TextStyle(color: borderCyan, fontFamily: 'Orbitron', fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...fields.map((field) {
            final String label = _getAttrLabel(field, trans);
            final String placeholder = _getAttrPlaceholder(field, trans);
            final TextEditingController controller = _getControllerForField(field);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _idTextField(
                controller, 
                placeholder.isNotEmpty ? placeholder : label, 
                'q[thing_metadata_$field]',
                labelOverride: label,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _idTextField(
    TextEditingController controller, 
    String hint, 
    String filterKey, 
    {String? labelOverride}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelOverride != null && labelOverride.isNotEmpty) ...[
          Text(
            labelOverride,
            style: const TextStyle(color: Color(0xFF00F2FF), fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
        ],
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00F2FF))),
          ),
          onChanged: (val) {
            context.read<SearchBloc>().add(UpdateFilterValue(filterId: filterKey, value: val));
          },
        ),
      ],
    );
  }

  String? _getSelectedSubCategoryLabel(dynamic filters, Map<String, dynamic> selectedValues) {
    if (filters == null) return null;

    dynamic selectedId;
    selectedValues.forEach((k, v) {
      if ((k.contains('phone_id') || k.contains('cat_id') || k.contains('sub_category')) && v != null) {
        selectedId = v;
      }
    });

    if (selectedId == null) return null;

    if (filters is List) {
      for (final f in filters) {
        if (f.options != null) {
          for (final opt in f.options) {
            if (opt.id.toString() == selectedId.toString()) {
              return opt.label;
            }
          }
        }
      }
    }
    return null;
  }

  List<String> _getFieldsForCategoryLabel(String? label) {
    if (label == null || label.trim().isEmpty) return [];

    final lower = label.toLowerCase();
    if (lower.contains('doc') || lower.contains('документ') || lower.contains('dokumen')) {
      return ['document_type', 'document_number', 'full_name'];
    } else if (lower.contains('phone') || lower.contains('телефон') || lower.contains('telefon') || lower.contains('gadget')) {
      return ['imei', 'serial_number', 'brand_model', 'color'];
    } else if (lower.contains('car') || lower.contains('авто') || lower.contains('машин') || lower.contains('samochód')) {
      return ['vin', 'license_plate', 'brand_model', 'color'];
    } else if (lower.contains('moto') || lower.contains('мото')) {
      return ['vin', 'license_plate', 'brand_model', 'color'];
    } else if (lower.contains('bike') || lower.contains('вело') || lower.contains('rower')) {
      return ['frame_number', 'brand_model', 'color'];
    } else if (lower.contains('jewel') || lower.contains('ювелир') || lower.contains('прикрас') || lower.contains('biżuteria')) {
      return ['brand_model', 'serial_number', 'hallmark', 'engraving'];
    } else if (lower.contains('key') || lower.contains('ключ') || lower.contains('klucz')) {
      return ['key_type', 'keychain_description'];
    } else if (lower.contains('bag') || lower.contains('сумк') || lower.contains('кошел') || lower.contains('portfel') || lower.contains('wallet')) {
      return ['brand_model', 'color', 'contents_description'];
    }

    return ['brand_model', 'serial_number', 'additional_info'];
  }

  int _getFieldsCountForCategory(String? label) {
    return _getFieldsForCategoryLabel(label).length;
  }

  TextEditingController _getControllerForField(String field) {
    switch (field) {
      case 'vin': return _vinController;
      case 'license_plate': return _licensePlateController;
      case 'imei': return _imeiController;
      case 'serial_number': return _serialNumberController;
      case 'frame_number': return _frameNumberController;
      case 'document_type': return _docTypeController;
      case 'document_number': return _docNumberController;
      case 'full_name': return _fullNameController;
      case 'brand_model': return _brandModelController;
      case 'color': return _colorController;
      case 'hallmark': return _hallmarkController;
      case 'engraving': return _engravingController;
      case 'key_type': return _keyTypeController;
      case 'keychain_description': return _keychainDescController;
      case 'contents_description': return _contentsDescController;
      case 'additional_info': return _additionalInfoController;
      default: return _brandModelController;
    }
  }

  String _getAttrLabel(String field, Map<String, dynamic> trans) {
    final keys = [
      'thing_metadata.attributes.$field',
      'thing_metadata_attributes_$field',
      'attributes.$field',
    ];
    for (final k in keys) {
      if (trans.containsKey(k) && trans[k] != null && trans[k].toString().isNotEmpty) {
        return trans[k].toString();
      }
    }
    switch (field) {
      case 'vin': return 'VIN Number';
      case 'license_plate': return 'License Plate';
      case 'imei': return 'IMEI Code';
      case 'serial_number': return 'Serial Number (S/N)';
      case 'frame_number': return 'Frame Number';
      case 'document_type': return 'Document Type';
      case 'document_number': return 'Document Number / Series';
      case 'full_name': return 'Full Name on Document';
      case 'brand_model': return 'Brand / Model';
      case 'color': return 'Color';
      case 'hallmark': return 'Hallmark / Stamp';
      case 'engraving': return 'Engraving / Markings';
      case 'key_type': return 'Key Type (car, apartment)';
      case 'keychain_description': return 'Keychain Description';
      case 'contents_description': return 'Contents Description';
      case 'additional_info': return 'Additional Distinctive Features';
      default: return field;
    }
  }

  String _getAttrPlaceholder(String field, Map<String, dynamic> trans) {
    final keys = [
      'thing_metadata.placeholders.$field',
      'thing_metadata_placeholders_$field',
      'placeholders.$field',
    ];
    for (final k in keys) {
      if (trans.containsKey(k) && trans[k] != null && trans[k].toString().isNotEmpty) {
        return trans[k].toString();
      }
    }
    switch (field) {
      case 'vin': return 'e.g., WBA3A51070F...';
      case 'imei': return '15 digits (e.g., 356890...)';
      case 'license_plate': return 'e.g., KR 12345';
      case 'frame_number': return 'e.g., WTU1234567X';
      case 'document_number': return 'e.g., AB 123456';
      case 'full_name': return 'Full name as shown on document';
      default: return '';
    }
  }

  Widget _buildGeoPanel(BuildContext context, Map<String, dynamic> trans) {
    const Color darkBg = Color(0xFF0F172A);
    const Color orangeAccent = Color(0xFFFF8A00);

    final String titleText = trans['radius_search'] ?? 
                              trans['map_picker.radius_search'] ?? 
                              trans['shared.map_picker.radius_search'] ?? 
                              trans['filters.radius_search'] ?? 
                              'Пошук у радіусі (PostGIS)';

    final String radiusLabelText = trans['radius_label'] ?? 
                                   trans['map_picker.radius_label'] ?? 
                                   trans['shared.map_picker.radius_label'] ?? 
                                   trans['filters.radius_label'] ?? 
                                   'Радіус покриття';

    final String kmUnit = trans['km'] ?? 
                          trans['map_picker.km'] ?? 
                          trans['shared.map_picker.km'] ?? 
                          trans['filters.km'] ?? 
                          'км';

    final String btnText = trans['detect_my_location'] ?? 
                           trans['map_picker.detect_my_location'] ?? 
                           trans['shared.map_picker.detect_my_location'] ?? 
                           trans['filters.detect_my_location'] ?? 
                           'Визначити мою геолокацію';

    final String centerPrefix = trans['search_center'] ?? 
                                 trans['map_picker.search_center'] ?? 
                                 trans['shared.map_picker.search_center'] ?? 
                                 trans['filters.search_center'] ?? 
                                 'Центр';

    final String noCenterText = trans['no_search_center'] ?? 
                                trans['map_picker.no_search_center'] ?? 
                                trans['shared.map_picker.no_search_center'] ?? 
                                trans['filters.no_search_center'] ?? 
                                'Центр не вибрано';

    final String geoStatusText = (_searchLat != null && _searchLng != null)
        ? '$centerPrefix: ${_searchLat!.toStringAsFixed(3)}, ${_searchLng!.toStringAsFixed(3)}'
        : noCenterText;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orangeAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText.toUpperCase(),
            style: const TextStyle(color: orangeAccent, fontFamily: 'Orbitron', fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                radiusLabelText,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
              ),
              Text(
                '${_radiusKm.round()} $kmUnit',
                style: const TextStyle(color: orangeAccent, fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_radiusKm > 1) {
                    setState(() => _radiusKm--);
                    context.read<SearchBloc>().add(UpdateFilterValue(filterId: 'radius_km', value: _radiusKm.round()));
                  }
                },
                icon: const Icon(Icons.remove_circle_outline, color: orangeAccent, size: 20),
              ),
              Expanded(
                child: Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 200,
                  divisions: 199,
                  activeColor: orangeAccent,
                  inactiveColor: Colors.white12,
                  onChanged: (val) {
                    setState(() => _radiusKm = val);
                    context.read<SearchBloc>().add(UpdateFilterValue(filterId: 'radius_km', value: _radiusKm.round()));
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_radiusKm < 200) {
                    setState(() => _radiusKm++);
                    context.read<SearchBloc>().add(UpdateFilterValue(filterId: 'radius_km', value: _radiusKm.round()));
                  }
                },
                icon: const Icon(Icons.add_circle_outline, color: orangeAccent, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchLat = 50.0412;
                  _searchLng = 21.9991;
                });
                final bloc = context.read<SearchBloc>();
                bloc.add(const UpdateFilterValue(filterId: 'search_lat', value: 50.0412));
                bloc.add(const UpdateFilterValue(filterId: 'search_lng', value: 21.9991));
                bloc.add(UpdateFilterValue(filterId: 'radius_km', value: _radiusKm.round()));
                bloc.add(const PerformSearch());
              },
              icon: const Icon(Icons.my_location, size: 16),
              label: Text(btnText.toUpperCase(), style: const TextStyle(fontFamily: 'Orbitron', fontSize: 10)),
              style: OutlinedButton.styleFrom(
                foregroundColor: orangeAccent,
                side: const BorderSide(color: orangeAccent),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            geoStatusText,
            style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'Monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, Map<String, dynamic> translations) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: translations['plac_title'] ?? 'Пошук...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: ElevatedButton(
              onPressed: () => context.read<SearchBloc>().add(const PerformSearch()),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00)),
              child: Text(translations['find'] ?? 'FIND', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        ),
      ),
    );
  }

  Widget _buildResultsGrid(List<dynamic> results, String currentLocale) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = results[index];
            final int id = post['id'] ?? index;
            final String imageUrl = post['image_url'] ?? '';

            return ArticleCard(
              key: ValueKey('article_${id}_$imageUrl'),
              post: post,
              currentLocale: currentLocale,
            );
          },
          childCount: results.length,
        ),
      ),
    );
  }

  Widget _buildCategoryButtons(BuildContext context, String activeCategory, Map<String, dynamic> translations, String currentLocale) {
    return Row(
      children: [
        _categoryTab(context, 'people', translations['button_article'] ?? 'Люди', const Color(0xFF00F2FF), activeCategory == 'people', currentLocale),
        const SizedBox(width: 8),
        _categoryTab(context, 'animals', translations['button_sense'] ?? 'Тварини', const Color(0xFFFF8A00), activeCategory == 'animals', currentLocale),
        const SizedBox(width: 8),
        _categoryTab(context, 'things', translations['button_thing'] ?? 'Речі', const Color(0xFF2ECC71), activeCategory == 'things', currentLocale),
      ],
    );
  }

  Widget _categoryTab(BuildContext context, String cat, String label, Color color, bool isActive, String locale) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _localActiveCategory = cat;
            _isAdvancedIdOpen = false;
          });
          context.read<SearchBloc>().add(LoadFilters(category: cat, locale: locale));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B), width: 2),
          ),
          child: Center(
            child: Text(
              label, 
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF1E293B), 
                fontWeight: FontWeight.bold, 
                fontSize: 13, 
                fontFamily: 'Orbitron'
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplyFiltersButton(BuildContext context, Map<String, dynamic> translations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.read<SearchBloc>().add(const PerformSearch()),
        icon: const Icon(Icons.filter_list),
        label: Text(translations['filter_button'] ?? "Застосувати фильтри"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A00).withValues(alpha: 0.1),
          foregroundColor: const Color(0xFFFF8A00),
          side: const BorderSide(color: Color(0xFFFF8A00)),
        ),
      ),
    );
  }

  Widget _buildResetFiltersButton(BuildContext context, String currentLocale, String activeCategory, Map<String, dynamic> translations) {
    return TextButton.icon(
      onPressed: () {
        _chipController.clear();
        _passportController.clear();
        _insuranceController.clear();

        _brandModelController.clear();
        _vinController.clear();
        _licensePlateController.clear();
        _imeiController.clear();
        _serialNumberController.clear();
        _frameNumberController.clear();
        _docTypeController.clear();
        _docNumberController.clear();
        _fullNameController.clear();
        _colorController.clear();
        _hallmarkController.clear();
        _engravingController.clear();
        _keyTypeController.clear();
        _keychainDescController.clear();
        _contentsDescController.clear();
        _additionalInfoController.clear();

        setState(() {
          _searchLat = null;
          _searchLng = null;
          _radiusKm = 5.0;
          _isAdvancedIdOpen = false;
          _isGeoPanelOpen = false;
        });
        context.read<SearchBloc>().add(LoadFilters(category: activeCategory, locale: currentLocale));
      },
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(translations['last'] ?? translations['reset_filters'] ?? "Скинути фильтри"),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF00F2FF)),
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
}

// =============================================================================
// CATEGORY CARD WIDGET
// =============================================================================
class CategoryCard extends StatelessWidget {
  final FindWayCategory category;
  final VoidCallback onTap;

  const CategoryCard({required this.category, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final String path = category.imagePath;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: path.startsWith('http')
              ? NetworkImage(path) as ImageProvider
              : AssetImage(path) as ImageProvider,
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.55), BlendMode.darken),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: category.accentColor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(category.modelsInfo.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'Orbitron')),
                  ]),
                  const SizedBox(height: 8),
                  Text(category.title.toUpperCase(), style: TextStyle(color: category.accentColor, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Orbitron')),
                  const SizedBox(height: 8),
                  Text(category.description, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOM BOTTOM NAVBAR WIDGET
// =============================================================================
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String currentLocale; 
  final Function(int) onTap;
  final Map<String, dynamic> translations;
  final int unreadCount; 

  const CustomBottomNavBar({
    required this.currentIndex, 
    required this.currentLocale, 
    required this.onTap, 
    required this.translations,
    this.unreadCount = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 20), 
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF1E293B), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          LocaleSelector(currentLocale: currentLocale, isInNavBar: true),
          _navItem(1, Icons.search, translations['nav_search'] ?? 'Search'),
          const SizedBox(width: 40), 
          _navItem(3, Icons.mail_outline, translations['nav_messages'] ?? 'Chat', badgeCount: unreadCount),
          _navItem(4, Icons.person_outline, translations['nav_profile'] ?? 'Profile'),
        ],
      ),
    );
  }
  
  Widget _navItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final bool isActive = currentIndex == index;
    final Color activeColor = const Color(0xFFD81B60);
    final Color inactiveColor = const Color(0xFF1E293B);

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(
            label: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
            isLabelVisible: badgeCount > 0,
            backgroundColor: Colors.red,
            child: Icon(
              icon, 
              color: isActive ? activeColor : inactiveColor, 
              size: 24
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label, 
            style: TextStyle(
              color: isActive ? activeColor : inactiveColor, 
              fontSize: 10, 
              fontFamily: 'Orbitron'
            )
          ),
        ],
      ),
    );
  }
}