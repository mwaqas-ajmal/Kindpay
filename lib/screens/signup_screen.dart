import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'signup_otp_screen.dart';
import '../theme/app_theme.dart';
import '../utils/glass_card.dart';
import '../utils/gradient_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
  });

  @override
  State<SignupScreen> createState() =>
      _SignupScreenState();
}

class _SignupScreenState
    extends State<SignupScreen> {
  TextEditingController username =
      TextEditingController();

  TextEditingController email =
      TextEditingController();

  TextEditingController password =
      TextEditingController();

  TextEditingController phone =
      TextEditingController();

  TextEditingController address =
      TextEditingController();

  String role = "user";

  PlatformFile? certificateFile;

  bool loading = false;

  bool obscure = true;

  double latitude = 0.0;

  double longitude = 0.0;

  bool locationLoading = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(milliseconds: 600),
      () {
        getCurrentLocation();
      },
    );
  }

  // =====================================================
  // 📍 GET LOCATION
  // =====================================================

  Future<bool> getCurrentLocation() async {
    try {
      setState(() {
        locationLoading = true;
      });

      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Please turn ON mobile location/GPS",
              ),
            ),
          );
        }

        await Geolocator.openLocationSettings();

        setState(() {
          locationLoading = false;
        });

        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Location permission denied",
              ),
            ),
          );
        }

        setState(() {
          locationLoading = false;
        });

        return false;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Location permission permanently denied. Enable it from app settings.",
              ),
            ),
          );
        }

        await Geolocator.openAppSettings();

        setState(() {
          locationLoading = false;
        });

        return false;
      }

      Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(
          seconds: 15,
        ),
      );

      latitude = position.latitude;
      longitude = position.longitude;

      print("LAT = $latitude");
      print("LONG = $longitude");

      setState(() {
        locationLoading = false;
      });

      if (latitude == 0.0 ||
          longitude == 0.0) {
        return false;
      }

      return true;
    } catch (e) {
      print("LOCATION ERROR => $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Location error: $e",
            ),
          ),
        );
      }

      setState(() {
        locationLoading = false;
      });

      return false;
    }
  }

  // =====================================================
  // 📁 PICK FILE
  // =====================================================

  Future<void> pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result != null) {
      setState(() {
        certificateFile =
            result.files.first;
      });
    }
  }

  // =====================================================
  // 🚀 SIGNUP
  // =====================================================

  Future<void> signup() async {
    if (username.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.trim().isEmpty ||
        phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Fill all required fields",
          ),
        ),
      );

      return;
    }

    if (role == "ngo" &&
        address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Enter NGO address",
          ),
        ),
      );

      return;
    }

    if (role == "ngo" &&
        certificateFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Upload NGO certificate",
          ),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    bool locationOk =
        await getCurrentLocation();

    if (role == "ngo" &&
        locationOk == false) {
      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "NGO location is required for map",
          ),
        ),
      );

      return;
    }

    try {
      var signupData = {
        "username":
            username.text.trim(),

        "email":
            email.text.trim(),

        "password":
            password.text.trim(),

        "phone":
            phone.text.trim(),

        "role":
            role,

        "address":
            address.text.trim(),

        "latitude":
            latitude.toString(),

        "longitude":
            longitude.toString(),

        "certificateBytes":
            certificateFile?.bytes,

        "certificateName":
            certificateFile?.name,
      };

      var otpRes =
          await ApiService.sendSignupOtp(
        email.text.trim(),
      );

      if (otpRes['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              otpRes['message'].toString(),
            ),
          ),
        );

        if (!mounted) {
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SignupOtpScreen(
              signupData: signupData,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              otpRes['message'].toString(),
            ),
          ),
        );
      }
    } catch (e) {
      print("SIGNUP ERROR => $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Network error",
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  // =====================================================
  // 🔥 UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 🌟 MODERN BACKGROUND ACCENTS
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondary.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
              child: GlassCard(
                opacity: 0.05,
                blur: 20,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.2),
                            AppTheme.secondary.withOpacity(0.2),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        size: 64,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      "Create Account",
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      "Join KindPay Community",
                      style: GoogleFonts.outfit(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // FIELDS
                    TextField(
                      controller: username,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Username",
                        prefixIcon: const Icon(Icons.person_outline, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: email,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Email",
                        prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: password,
                      obscureText: obscure,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              obscure = !obscure;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: phone,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Phone",
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ROLE DROPDOWN
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2836),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: AppTheme.cardColor,
                          value: role,
                          isExpanded: true,
                          style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 16),
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                          items: const [
                            DropdownMenuItem(
                              value: "user",
                              child: Text("Regular User"),
                            ),
                            DropdownMenuItem(
                              value: "ngo",
                              child: Text("NGO / Charity"),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              role = val!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // NGO FIELDS
                    if (role == "ngo") ...[
                      TextField(
                        controller: address,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: "NGO Address",
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2836),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.upload_file_outlined, color: AppTheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  certificateFile == null
                                      ? "Upload NGO Certificate"
                                      : certificateFile!.name,
                                  style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Icon(
                            latitude != 0.0 && longitude != 0.0
                                ? Icons.location_on
                                : Icons.location_off_outlined,
                            color: latitude != 0.0 && longitude != 0.0
                                ? AppTheme.secondary
                                : AppTheme.danger,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationLoading
                                  ? "Getting location..."
                                  : latitude != 0.0 && longitude != 0.0
                                      ? "Location captured successfully"
                                      : "Location required for NGO map",
                              style: GoogleFonts.outfit(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: getCurrentLocation,
                            child: Text(
                              "Retry",
                              style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (latitude != 0.0 && longitude != 0.0)
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(latitude, longitude),
                                initialZoom: 15,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.kindpay',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(latitude, longitude),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (latitude != 0.0 && longitude != 0.0)
                        const SizedBox(height: 16),


                      Text(
                        "⏳ NGO verification may take up to 24 hours.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    // 🔥 SIGNUP BUTTON
                    GradientButton(
                      text: "CREATE ACCOUNT",
                      onPressed: loading ? null : signup,
                      isLoading: loading,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: Text(
                            "Login",
                            style: GoogleFonts.outfit(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}