import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';

import 'screens/login_screen.dart';

import 'screens/user/user_dashboard.dart';

import 'screens/ngo/ngo_dashboard.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // =====================================================
  // STRIPE
  // =====================================================

  if (!kIsWeb) {

    Stripe.publishableKey =

    "pk_test_51TZlcgKGiNBNBr9TtI4kmRL2ld1bcRIyljyHHCfiTphIIIlMAMxjx7oWK98tgQemduDFnkvMeejm1RDLcFuMC81Q00ZXyyVp8s";

    await Stripe.instance.applySettings();
  }

  // =====================================================
  // CHECK LOGIN
  // =====================================================

  SharedPreferences prefs =

  await SharedPreferences.getInstance();

  bool isLoggedIn =

  prefs.getBool("isLoggedIn") ?? false;

  String role =
  prefs.getString("role") ?? "";

  Map<String,dynamic> userData = {

    "id":
    prefs.getString("id") ?? "",

    "username":
    prefs.getString("username") ?? "",

    "email":
    prefs.getString("email") ?? "",

    "phone":
    prefs.getString("phone") ?? "",

    "role":
    prefs.getString("role") ?? "",

    "address":
    prefs.getString("address") ?? "",
  };

  Widget startScreen;

  if(isLoggedIn){

    if(role == "ngo"){

      startScreen = NgoDashboard(

        userData: userData,

        status:
        prefs.getString("status")
            ?? "pending",
      );

    }else{

      startScreen = UserDashboard(
        userData: userData,
      );
    }

  }else{

    startScreen =
    const LoginScreen();
  }

  runApp(MyApp(
    startScreen: startScreen,
  ));
}

class MyApp extends StatelessWidget {

  final Widget startScreen;

  const MyApp({

    super.key,

    required this.startScreen,
  });

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: "KindPay",

      theme: AppTheme.lightTheme,

      darkTheme: AppTheme.darkTheme,

      themeMode: ThemeMode.light,

      home: startScreen,
    );
  }
}