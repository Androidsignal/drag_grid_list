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

/// Deterministic varying tile height, so the masonry demo actually staggers
/// instead of laying out as an even grid.
///
/// Keyed by the card's own id, not its current list position — a card's
/// height must stay put across a reorder, otherwise unrelated cards
/// visibly resize every time *any* card is dragged.
double demoMasonryHeight(DemoCard card) =>
    90.0 + (card.id.hashCode.abs() * 47) % 140;
