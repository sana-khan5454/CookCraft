// lib/screens/cooking_time_picker.dart
// ✅ Works on web and mobile
// ✅ Cupertino wheel picker — hours 0-12, minutes in 5-min steps
// ✅ Displays selected time clearly

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CookingTimePicker extends StatefulWidget {
  final String?              initialValue;
  final ValueChanged<String> onChanged;

  const CookingTimePicker({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<CookingTimePicker> createState() => _CookingTimePickerState();
}

class _CookingTimePickerState extends State<CookingTimePicker> {
  int _hours   = 0;
  int _minutes = 30;

  @override
  void initState() {
    super.initState();
    _parse(widget.initialValue);
  }

  void _parse(String? v) {
    if (v == null || v.isEmpty) return;
    final h = RegExp(r'(\d+)\s*hr').firstMatch(v);
    final m = RegExp(r'(\d+)\s*min').firstMatch(v);
    if (h != null) _hours   = int.tryParse(h.group(1)!) ?? 0;
    if (m != null) _minutes = int.tryParse(m.group(1)!) ?? 0;
  }

  String get _label {
    if (_hours == 0 && _minutes == 0) return '5 min';
    if (_hours == 0)   return '$_minutes min';
    if (_minutes == 0) return '$_hours hr';
    return '$_hours hr $_minutes min';
  }

  void _open() {
    int tH = _hours;
    int tM = _minutes;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context:         context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => SizedBox(
          height: 340,
          child: Column(children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cooking Time',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() { _hours = tH; _minutes = tM; });
                      widget.onChanged(_label);
                      Navigator.pop(ctx);
                    },
                    child: Text('Done',
                        style: TextStyle(
                          color:      theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize:   16,
                        )),
                  ),
                ],
              ),
            ),
            // Current selection display
            Text(
              tH == 0 && tM == 0 ? '—'
                  : tH == 0 ? '$tM min'
                  : tM == 0 ? '$tH hr'
                  : '$tH hr $tM min',
              style: TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.bold,
                color:      theme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            // Wheels
            Expanded(
              child: Row(children: [
                // Hours
                Expanded(child: Column(children: [
                  Text('Hours',
                      style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12)),
                  Expanded(child: CupertinoPicker(
                    scrollController:
                    FixedExtentScrollController(initialItem: tH),
                    itemExtent: 44,
                    onSelectedItemChanged: (i) {
                      tH = i;
                      setInner(() {});
                    },
                    children: List.generate(13, (i) => Center(
                      child: Text('$i hr',
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 18)),
                    )),
                  )),
                ])),
                // Minutes (5-min steps)
                Expanded(child: Column(children: [
                  Text('Minutes',
                      style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12)),
                  Expanded(child: CupertinoPicker(
                    scrollController:
                    FixedExtentScrollController(initialItem: tM ~/ 5),
                    itemExtent: 44,
                    onSelectedItemChanged: (i) {
                      tM = i * 5;
                      setInner(() {});
                    },
                    children: List.generate(12, (i) => Center(
                      child: Text('${i * 5} min',
                          style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 18)),
                    )),
                  )),
                ])),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final hasValue = _hours > 0 || _minutes > 0;

    return GestureDetector(
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color:        theme.cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          Icon(Icons.timer_outlined, color: theme.primaryColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cooking Time',
                    style: TextStyle(
                      fontSize: 12,
                      color:    theme.textTheme.bodySmall?.color,
                    )),
                const SizedBox(height: 2),
                Text(
                  hasValue ? _label : 'Tap to set',
                  style: TextStyle(
                    fontSize:   15,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                    color: hasValue
                        ? theme.textTheme.bodyMedium?.color
                        : theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: theme.iconTheme.color),
        ]),
      ),
    );
  }
}