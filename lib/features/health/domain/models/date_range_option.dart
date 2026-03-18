/// ──────────────────────────────────────────────────────────────────────────────
/// Date Range Option – Domain Enum
/// ──────────────────────────────────────────────────────────────────────────────
/// Represents the pre‑defined date ranges the user can pick from.  `custom` is
/// special – it requires the user to supply explicit start / end dates.
/// ──────────────────────────────────────────────────────────────────────────────
library;

enum DateRangeOption {
  today('Today'),
  last7Days('Last 7 Days'),
  custom('Custom Range');

  const DateRangeOption(this.label);
  final String label;
}
