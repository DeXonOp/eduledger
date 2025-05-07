import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<Map<String, dynamic>> categories = const [
    {"title": "School", "icon": Icons.school, "color": Colors.blueGrey},
    {"title": "Student", "icon": Icons.person, "color": Colors.deepOrange},
    {"title": "Institution", "icon": Icons.account_balance, "color": Colors.indigo},
    {"title": "Report", "icon": Icons.bar_chart, "color": Colors.green},
  ];

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Exit App"),
        content: const Text("Do you want to exit the application?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clears all saved data

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await _showExitDialog(context);
        if (shouldExit) {
          SystemNavigator.pop(); // Exit the app gracefully
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              bool shouldLogout = await _showLogoutDialog(context);
              if (shouldLogout) {
                await _logout(context); // call updated logout
              }
            },
          ),
          title: Row(
            children: [
              Image.asset('assets/logo.png', height: 30),
              const SizedBox(width: 10),
              const Text('EduLedger'),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: () {
                  themeNotifier.toggleTheme();
                },
                child: Image.asset(
                  themeNotifier.themeMode == ThemeMode.dark
                      ? 'assets/sun.png'
                      : 'assets/moon.png',
                  height: 26,
                  width: 26,
                ),
              ),
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? null
                : const LinearGradient(
              colors: [Color(0xFFB3E5FC), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            color: isDark ? const Color(0xFF1e1f22) : null,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Categories",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                      children: categories.map((category) {
                        return Material(
                          color: category['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            splashColor: category['color'].withOpacity(0.3),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${category['title']} clicked")),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(category['icon'], color: category['color'], size: 40),
                                const SizedBox(height: 10),
                                Text(
                                  category['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: category['color'],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
