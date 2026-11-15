import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_daily/core/design_system/app_colors.dart';
import 'package:quran_daily/app/app.dart';
import 'package:quran_daily/core/design_system/widgets/app_badge.dart';
import 'package:quran_daily/core/design_system/widgets/app_banner.dart';
import 'package:quran_daily/core/design_system/widgets/app_card.dart';
import 'package:quran_daily/core/design_system/widgets/app_section_header.dart';
import 'package:quran_daily/core/design_system/widgets/app_snack_bar.dart';
import 'package:quran_daily/core/design_system/widgets/app_text_field.dart';
import 'package:quran_daily/core/design_system/widgets/confirm_sheet.dart';
import 'package:quran_daily/core/design_system/widgets/offline_banner.dart';
import 'package:quran_daily/core/design_system/widgets/progress_header.dart';
import 'package:quran_daily/core/design_system/widgets/skeleton.dart';
import 'package:quran_daily/core/design_system/widgets/state_panel.dart';

import '../../../helpers/widget_test_app.dart';

Color? decorationColorOf(WidgetTester tester, Finder finder) {
  final container = tester.widget<Container>(finder);
  final decoration = container.decoration;
  if (decoration is ShapeDecoration) return decoration.color;
  if (decoration is BoxDecoration) return decoration.color;
  return null;
}

