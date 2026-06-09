import 'package:flutter/material.dart';

import '../../core/theme/mono_palette.dart';

/// 区块标题：页面内分段标题，统一居中样式。
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final mono = MonoTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.03,
                color: mono.textPrimary,
              ),
        ),
      ),
    );
  }
}
