part of 'report_bloc.dart';

enum ReportFilterScope { all, openOnly, followed }

enum ReportOwnerScope { all, adminArea }

class ReportEvent extends Equatable {
  const ReportEvent();
  @override
  List<Object?> get props => [];
}

class ReportLoadRequested extends ReportEvent {}

class ReportDataReceived extends ReportEvent {
  const ReportDataReceived(this.reports);
  final List<ReportEntity> reports;
  @override
  List<Object?> get props => [reports];
}

class ReportStreamError extends ReportEvent {
  const ReportStreamError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class ReportTypeFilterChanged extends ReportEvent {
  const ReportTypeFilterChanged(this.types);
  final Set<ReportType> types;
  @override
  List<Object?> get props => [types];
}

class ReportScopeChanged extends ReportEvent {
  const ReportScopeChanged(this.scope);
  final ReportFilterScope scope;
  @override
  List<Object?> get props => [scope];
}

class ReportOwnerScopeChanged extends ReportEvent {
  const ReportOwnerScopeChanged(this.scope);
  final ReportOwnerScope scope;
  @override
  List<Object?> get props => [scope];
}

class ReportSearchChanged extends ReportEvent {
  const ReportSearchChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

class ReportStatusUpdated extends ReportEvent {
  const ReportStatusUpdated(this.id, this.status);
  final String id;
  final ReportStatus status;
  @override
  List<Object?> get props => [id, status];
}

class ReportFollowToggled extends ReportEvent {
  const ReportFollowToggled(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class ReportSelected extends ReportEvent {
  const ReportSelected(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class ReportCreateRequested extends ReportEvent {
  const ReportCreateRequested(this.report, {this.imagePaths = const []});
  final ReportEntity report;
  final List<String> imagePaths;
  @override
  List<Object?> get props => [report, imagePaths];
}

class ReportDescriptionUpdated extends ReportEvent {
  const ReportDescriptionUpdated(this.id, this.description);
  final String id;
  final String description;
  @override
  List<Object?> get props => [id, description];
}

class ReportDeleted extends ReportEvent {
  const ReportDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
