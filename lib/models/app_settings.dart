class AppSettings {
  final String userName; // Custom name in "Welcome back, <userName>"
  final int widgetMaxCards; // 3, 5, 10, 100 (All)
  final String widgetFilter; // 'all', 'action_needed', 'warning_and_urgent'
  final String widgetSortBy; // 'urgency', 'name'
  final bool notificationsEnabled;
  final bool notify30Days;
  final bool notify14Days;
  final bool notify7Days;
  final bool notify1Day;

  AppSettings({
    this.userName = 'CardMinder',
    this.widgetMaxCards = 5,
    this.widgetFilter = 'all',
    this.widgetSortBy = 'urgency',
    this.notificationsEnabled = true,
    this.notify30Days = true,
    this.notify14Days = true,
    this.notify7Days = true,
    this.notify1Day = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'widgetMaxCards': widgetMaxCards,
      'widgetFilter': widgetFilter,
      'widgetSortBy': widgetSortBy,
      'notificationsEnabled': notificationsEnabled,
      'notify30Days': notify30Days,
      'notify14Days': notify14Days,
      'notify7Days': notify7Days,
      'notify1Day': notify1Day,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      userName: (json['userName'] as String?) ?? 'CardMinder',
      widgetMaxCards: (json['widgetMaxCards'] as int?) ?? 5,
      widgetFilter: (json['widgetFilter'] as String?) ?? 'all',
      widgetSortBy: (json['widgetSortBy'] as String?) ?? 'urgency',
      notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? true,
      notify30Days: (json['notify30Days'] as bool?) ?? true,
      notify14Days: (json['notify14Days'] as bool?) ?? true,
      notify7Days: (json['notify7Days'] as bool?) ?? true,
      notify1Day: (json['notify1Day'] as bool?) ?? true,
    );
  }

  AppSettings copyWith({
    String? userName,
    int? widgetMaxCards,
    String? widgetFilter,
    String? widgetSortBy,
    bool? notificationsEnabled,
    bool? notify30Days,
    bool? notify14Days,
    bool? notify7Days,
    bool? notify1Day,
  }) {
    return AppSettings(
      userName: userName ?? this.userName,
      widgetMaxCards: widgetMaxCards ?? this.widgetMaxCards,
      widgetFilter: widgetFilter ?? this.widgetFilter,
      widgetSortBy: widgetSortBy ?? this.widgetSortBy,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notify30Days: notify30Days ?? this.notify30Days,
      notify14Days: notify14Days ?? this.notify14Days,
      notify7Days: notify7Days ?? this.notify7Days,
      notify1Day: notify1Day ?? this.notify1Day,
    );
  }
}
