import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_product_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Product Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthGate(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/addProduct': (context) => AddProductScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  Future<bool> isLoggedIn() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.data == true) {
          return HomeScreen();
        }
        return LoginScreen();
      },
    );
  }
}
