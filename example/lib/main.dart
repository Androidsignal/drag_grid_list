import 'package:drag_grid_list/drag_grid_list.dart';
import 'package:flutter/material.dart';

import 'demo_data.dart';

void main() {
  runApp(const DragGridListExampleApp());
}

class DragGridListExampleApp extends StatelessWidget {
  const DragGridListExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'drag_grid_list example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  List<DemoCard> _listItems = generateDemoCards(10);
  List<DemoCard> _gridItems = generateDemoCards(20);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('drag_grid_list'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.view_list), text: 'List'),
              Tab(icon: Icon(Icons.grid_view), text: 'Grid'),
            ],
          ),
        ),
        body: Column(
          children: [
            const _DragHint(),
            Expanded(
              child: TabBarView(
                children: [
                  DragGridList<DemoCard>.builder(
                    items: _listItems,
                    keyOf: (card) => ValueKey(card.id),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemSpacing: 10,
                    itemExtent: 72,
                    longPressDelay: const Duration(milliseconds: 150),
                    onItemsChanged: (items) => setState(() => _listItems = items),
                    itemBuilder: (context, card, index) => _ListTile(card: card, index: index),
                  ),
                  DragGridList<DemoCard>.builder(
                    items: _gridItems,
                    layout: DragListLayout.grid,
                    keyOf: (card) => ValueKey(card.id),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    minColumnWidth: 120,
                    itemSpacing: 10,
                    rowSpacing: 10,
                    childAspectRatio: 1,
                    longPressDelay: const Duration(milliseconds: 150),
                    onItemsChanged: (items) => setState(() => _gridItems = items),
                    itemBuilder: (context, card, index) => _GridTile(card: card),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slim, dismiss-free hint banner nudging first-time users toward the
/// long-press-to-drag gesture.
class _DragHint extends StatelessWidget {
  const _DragHint();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, size: 18, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Long-press an item, then drag to reorder',
              style: TextStyle(fontSize: 13, color: colorScheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({required this.card, required this.index});

  final DemoCard card;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(backgroundColor: card.color, foregroundColor: Colors.white, child: Text('${index + 1}')),
        title: Text(card.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(card.id),
        trailing: Icon(Icons.drag_handle, color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile({required this.card});

  final DemoCard card;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [card.color, card.color.withValues(alpha: 0.7)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: 6, right: 6, child: Icon(Icons.open_with, size: 16, color: Colors.white70)),
            Center(
              child: Text(
                card.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
