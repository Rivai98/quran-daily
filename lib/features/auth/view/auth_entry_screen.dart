import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../core/localization/arabic_strings.dart';

class AuthEntryScreen extends StatelessWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.auto_stories,
                      size: 72, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    ArabicStrings.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ArabicStrings.signInHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, AppRoutes.groups),
                    icon: const Icon(Icons.login),
                    label: const Text(ArabicStrings.signInWithGoogle),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ArabicStrings.signInError,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
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
