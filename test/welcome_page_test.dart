import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup_tracker/features/splash/welcome_page.dart';

void main() {
  const homeKey = Key('home-page');
  const startButtonKey = Key('welcome-start-button');

  testWidgets('fades entire welcome overlay into home page', (tester) async {
    var mountCount = 0;

    await tester.pumpWidget(
      WelcomePage(
        child: _MountTracker(key: homeKey, onMount: () => mountCount++),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('FFWC2026'), findsOneWidget);
    expect(_homeIsBlocked(homeKey), isTrue);
    expect(mountCount, 1);

    await tester.tap(find.byKey(startButtonKey));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('FFWC2026'), findsNothing);
    expect(_homeIsBlocked(homeKey), isFalse);
    expect(mountCount, 1);
  });
}

bool _homeIsBlocked(Key homeKey) {
  final element = find
      .ancestor(
        of: find.byKey(homeKey),
        matching: find.byType(IgnorePointer),
      )
      .evaluate()
      .single;
  return (element.widget as IgnorePointer).ignoring;
}

class _MountTracker extends StatefulWidget {
  const _MountTracker({super.key, required this.onMount});

  final VoidCallback onMount;

  @override
  State<_MountTracker> createState() => _MountTrackerState();
}

class _MountTrackerState extends State<_MountTracker> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
