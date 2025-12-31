import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/tab_main_provider.dart';
import 'provider/swipe_provider.dart';
import 'provider/tab_history_provider.dart';
import 'router/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabMainProvider()),
        ChangeNotifierProvider(create: (_) => SwipeProvider()),
        ChangeNotifierProvider(create: (_) => TabHistoryProvider()),
      ],
      child: MaterialApp.router(
        title: 'Online Museum',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}