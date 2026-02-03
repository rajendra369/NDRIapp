import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../../core/widgets/glass_container.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../data/datasources/auth_service.dart';
import '../../../dashboard/domain/entities/station_mapping.dart';
import '../../../dashboard/presentation/screens/main_container_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Login controllers
  String? _selectedCollector;
  final TextEditingController _passwordController = TextEditingController();
  bool _passwordVisible = false;

  // Animation controllers
  late AnimationController _waveController;
  late AnimationController _dropController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _waveController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) {
    if (_selectedCollector == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a collector')),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthLoginRequested(
        collector: _selectedCollector!,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainContainerScreen(),
            ),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: Stack(
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A237E), // Deep blue
                      Color(0xFF0D47A1), // Blue
                      Color(0xFF01579B), // Light blue
                      Color(0xFF006064), // Teal
                    ],
                  ),
                ),
              ),

              // Animated water waves at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 200),
                      painter: WavePainter(_waveController.value),
                    );
                  },
                ),
              ),

              // Rain drops animation
              ...List.generate(15, (index) => _buildRainDrop(index)),

              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // App Logo and Title
                        _buildHeader(),

                        const SizedBox(height: 24),

                        // Map Preview Card
                        _buildMapPreview(),

                        const SizedBox(height: 24),

                        // Login Card
                        const SizedBox(height: 12),
                        GlassContainer(
                          padding: const EdgeInsets.all(24),
                          child: _buildLoginCard(context, isLoading),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRainDrop(int index) {
    final random = Random(index);
    final startX = random.nextDouble() * 400;
    final delay = random.nextDouble();

    return AnimatedBuilder(
      animation: _dropController,
      builder: (context, child) {
        final progress = (_dropController.value + delay) % 1.0;
        return Positioned(
          left: startX,
          top: progress * MediaQuery.of(context).size.height * 0.7,
          child: Opacity(
            opacity: 0.3 + (random.nextDouble() * 0.3),
            child: Container(
              width: 2,
              height: 15 + random.nextDouble() * 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.6),
                    Colors.cyan.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated water drop icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
            border: Border.all(color: Colors.white30, width: 2),
          ),
          child: const Icon(Icons.water_drop, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'HMO APP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hydrological Monitoring System',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.cyan.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Colors.white70, size: 14),
              SizedBox(width: 4),
              Text(
                'Sindhuli District, Nepal',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview() {
    final stationMarkers = StationMapping.coordinates.entries.map((entry) {
      final stationId = entry.key;
      final coords = entry.value;
      final stationType = StationMapping.getStationType(stationId);
      final isSpring = stationType == 'Spring';

      // Get station code
      String stationCode;
      if (isSpring) {
        stationCode = stationId.replaceAll('Flow_', '');
      } else {
        final code = stationId.replaceAll('Index_', '');
        stationCode = 'M-${code.substring(code.length - 3)}';
      }

      return Marker(
        point: LatLng(coords[0], coords[1]),
        width: 60,
        height: 40,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSpring ? Colors.blue : Colors.orange,
                  width: 2,
                ),
              ),
              child: Icon(
                isSpring ? Icons.waves : Icons.water_drop,
                color: isSpring ? Colors.blue : Colors.orange,
                size: 12,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: isSpring ? Colors.blue[700] : Colors.orange[700],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                stationCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(27.30, 85.90),
              initialZoom: 9.5,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'org.ndri.muhan',
              ),
              MarkerLayer(markers: stationMarkers),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _buildLegendChip(Icons.waves, Colors.blue, 'Springs (7)'),
                  const SizedBox(width: 8),
                  _buildLegendChip(Icons.water_drop, Colors.orange, 'Rain (4)'),
                  const Spacer(),
                  Text(
                    '11 Stations',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.login, color: Color(0xFF0D47A1)),
            SizedBox(width: 8),
            Text(
              'Data Collector Login',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Collector Dropdown
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF0D47A1)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCollector,
                    hint: const Text('Select Collector'),
                    isExpanded: true,
                    items: AuthService().collectors.map((collector) {
                      return DropdownMenuItem(
                        value: collector,
                        child: Text(collector),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCollector = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Password Field
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.lock, color: Color(0xFF0D47A1)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() => _passwordVisible = !_passwordVisible);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Login Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            onPressed: isLoading ? null : () => _handleLogin(context),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.water_drop),
                      SizedBox(width: 8),
                      Text(
                        'Start Monitoring',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final opacity = 0.15 + (i * 0.1);
      final amplitude = 20.0 - (i * 5);
      final speed = 1 + (i * 0.5);
      final yOffset = i * 30.0;

      paint.color = Colors.cyan.withValues(alpha: opacity);

      final path = Path();
      path.moveTo(0, size.height);

      for (double x = 0; x <= size.width; x++) {
        final y =
            size.height -
            80 +
            yOffset +
            sin((x / size.width * 2 * pi) + (animationValue * 2 * pi * speed)) *
                amplitude +
            sin(
                  (x / size.width * 4 * pi) +
                      (animationValue * 2 * pi * speed * 0.5),
                ) *
                (amplitude / 2);
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
