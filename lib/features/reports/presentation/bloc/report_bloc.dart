import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';

part 'report_event.dart';
part 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc(this._repository) : super(const ReportState()) {
    on<ReportLoadRequested>(_onLoad);
    on<ReportDataReceived>(_onDataReceived);
    on<ReportStreamError>(_onStreamError);
    on<ReportTypeFilterChanged>(_onTypeFilter);
    on<ReportScopeChanged>(_onScope);
    on<ReportOwnerScopeChanged>(_onOwnerScope);
    on<ReportSearchChanged>(_onSearch);
    on<ReportStatusUpdated>(_onStatusUpdate);
    on<ReportFollowToggled>(_onFollowToggle);
    on<ReportSelected>(_onSelect);
    on<ReportCreateRequested>(_onCreate);
    on<ReportDescriptionUpdated>(_onDescriptionUpdate);
    on<ReportDeleted>(_onDelete);
  }

  final ReportRepository _repository;
  StreamSubscription<List<ReportEntity>>? _sub;

  Future<void> _onLoad(
    ReportLoadRequested event,
    Emitter<ReportState> emit,
  ) async {
    await _sub?.cancel();
    emit(state.copyWith(status: ReportLoadStatus.loading));
    _sub = _repository.streamReports().listen(
      (items) => add(ReportDataReceived(items)),
      onError: (e) => add(ReportStreamError(e.toString())),
    );
  }

  void _onDataReceived(ReportDataReceived event, Emitter<ReportState> emit) {
    final filtered = _applyFilters(
      event.reports,
      state.filterTypes,
      state.scope,
      state.ownerScope,
      state.searchQuery,
    );
    emit(
      state.copyWith(
        status: ReportLoadStatus.loaded,
        reports: event.reports,
        filtered: filtered,
      ),
    );
  }

  void _onStreamError(ReportStreamError event, Emitter<ReportState> emit) {
    emit(
      state.copyWith(
        status: ReportLoadStatus.error,
        errorMessage: event.message,
      ),
    );
  }

  void _onTypeFilter(ReportTypeFilterChanged event, Emitter<ReportState> emit) {
    final filtered = _applyFilters(
      state.reports,
      event.types,
      state.scope,
      state.ownerScope,
      state.searchQuery,
    );
    emit(state.copyWith(filterTypes: event.types, filtered: filtered));
  }

  void _onScope(ReportScopeChanged event, Emitter<ReportState> emit) {
    final filtered = _applyFilters(
      state.reports,
      state.filterTypes,
      event.scope,
      state.ownerScope,
      state.searchQuery,
    );
    emit(state.copyWith(scope: event.scope, filtered: filtered));
  }

  void _onOwnerScope(ReportOwnerScopeChanged event, Emitter<ReportState> emit) {
    final filtered = _applyFilters(
      state.reports,
      state.filterTypes,
      state.scope,
      event.scope,
      state.searchQuery,
    );
    emit(state.copyWith(ownerScope: event.scope, filtered: filtered));
  }

  void _onSearch(ReportSearchChanged event, Emitter<ReportState> emit) {
    final filtered = _applyFilters(
      state.reports,
      state.filterTypes,
      state.scope,
      state.ownerScope,
      event.query,
    );
    emit(state.copyWith(searchQuery: event.query, filtered: filtered));
  }

  Future<void> _onStatusUpdate(
    ReportStatusUpdated event,
    Emitter<ReportState> emit,
  ) async {
    final updated = await _repository.updateStatus(event.id, event.status);
    if (updated == null) return;
    final updatedReports = state.reports
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    final filtered = _applyFilters(
      updatedReports,
      state.filterTypes,
      state.scope,
      state.ownerScope,
      state.searchQuery,
    );
    emit(
      state.copyWith(
        reports: updatedReports,
        filtered: filtered,
        selectedId: updated.id,
      ),
    );
  }

  Future<void> _onFollowToggle(
    ReportFollowToggled event,
    Emitter<ReportState> emit,
  ) async {
    final updated = await _repository.toggleFollow(event.id);
    if (updated == null) return;
    final updatedReports = state.reports
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    final filtered = _applyFilters(
      updatedReports,
      state.filterTypes,
      state.scope,
      state.ownerScope,
      state.searchQuery,
    );
    emit(
      state.copyWith(
        reports: updatedReports,
        filtered: filtered,
        selectedId: updated.id,
      ),
    );
  }

  void _onSelect(ReportSelected event, Emitter<ReportState> emit) {
    emit(state.copyWith(selectedId: event.id));
  }

  Future<void> _onCreate(
    ReportCreateRequested event,
    Emitter<ReportState> emit,
  ) async {
    await _repository.createReport(event.report, imagePaths: event.imagePaths);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }

  List<ReportEntity> _applyFilters(
    List<ReportEntity> reports,
    Set<ReportType> types,
    ReportFilterScope scope,
    ReportOwnerScope ownerScope,
    String query,
  ) {
    Iterable<ReportEntity> items = reports;

    if (types.isNotEmpty) {
      items = items.where((e) => types.contains(e.type));
    }

    switch (scope) {
      case ReportFilterScope.openOnly:
        items = items.where((e) => e.status == ReportStatus.open);
        break;
      case ReportFilterScope.followed:
        items = items.where((e) => e.isFollowed);
        break;
      case ReportFilterScope.all:
        break;
    }

    // Placeholder: ownerScope for admin-specific filtering
    if (ownerScope == ReportOwnerScope.adminArea) {
      // Example stub: keep as is for now
    }

    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      items = items.where(
        (e) =>
            e.title.toLowerCase().contains(lower) ||
            e.description.toLowerCase().contains(lower),
      );
    }

    return items.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _onDescriptionUpdate(
    ReportDescriptionUpdated event,
    Emitter<ReportState> emit,
  ) async {
    try {
      await _repository.updateReportDescription(event.id, event.description);
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportLoadStatus.error,
          errorMessage: 'Açıklama güncellenemedi: $e',
        ),
      );
    }
  }

  Future<void> _onDelete(ReportDeleted event, Emitter<ReportState> emit) async {
    try {
      await _repository.deleteReport(event.id);
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportLoadStatus.error,
          errorMessage: 'Bildirim silinemiyor: $e',
        ),
      );
    }
  }
}
