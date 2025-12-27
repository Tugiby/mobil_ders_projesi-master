part of 'report_bloc.dart';

enum ReportLoadStatus { initial, loading, loaded, error }

class ReportState extends Equatable {
  const ReportState({
    this.status = ReportLoadStatus.initial,
    this.reports = const [],
    this.filtered = const [],
    this.selectedId,
    this.filterTypes = const {},
    this.scope = ReportFilterScope.all,
    this.ownerScope = ReportOwnerScope.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  final ReportLoadStatus status;
  final List<ReportEntity> reports;
  final List<ReportEntity> filtered;
  final String? selectedId;
  final Set<ReportType> filterTypes;
  final ReportFilterScope scope;
  final ReportOwnerScope ownerScope;
  final String searchQuery;
  final String? errorMessage;

  ReportState copyWith({
    ReportLoadStatus? status,
    List<ReportEntity>? reports,
    List<ReportEntity>? filtered,
    String? selectedId,
    Set<ReportType>? filterTypes,
    ReportFilterScope? scope,
    ReportOwnerScope? ownerScope,
    String? searchQuery,
    String? errorMessage,
  }) {
    return ReportState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      filtered: filtered ?? this.filtered,
      selectedId: selectedId ?? this.selectedId,
      filterTypes: filterTypes ?? this.filterTypes,
      scope: scope ?? this.scope,
      ownerScope: ownerScope ?? this.ownerScope,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    reports,
    filtered,
    selectedId,
    filterTypes,
    scope,
    ownerScope,
    searchQuery,
    errorMessage,
  ];
}
