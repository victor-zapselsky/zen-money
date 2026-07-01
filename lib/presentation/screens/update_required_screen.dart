import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/colors.dart';
import '../../data/services/update_gate_service.dart';

class UpdateRequiredApp extends StatelessWidget {
  final String message;

  const UpdateRequiredApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Копилка',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Text('🐷', style: TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Нужно обновление',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 15, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => launchUrl(
                      Uri.parse(UpdateGateService.rustoreUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: const Text('Обновить'),
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
