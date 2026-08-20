import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_constants.dart';
import 'providers/task_provider.dart';
import 'screens/todo_screen.dart';
import 'services/task_store.dart';

const _appBarTheme = AppBarTheme(elevation: 0, scrolledUnderElevation: 0);

ThemeData _buildTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: brightness,
  ),
  useMaterial3: true,
  appBarTheme: _appBarTheme,
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.store});

  final TaskStore? store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider(store: store),
      child: MaterialApp(
        title: appName,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const TodoScreen(),
      ),
    );
  }
}
