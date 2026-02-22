import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_config.dart';
import '../services/reports_service.dart';

final reportsServiceProvider = Provider<ReportsService>((ref) {
  return ReportsService();
});

final reportsProvider = StateNotifierProvider<ReportsNotifier, AsyncValue<List<ReportConfig>>>((ref) {
  final service = ref.watch(reportsServiceProvider);
  return ReportsNotifier(service);
});

final reportTemplatesProvider = StateNotifierProvider<ReportTemplatesNotifier, AsyncValue<List<ReportTemplate>>>((ref) {
  final service = ref.watch(reportsServiceProvider);
  return ReportTemplatesNotifier(service);
});

final reportDataProvider = StateNotifierProvider.family<ReportDataNotifier, AsyncValue<ReportData?>, String>((ref, reportId) {
  final service = ref.watch(reportsServiceProvider);
  return ReportDataNotifier(service, reportId);
});

class ReportsNotifier extends StateNotifier<AsyncValue<List<ReportConfig>>> {
  final ReportsService _service;

  ReportsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadReports();
  }

  Future<void> loadReports() async {
    state = const AsyncValue.loading();
    try {
      final reports = await _service.getAllReports();
      state = AsyncValue.data(reports);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createReport(ReportConfig config) async {
    try {
      await _service.createReport(config);
      await loadReports();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateReport(ReportConfig config) async {
    try {
      await _service.updateReport(config);
      await loadReports();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _service.deleteReport(reportId);
      await loadReports();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class ReportTemplatesNotifier extends StateNotifier<AsyncValue<List<ReportTemplate>>> {
  final ReportsService _service;

  ReportTemplatesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    state = const AsyncValue.loading();
    try {
      final templates = await _service.getReportTemplates();
      state = AsyncValue.data(templates);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class ReportDataNotifier extends StateNotifier<AsyncValue<ReportData?>> {
  final ReportsService _service;
  final String reportId;

  ReportDataNotifier(this._service, this.reportId) : super(const AsyncValue.loading()) {
    generateReport();
  }

  Future<void> generateReport() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.generateReport(reportId);
      state = AsyncValue.data(data);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class ReportTemplate {
  final String id;
  final String name;
  final String description;
  final ReportType type;
  final ReportFormat format;
  final String category;
  final List<String> defaultColumns;
  final Map<String, dynamic> defaultFilters;
  final String icon;
  final bool isCustom;
  final List<String> features;

  const ReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.format,
    required this.category,
    this.defaultColumns = const [],
    this.defaultFilters = const {},
    this.icon = '',
    this.isCustom = false,
    this.features = const [],
  });
}