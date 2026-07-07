/// Compatibility barrel for the dashboard UI helpers.
///
/// The three concerns that used to live together here now have their own files
/// (one responsibility each). This barrel re-exports them so existing
/// `import '../utils/dashboard_helpers.dart';` lines keep working unchanged.
library;

export 'safte_semantic_interpreter.dart';
export 'route_transitions.dart';
export 'premium_sliver_app_bar.dart';
