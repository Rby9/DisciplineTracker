# Validation status

Performed in the editing environment:

- Tree-sitter syntax parsing of all 32 application Swift files and the three native verification source files: no parse errors.
- JSON parsing of all asset catalog manifests: valid.
- `git diff --check`: passed.
- `bash -n Verification/run-checks.sh`: passed.
- Reviewed that new source files live in the project's filesystem-synchronized application folder. Verification fixtures are outside that folder.
- Reviewed all task completion mutations and pending filters for the new mutually exclusive status.

Not performed here (no Swift compiler, Apple SDK, Xcode or iOS simulator):

- Swift type-checking/build, SwiftData macro expansion and actual store migration.
- Execution of `Verification/run-checks.sh`.
- Interface rendering, touch interactions, scrolling and Dynamic Type on devices.
- Notification delivery or code signing on an iPhone.

Native checks use a temporary store and compile legacy models from the uploaded archive under the same module name, then open the store with the updated models. They cover common recurrence boundary cases, status persistence, conversion identity and duplicate prevention. Run them on the Mac before relying on the migrated application.

Manual regression cases:

1. Existing pending/completed tasks, routines and journals survive an update and relaunch.
2. Make recurring: Cancel changes nothing; daily and selected weekdays create the expected dates; completed/skipped original keeps status; original day appears once; converting twice is unavailable.
3. Set each status from Today, Weekly and Details; pending counts, ring, weekly summary and journal agree; relaunch preserves it. All/Completed/Skipped remain reachable on a long list.
4. Delete a future routine occurrence; remove that weekday from the routine and later add it back. The deleted occurrence stays absent. Other new matching days may return.
5. Routine edits protect completed/skipped, historical and individually edited occurrences. Review/apply and Stop still behave as before.
6. Weekly insights uses the currently selected week, handles zero tasks, shows correct categories, and opens the journal for the tapped day. Historical figures reflect currently scheduled tasks, not a frozen history of completion events.
7. On phone, verify reminder (-10 min), exact time and overdue (+15 min), both foreground and lock screen. Completion/skip/deletion cancels future notifications. Repeated rapid changes settle to the latest state.
8. Check Today/Weekly transitions, header/ring replay, long titles, large text, smallest supported device and Reduce Motion.

Known product boundaries retained:

- Data is local to each installation. No device sync or export/import yet.
- At most 64 nearest pending notification events, refreshed by app activation or task edits; no continuous background replenishment.
- Date strip in Today keeps the existing 11-day window; Weekly's calendar can select other dates.
- No replacement app icon or App Store assets were generated in this batch.
