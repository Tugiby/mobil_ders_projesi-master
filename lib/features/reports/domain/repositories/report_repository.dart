import '../entities/report_entity.dart';

abstract class ReportRepository {
  Stream<List<ReportEntity>> streamReports();
  Future<ReportEntity> createReport(
    ReportEntity report, {
    List<String> imagePaths = const [],
  });
  Future<ReportEntity?> updateStatus(String id, ReportStatus status);
  Future<ReportEntity?> toggleFollow(String id);
  Future<void> updateReportDescription(String id, String description);
  Future<void> deleteReport(String id);
}
