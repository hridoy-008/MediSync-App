import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/localization/l10n.dart';
import '../../../core/routing/app_routes.dart';
import '../../bmi_plan/presentation/bmi_plan_page.dart';
import '../../prescription/presentation/prescription_list_page.dart';
import '../../profile/presentation/profile_page.dart';
import 'dashboard_controller.dart';
import 'today_page.dart';

/// The app shell: 4-tab bottom navigation + the global "Add prescription" FAB
/// on Home (Design §4).
class HomeShell extends GetView<DashboardController> {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final index = controller.navIndex.value;
      return Scaffold(
        body: IndexedStack(
          index: index,
          children: const [
            TodayPage(),
            PrescriptionListPage(),
            BmiPlanPage(),
            ProfilePage(),
          ],
        ),
        floatingActionButton: index == 0
            ? FloatingActionButton.extended(
                onPressed: () => Get.toNamed(AppRoutes.capture),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(l.addPrescription),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: controller.setTab,
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.today_outlined),
                selectedIcon: const Icon(Icons.today),
                label: l.navHome),
            NavigationDestination(
                icon: const Icon(Icons.description_outlined),
                selectedIcon: const Icon(Icons.description),
                label: l.navPrescriptions),
            NavigationDestination(
                icon: const Icon(Icons.favorite_outline),
                selectedIcon: const Icon(Icons.favorite),
                label: l.navPlan),
            NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: l.navProfile),
          ],
        ),
      );
    });
  }
}
