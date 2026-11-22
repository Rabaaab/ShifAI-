import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/morocco_cities.dart';
import '../providers/settings_provider.dart';
import '../theme/ds.dart';
import 'ds_widgets.dart';

/// Bottom sheet to choose the city used to look for doctors.
Future<void> pickCity(BuildContext context) async {
  final settings = context.read<SettingsProvider>();
  final chosen = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DS.bgTop,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => _CitySheet(selected: settings.city),
  );
  if (chosen != null) await settings.setCity(chosen);
}

class _CitySheet extends StatefulWidget {
  const _CitySheet({required this.selected});
  final String? selected;

  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final cities = moroccoCities
        .where((c) => c.toLowerCase().contains(_query.trim().toLowerCase()))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          22,
          24,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your city'.tr,
                style: DS.text(size: 24, weight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              TextField(
                autofocus: false,
                style: DS.text(weight: FontWeight.w600),
                onChanged: (v) => setState(() => _query = v),
                decoration: dsFieldDecoration(
                  hint: 'Search a city'.tr,
                  vertical: 16,
                  prefix: const Icon(Icons.search_rounded, color: DS.iconMuted),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: cities.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'No city found.'.tr,
                          style: DS.text(color: DS.muted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: cities.length,
                        itemBuilder: (context, i) {
                          final c = cities[i];
                          final selected = c == widget.selected;
                          return Semantics(
                            button: true,
                            selected: selected,
                            label: c,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.pop(context, c),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 52,
                                ),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c,
                                        style: DS.text(
                                          size: 16.5,
                                          weight: selected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: selected ? DS.navy : DS.ink,
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_rounded,
                                        color: DS.navy,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
