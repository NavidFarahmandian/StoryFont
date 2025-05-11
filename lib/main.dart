import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:storyfont/viewmodels/auth_viewmodel.dart';
import 'package:storyfont/viewmodels/task_viewmodel.dart';
import 'package:storyfont/views/auth_page.dart';
import 'package:storyfont/views/task_list_page.dart';
import 'firebase_options.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, _) {
        return ChangeNotifierProvider(
          create: (_) => AuthViewModel(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Task Manager',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
              textTheme: GoogleFonts.poppinsTextTheme(),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
              textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: Colors.white),
              useMaterial3: true,
            ),
            themeMode: currentTheme,
            home: StreamBuilder(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasData) {
                  return ChangeNotifierProvider(
                    create: (_) => TaskViewModel()..loadTasks(),
                    child: const TaskListPage(),
                  );
                } else {
                  return const AuthPage();
                }
              },
            ),
          ),
        );
      },
    );
  }

}
