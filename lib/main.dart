import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_constants.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await TaskStore.create();
  final themeStore = await ThemeStore.create();
  runApp(MyApp(store: store, themeStore: themeStore));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.store, this.themeStore});

  final TaskStore? store;
  final ThemeStore? themeStore;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider(store: store)),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(store: themeStore),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: appName,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeProvider.mode,
          home: const TodoScreen(),
        ),
      ),
    );
  }
}