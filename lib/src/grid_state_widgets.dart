import 'package:flutter/material.dart';

/// Default `loadingBuilder`: a centered spinner.
Widget defaultDragLoadingBuilder(BuildContext context) {
  return const Center(child: CircularProgressIndicator());
}

/// Default `emptyBuilder`: a centered "No items" message.
Widget defaultDragEmptyBuilder(BuildContext context) {
  final style = Theme.of(context).textTheme.bodyMedium
      ?.copyWith(color: Theme.of(context).colorScheme.outline);
  return Center(child: Text('No items', style: style));
}
