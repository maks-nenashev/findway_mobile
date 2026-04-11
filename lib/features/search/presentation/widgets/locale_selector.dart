import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';

class LocaleSelector extends StatelessWidget {
  final String currentLocale;
  final bool isInNavBar; 

  const LocaleSelector({required this.currentLocale, this.isInNavBar = false, super.key});

  static const Map<String, List<String>> _groupedLocales = {
    "Europe": ["en", "uk", "pl", "nl", "be", "de", "fr", "it", "es", "pt", "cs", "sk", "ro"],
    "North America": ["ca", "us", "mx"],
  };

  static const Map<String, String> _fullNames = {
    "uk": "Ukraine (UA)", "en": "United Kingdom (EN)", "pl": "Poland (PL)",
    "nl": "Netherlands (NL)", "be": "Belgium", "de": "Germany (DE)",
    "fr": "France (FR)", "it": "Italy (IT)", "es": "Spain (ES)",
    "pt": "Portugal (PT)", "cs": "Czech Republic (CZ)", "sk": "Slovakia (SK)",
    "ro": "Romania (RO)", "ca": "Canada (CA)", "us": "USA (US)",
    "mx": "Mexico (MX)", "be_nl": "Flanders – NL", "be_fr": "Wallonia – FR",
    "be_de": "Eupen – DE"
  };

  String _getFlag(String code) {
    if (code.isEmpty) return "🌐";
    String countryCode = code.split('_')[0].toLowerCase();
    if (countryCode == 'en') countryCode = 'gb';
    if (countryCode == 'uk') countryCode = 'ua';
    return countryCode.toUpperCase().characters.map((char) => String.fromCharCode(char.codeUnitAt(0) + 127397)).join();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLanguagePicker(context),
      child: Column( 
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getFlag(currentLocale), style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            currentLocale.toUpperCase(),
            style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'Orbitron'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final searchBloc = context.read<SearchBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E14),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return BlocProvider.value(
          value: searchBloc,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ListView(
              shrinkWrap: true,
              children: _groupedLocales.entries.map((entry) {
                return ExpansionTile(
                  title: Text(entry.key, style: const TextStyle(color: Color(0xFF00F2FF), fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                  children: entry.value.map((locale) {
                    // ✅ ЛОГИКА ВЕТВЛЕНИЯ ДЛЯ БЕЛЬГИИ
                    if (locale == 'be') {
                      return _buildBelgiumSubTile(context, searchBloc);
                    }
                    
                    return ListTile(
                      leading: Text(_getFlag(locale), style: const TextStyle(fontSize: 22)),
                      title: Text(_fullNames[locale] ?? locale.toUpperCase(), style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        searchBloc.add(ChangeLocale(locale));
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ========== БЕЛЬГИЙСКИЙ ПОДМОДУЛЬ ==========

  Widget _buildBelgiumSubTile(BuildContext context, SearchBloc bloc) {
    return ExpansionTile(
      leading: Text(_getFlag('be'), style: const TextStyle(fontSize: 20)),
      title: const Padding(
        padding: EdgeInsets.only(left: 16.0),
        child: Text("Belgium", style: TextStyle(color: Colors.white70, fontSize: 18)),
      ),
      children: [
        _buildSubItem(context, bloc, 'be_nl'),
        _buildSubItem(context, bloc, 'be_fr'),
        _buildSubItem(context, bloc, 'be_de'),
      ],
    );
  }

  Widget _buildSubItem(BuildContext context, SearchBloc bloc, String code) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48),
      leading: Text(_getFlag(code), style: const TextStyle(fontSize: 18)),
      title: Text(
        _fullNames[code] ?? code.toUpperCase(),
        style: const TextStyle(color: Colors.white60, fontSize: 18),
      ),
      onTap: () {
        bloc.add(ChangeLocale(code));
        Navigator.pop(context);
      },
    );
  }
}