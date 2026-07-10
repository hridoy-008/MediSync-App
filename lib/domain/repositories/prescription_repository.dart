import '../../core/utils/result.dart';
import '../entities/prescription.dart';

/// Persists prescriptions + their structured items. Local-first; cloud sync is
/// an enhancement behind the same interface (TRD §1, §8).
abstract interface class PrescriptionRepository {
  Future<Result<List<Prescription>>> getAll();
  Future<Result<Prescription?>> getById(String id);
  Future<Result<void>> save(Prescription prescription);
  Future<Result<void>> delete(String id);
  Stream<List<Prescription>> watchAll();
}