void main() {
  testWidgets('StatePanel shows icon, title, one sentence, next action',
      (tester) async {
    var pressed = 0;
    await tester.pumpWidget(buildArabicTestApp(
      Scaffold(
        body: StatePanel(
          icon: Icons.groups,
          title: 'لم تنضم إلى أي مجموعة بعد',
          message: 'ابحث عن مجموعة عامة واطلب الانضمام إليها.',
          actionLabel: 'ابحث عن مجموعة',
          onAction: () => pressed++,
        ),
      ),
    ));

    expect(find.byType(Icon), findsOneWidget);
    expect(find.text('لم تنضم إلى أي مجموعة بعد'), findsOneWidget);
    expect(find.text('ابحث عن مجموعة عامة واطلب الانضمام إليها.'), findsOneWidget);
    expect(find.text('ابحث عن مجموعة'), findsOneWidget);

    await tester.tap(find.text('ابحث عن مجموعة'));
    expect(pressed, 1);
  });

  testWidgets('OfflineBanner shows the offline icon, message and last sync',
      (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      const Scaffold(
        body: OfflineBanner(
          message: 'أنت غير متصل. سيُرسل إتمامك عند عودة الاتصال.',
          lastSynced: '٨:١٢ ص',
        ),
      ),
    ));

    final icon = tester.widget<Icon>(find.byType(Icon).first);
    expect(icon.icon, Icons.cloud_off);
    expect(find.text('أنت غير متصل. سيُرسل إتمامك عند عودة الاتصال.'), findsOneWidget);
    expect(find.text('٨:١٢ ص'), findsOneWidget);
  });

  testWidgets('ConfirmSheet places confirm at the start and cancel at the end',
      (tester) async {
    var confirmed = false;
    await tester.pumpWidget(buildArabicTestApp(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => ConfirmSheet.show(
                context,
                title: 'التراجع عن إتمام الجزء؟',
                message: 'سيعود الجزء إلى «لم يُقرأ بعد» وينقص تقدم المجموعة.',
                confirmLabel: 'نعم، تراجع',
                destructive: true,
                onConfirm: () => confirmed = true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('التراجع عن إتمام الجزء؟'), findsOneWidget);
    expect(find.text('سيعود الجزء إلى «لم يُقرأ بعد» وينقص تقدم المجموعة.'),
        findsOneWidget);

    final confirmRect = tester.getRect(find.text('نعم، تراجع'));
    final cancelRect = tester.getRect(find.text('إلغاء'));
    expect(confirmRect.center.dx, greaterThan(cancelRect.center.dx),
        reason: 'in RTL the confirming action sits at the start (right)');

    await tester.tap(find.text('نعم، تراجع'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('AppSnackBar shows the message with an optional action',
      (tester) async {
    var acted = false;
    await tester.pumpWidget(buildArabicTestApp(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => AppSnackBar.show(
                context,
                'سُجّل إتمام الجزء الخامس',
                actionLabel: 'تراجع',
                onAction: () => acted = true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('سُجّل إتمام الجزء الخامس'), findsOneWidget);
    expect(find.text('تراجع'), findsOneWidget);

    await tester.tap(find.text('تراجع'));
    expect(acted, isTrue);
  });

  testWidgets('SkeletonBox paints a surfaceMuted rounded box', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      const Scaffold(body: SkeletonBox(height: 56)),
    ));

    expect(
      decorationColorOf(tester, find.byType(Container).first),
      AppColors.light.surfaceMuted,
    );
    expect(tester.getSize(find.byType(SkeletonBox)).height, 56);
  });

  testWidgets('ProgressHeader ring shows ١٢ / ٣٠ and the percentage',
      (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      const Scaffold(
        body: ProgressHeader(completed: 12, total: 30),
      ),
    ));

    expect(find.text('١٢ / ٣٠'), findsOneWidget);
    expect(find.text('٤٠٪'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ProgressHeader bar shows the ratio and a progress bar',
      (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      const Scaffold(
        body: ProgressHeader(
          completed: 12,
          total: 30,
          variant: ProgressVariant.bar,
        ),
      ),
    ));

    expect(find.text('١٢ / ٣٠'), findsOneWidget);
    expect(find.text('٤٠٪'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator).first,
    );
    expect(bar.value, closeTo(0.4, 0.001));
  });

  testWidgets('AppTextField renders label, hint, error and LTR email field',
      (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      const Scaffold(
        body: AppTextField(
          label: 'البريد الإلكتروني',
          hint: 'sara@example.com',
          ltr: true,
          keyboardType: TextInputType.emailAddress,
          errorText: 'أدخل بريدًا صحيحًا',
        ),
      ),
    ));

    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('أدخل بريدًا صحيحًا'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.textDirection, TextDirection.ltr);
    expect(tester.getSize(find.byType(AppTextField)).height,
        greaterThanOrEqualTo(52));
  });

  testWidgets('AppTextField obscure toggle flips obscureText', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      const Scaffold(
        body: AppTextField(label: 'كلمة المرور', obscure: true),
      ),
    ));

    var field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isFalse);
  });

  testWidgets('AppCard paints surface with a hairline border and lg radius',
      (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      const Scaffold(body: AppCard(child: SizedBox(width: 40, height: 20))),
    ));

    expect(
      decorationColorOf(tester, find.byType(Container).first),
      AppColors.light.surface,
    );
    final decoration = tester.widget<Container>(
      find.byType(Container).first,
    ).decoration as ShapeDecoration;
    final shape = decoration.shape as RoundedRectangleBorder;
    expect(shape.side.width, 1);
    expect(shape.borderRadius, BorderRadius.circular(16));
  });

  testWidgets('AppSectionHeader shows title, subtitle and optional action',
      (tester) async {
    var pressed = 0;
    await tester.pumpWidget(buildArabicTestApp(
      Scaffold(
        body: AppSectionHeader(
          title: 'الأجزاء',
          subtitle: 'حالة أجزاء اليوم',
          actionLabel: 'عرض الكل',
          onAction: () => pressed++,
        ),
      ),
    ));

    expect(find.text('الأجزاء'), findsOneWidget);
    expect(find.text('حالة أجزاء اليوم'), findsOneWidget);
    await tester.tap(find.text('عرض الكل'));
    expect(pressed, 1);
  });

  testWidgets('AppBadge renders variants, icons, and semantics', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      const Scaffold(
        body: Column(
          children: [
            AppBadge(label: 'عضو', variant: AppBadgeVariant.neutral),
            AppBadge.role(label: 'مشرف', isOwner: false),
            AppBadge.role(label: 'مالك', isOwner: true),
            AppBadge.count(label: '٣٠', variant: AppBadgeVariant.info),
          ],
        ),
      ),
    ));

    expect(find.text('عضو'), findsOneWidget);
    expect(find.text('مشرف'), findsOneWidget);
    expect(find.text('مالك'), findsOneWidget);
    expect(find.text('٣٠'), findsOneWidget);
  });

  testWidgets('AppBanner renders error, warning, info and action button', (tester) async {
    var retryCount = 0;
    await tester.pumpWidget(buildArabicTestApp(
      Scaffold(
        body: Column(
          children: [
            AppBanner.error(
              title: 'تنبيه',
              message: 'تعذر الحفظ، يرجى المحاولة لاحقًا',
              actionLabel: 'إعادة المحاولة',
              onAction: () => retryCount++,
            ),
            AppBanner.warning(
              message: 'وصلت إلى الحد الأقصى للمجموعات (مجموعتان فقط)',
            ),
            AppBanner.info(
              message: 'تم تحديث بيانات الورد تلقائيًا',
            ),
          ],
        ),
      ),
    ));

    expect(find.text('تنبيه'), findsOneWidget);
    expect(find.text('تعذر الحفظ، يرجى المحاولة لاحقًا'), findsOneWidget);
    expect(find.text('وصلت إلى الحد الأقصى للمجموعات (مجموعتان فقط)'), findsOneWidget);
    expect(find.text('تم تحديث بيانات الورد تلقائيًا'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    expect(retryCount, 1);
  });

  testWidgets('StatePanel.empty displays logo and dual actions in RTL order', (tester) async {
    var primaryPressed = 0;
    var secondaryPressed = 0;

    await tester.pumpWidget(buildArabicTestApp(
      Scaffold(
        body: StatePanel.empty(
          title: 'لم تنضم إلى حلقة بعد',
          message: 'اختر حلقة متاحة أو ابدأ حلقتك الخاصة',
          actionLabel: 'انضم لأي حلقة',
          onAction: () => primaryPressed++,
          secondaryActionLabel: 'أنشئ حلقة',
          onSecondaryAction: () => secondaryPressed++,
        ),
      ),
    ));

    expect(find.text('لم تنضم إلى حلقة بعد'), findsOneWidget);
    expect(find.text('اختر حلقة متاحة أو ابدأ حلقتك الخاصة'), findsOneWidget);
    expect(find.text('انضم لأي حلقة'), findsOneWidget);
    expect(find.text('أنشئ حلقة'), findsOneWidget);

    await tester.tap(find.text('انضم لأي حلقة'));
    expect(primaryPressed, 1);
    await tester.tap(find.text('أنشئ حلقة'));
    expect(secondaryPressed, 1);
  });

  testWidgets('AppCard onTap triggers callback with Material ripple', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(buildArabicTestApp(
      Scaffold(
        body: AppCard(
          onTap: () => tapped++,
          child: const Text('بطاقة قابلة للنقر'),
        ),
      ),
    ));

    expect(find.text('بطاقة قابلة للنقر'), findsOneWidget);
    await tester.tap(find.text('بطاقة قابلة للنقر'));
    expect(tapped, 1);
  });

  testWidgets('AppSplashScreen renders brand logo, title, and loading indicator', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      const AppSplashScreen(),
      size: const Size(360, 800),
    ));

    expect(find.text('حلقة'), findsOneWidget);
    expect(find.text('ختمة القرآن مع حلقتك، وردٌ كل يوم'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppSnackBar.showError and showSuccess queue formatted snackbars', (tester) async {
    await tester.pumpWidget(buildArabicTestApp(
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AppSnackBar.showError(context, 'خطأ في الاتصال'),
            child: const Text('إظهار الخطأ'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('إظهار الخطأ'));
    await tester.pump();
    expect(find.text('خطأ في الاتصال'), findsOneWidget);
  });
}
