import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'bloc/auth/auth_bloc.dart';
import 'config/app_theme.dart';
import 'screens/auth_screen.dart';
import 'services/nakama_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'env.config');
  } catch (_) {
    debugPrint('env.config not found, using default values');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          theme: buildAppTheme(),
          home: const AuthScreen(),
        ),
      ),
    );
  }
}
