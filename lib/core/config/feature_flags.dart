/// Toggle features per white-label deployment (TRD §13). P0 features are on by
/// default; P1/P2 features are designed-for but gated off here.
class FeatureFlags {
  const FeatureFlags({
    this.prescriptionCapture = true,
    this.cloudOcr = true,
    this.medicationReminders = true,
    this.mealReminders = true,
    this.hydrationReminders = true,
    this.sleepReminders = true,
    this.bmiPlan = true,
    this.cloudSync = true,
    // P1+ — designed for, off by default
    this.adherenceReports = false,
    this.vitalsTracking = false,
    this.inventoryRefill = false,
    this.caregiverProfiles = false,
    this.drugInteractionWarnings = false,
  });

  final bool prescriptionCapture;
  final bool cloudOcr;
  final bool medicationReminders;
  final bool mealReminders;
  final bool hydrationReminders;
  final bool sleepReminders;
  final bool bmiPlan;
  final bool cloudSync;

  final bool adherenceReports;
  final bool vitalsTracking;
  final bool inventoryRefill;
  final bool caregiverProfiles;
  final bool drugInteractionWarnings;

  static const FeatureFlags defaults = FeatureFlags();
}
