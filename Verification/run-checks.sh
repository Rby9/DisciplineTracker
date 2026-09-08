#!/bin/bash
set -euo pipefail
tracker_root="$(cd "$(dirname "$0")/.." && pwd)"
tracker_check_dir="$(mktemp -d "${TMPDIR:-/tmp}/DisciplineTracker-checks.XXXXXX")"
trap 'rm -rf "$tracker_check_dir"' EXIT
cd "$tracker_root"
xcrun swiftc -target "$(uname -m)-apple-macosx14.0" -parse-as-library -module-name DisciplineTracker \
    Verification/Fixtures/LegacyModels.swift Verification/LegacyFixture.swift \
    -o "$tracker_check_dir/legacy"
"$tracker_check_dir/legacy" "$tracker_check_dir/migration.store"
xcrun swiftc -target "$(uname -m)-apple-macosx14.0" -parse-as-library -module-name DisciplineTracker \
    DisciplineTracker/Models/TaskItem.swift \
    DisciplineTracker/Models/TaskSeries.swift \
    DisciplineTracker/Models/TaskStatus.swift \
    DisciplineTracker/Models/JournalEntry.swift \
    DisciplineTracker/Utilities/Color+Hex.swift \
    DisciplineTracker/Utilities/AppTheme.swift \
    DisciplineTracker/Utilities/RecurrenceSchedule.swift \
    DisciplineTracker/Utilities/ReminderPolicy.swift \
    DisciplineTracker/Services/RoutineConversion.swift \
    Verification/Checks.swift -o "$tracker_check_dir/checks"
"$tracker_check_dir/checks" "$tracker_check_dir/migration.store"
