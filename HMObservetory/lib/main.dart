import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/data/datasources/auth_service.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_event.dart';
import 'features/dashboard/data/datasources/map_service.dart';

import 'features/dashboard/presentation/bloc/records_bloc.dart';
import 'features/dashboard/presentation/bloc/records_event.dart';
import 'features/dashboard/data/datasources/firestore_service.dart';
import 'features/dashboard/presentation/bloc/collectors_bloc.dart';
import 'features/dashboard/presentation/bloc/collectors_event.dart';
import 'features/settings/presentation/bloc/import_bloc.dart';
import 'features/settings/data/datasources/data_import_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = AuthService();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(authService: authService)..add(AuthStarted()),
        ),
        BlocProvider(
          create: (context) =>
              DashboardBloc(mapService: MapService())
                ..add(DashboardDataRequested()),
        ),
        BlocProvider(
          create: (context) =>
              RecordsBloc(firestoreService: firestoreService)
                ..add(RecordsFetchRequested()),
        ),
        BlocProvider(
          create: (context) =>
              CollectorsBloc(firestoreService: firestoreService)
                ..add(CollectorsFetchRequested()),
        ),
        BlocProvider(
          create: (context) => ImportBloc(importService: DataImportService()),
        ),
      ],
      child: MaterialApp(
        title: 'Meteoflow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
