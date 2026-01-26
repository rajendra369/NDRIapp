import 'package:flutter/material.dart';
import 'main_container_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;

  void _handleLogin() {
    // Navigate to the main app
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainContainerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use a LayoutBuilder to make it responsive if needed, but for now we'll optimize for tablet/desktop per the sketch
    // The sketch shows a card-like interface with two columns.
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                  maxHeight: 600,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT SIDE - USER LOGIN
                      Expanded(
                        flex: 5, // Slightly larger for the image
                        child: Column(
                          children: [
                            // Header Image
                            SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: Image.asset(
                                'assets/images/login_header.png', // Ensure this matches your asset path
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.blue[100],
                                      child: const Icon(
                                        Icons.image,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTextField(
                                    label: 'Username',
                                    icon: Icons.person_outline,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    label: 'Password',
                                    icon: Icons.key,
                                    obscureText: true,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    label: 'PP.',
                                    icon: Icons.description_outlined,
                                  ), // PP field from sketch
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: 0.9,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: const Color(
                                            0xFF4FA07B,
                                          ), // Greenish color from sketch
                                          onChanged: (val) => setState(
                                            () => _rememberMe = val!,
                                          ),
                                        ),
                                      ),
                                      const Text('Remember me'),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF5D8E6F,
                                        ), // Muted green from sketch
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onPressed: _handleLogin,
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Icon(
                                    Icons.home_outlined,
                                    size: 30,
                                    color: Colors.black54,
                                  ), // Home icon at bottom left
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // VERTICAL DIVIDER
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Colors.grey,
                      ),

                      // RIGHT SIDE - ADMIN LOGIN
                      Expanded(
                        flex: 4,
                        child: Container(
                          color: Colors.grey[50],
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 20),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_outline, size: 28),
                                  SizedBox(width: 8),
                                  Text(
                                    'Admin Login',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(
                                thickness: 1.5,
                                color: Colors.black87,
                              ),
                              const SizedBox(height: 30),

                              // Admin Fields
                              _buildTextField(
                                label: 'Username',
                                icon: Icons.person_outline,
                                isDense: true,
                              ),
                              const SizedBox(height: 12),
                              // Sketch shows two Usernames? I'll assume one is Role or maybe just a redundancy in sketch.
                              // I'll add a second one just to match sketch visual if needed, but functionally weird.
                              // Let's stick to standard Username/Password unless user specified otherwise.
                              // Actually, looking at the sketch closely, the top right box has "Admin Login" then "Username", "Username", "Password".
                              // Maybe "Organization" and "Username"? Or "Role"? I'll put a second generic field for now to match structure, maybe "Role/ID".
                              // Or simply stick to Username/Password for functionality. I'll stick to 2 fields: Username, Password.
                              // Wait, the sketch CLEARLY has 3 input boxes on the right.
                              // 1. Person Icon - Username
                              // 2. Person Icon - Username (Maybe one is Name, one is ID?)
                              // 3. Key Icon - Password
                              // I will implement 3 fields to match the visual 100%.
                              _buildTextField(
                                label: 'Username',
                                icon: Icons.person_outline,
                                isDense: true,
                              ),
                              const SizedBox(height: 12),
                              _buildTextField(
                                label: 'Password',
                                icon: Icons.key,
                                obscureText: true,
                                isDense: true,
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFF5D8E6F,
                                    ), // Muted green
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _handleLogin,
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Database Icon at bottom right
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'DATABASE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Icon(
                                      Icons.storage,
                                      size: 40,
                                      color: Colors.grey[700],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool isDense = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[400]!),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ), // Reduced vertical padding
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              obscureText: obscureText,
              decoration: InputDecoration(
                hintText: label,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                ), // Center text vertically
                fillColor: Colors.transparent,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
