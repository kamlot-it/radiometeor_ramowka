import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'config/theme_config.dart';
import 'config/app_config.dart';
import 'core/errors/error_handler.dart';
import 'presentation/providers/schedule_provider.dart';
import 'presentation/screens/schedule_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorHandler.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ScheduleProvider(),
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.lightTheme,
        darkTheme: ThemeConfig.darkTheme,
        themeMode: ThemeMode.system,
        home: const ScheduleScreen(),
        builder: (context, widget) {
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            return ErrorHandler.buildErrorWidget(errorDetails);
          };
          return widget!;
        },
      ),
    );
  }
}
