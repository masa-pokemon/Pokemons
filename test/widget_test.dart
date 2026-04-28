
// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:flutter_blockly/flutter_blockly.dart';

void main() {
  testWidgets('3D Game Editor App builds and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PokemonApp());
  });
}
