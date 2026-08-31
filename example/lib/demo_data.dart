import 'package:flutter/material.dart';

/// Simple demo payload used across the example pages.
class DemoCard {
  const DemoCard({required this.id, required this.title, required this.color});

  final String id;
  final String title;
  final Color color;
}

final List<Color> demoColors = [
  Colors.red,
  Colors.orange,
  Colors.amber,
  Colors.green,
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.pink,
  Colors.brown,
];

List<DemoCard> generateDemoCards(int count, {String prefix = 'Card'}) {
  return List.generate(
    count,
    (i) => DemoCard(
      id: '$prefix-$i',
      title: '$prefix ${i + 1}',
      color: demoColors[i % demoColors.length],
    ),
  );
}
