import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/colors.dart';
import '../../widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      emoji: '💸',
      title: 'Контролируй\nсвои расходы',
      subtitle: 'Фиксируй каждую трату и всегда знай,\nкуда уходят деньги',
    ),
    _PageData(
      emoji: '🎯',
      title: 'Ставь цели\nи достигай их',
      subtitle: 'Создавай финансовые цели и откладывай\nна мечту шаг за шагом',
    ),
    _PageData(
      emoji: '📊',
      title: 'Анализируй\nсвои финансы',
      subtitle: 'Смотри отчёты, следи за бюджетом\nи принимай умные решения',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);
    if (mounted) context.go('/journal');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_page < 2)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () => _controller.animateToPage(2,
                        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: const Text('Пропустить',
                        style: TextStyle(color: AppColors.inkSoft, fontSize: 14)),
                  ),
                ),
              )
            else
              const SizedBox(height: 56),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primary : AppColors.lineColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // CTA buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _page < 2
                  ? AppButton(
                      label: 'Далее →',
                      onTap: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    )
                  : Column(
                      children: [
                        AppButton(label: 'Создать аккаунт', onTap: () => context.push('/register')),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Уже есть аккаунт',
                          outlined: true,
                          onTap: () => context.push('/login'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _finish,
                          child: const Text('Продолжить без входа',
                              style: TextStyle(color: AppColors.inkSoft)),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PageData {
  final String emoji;
  final String title;
  final String subtitle;
  const _PageData({required this.emoji, required this.title, required this.subtitle});
}

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              color: AppColors.primaryGhost,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(data.emoji, style: const TextStyle(fontSize: 72)),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.25),
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.inkSoft, height: 1.5),
          ),
        ],
      ),
    );
  }
}
