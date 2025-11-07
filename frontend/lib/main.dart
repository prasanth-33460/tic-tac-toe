import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth/auth_bloc.dart';
import 'screens/auth_screen.dart';
import 'services/nakama_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Tic Tac Toe App - Initializing...');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  debugPrint('Device orientation set to portrait only');

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  debugPrint('System UI mode set to immersive sticky');

  runApp(const MyApp());
  debugPrint('App started successfully');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<NakamaService>(create: (_) => NakamaService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(context.read<NakamaService>()),
          ),
        ],
        child: MaterialApp(
          title: 'Tic Tac Toe',
          debugShowCheckedModeBanner: false,

          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F1419),
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF00D4FF),
              secondary: const Color(0xFF00D4FF),
              surface: const Color(0xFF1A1F27),
              background: const Color(0xFF0F1419),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A1F27),
              elevation: 0,
              centerTitle: true,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1A1F27),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),

          home: const AuthScreen(),
        ),
      ),
    );
  }
}
