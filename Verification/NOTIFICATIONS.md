# Verification — personalized reminders

## Completed in the editing environment

- Swift grammar parsing of all application and verification source files.
- `git diff --check` for modified tracked files.
- String catalog JSON validation, preservation of all previous keys/translations,
  and placeholder compatibility for new English/Romanian strings.
- Review of creation/edit/conversion/routine/status/delete/reschedule hooks and
  optional model-field additions.

## Not executed here

No Apple SDK, Swift compiler or Xcode is installed in this Linux environment.
Grammar parsing is not Swift type checking. No simulator/device screenshots or
notification delivery, SwiftData migration, signing or native build results are
claimed. The native checks below have been extended but must run on a Mac.

## Native checks on Mac

From the existing project directory:

```bash
bash Verification/run-checks.sh
xcodebuild -project DisciplineTracker.xcodeproj -scheme DisciplineTracker -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/DisciplineTracker-notification-build CODE_SIGNING_ALLOWED=NO build
```

The first command uses a temporary legacy SwiftData fixture, never the user's
live database. It covers recurrence boundaries and migration plus:

- old reminder behavior for migrated tasks and routines;
- optional new fields, disabled reminders versus absent settings;
- duplicate/invalid offsets, midnight and daylight-saving boundaries;
- conversion with custom future reminders and protected original settings;
- cancellation of persisted snooze state on completion;
- persistence of routine and empty task reminder lists.

## Device acceptance checks

Use test activities, not important real entries. Record actual results on the Mac
and phone before treating the release as validated.

1. Existing store: old tasks, journal, routine and profile remain; old tasks show
   offsets 10, 0, -15. Restart app; all remain.
2. Fresh activity: default is 10. Set 30/20/10/5 and a custom 45-minute interval;
   save, reopen, restart; selections remain without duplicates.
3. Defaults: changing profile defaults affects only subsequently created tasks and
   routines. Empty defaults stay empty after restart.
4. Previous-day preview: 00:15 task + 30-minute reminder displays previous day 23:45.
   Passed reminder rows do not cause immediate notifications.
5. Permissions: allow, deny, return from iOS Settings, provisional/quiet delivery;
   Profile reflects state. Retry/test errors are visible.
6. Test: one example after 5 seconds, also with locked screen; repeated tests replace
   the earlier pending test. Switching master off cancels an outstanding test.
7. Multiple reminders: receive the selected 2/1/0-minute example once per event.
   Open app repeatedly before firing; no duplicates.
8. Status/deletion: complete, skip, delete before delivery; queued reminders removed.
   Returning a task to Pending schedules only future configured reminders.
9. Reschedule: move, edit date, move to tomorrow, undo; old requests and old snooze
   do not survive. New requests follow new start time.
10. Routine changes: only reminder changes are counted as updates. Effective date
    protects earlier tasks; completed/skipped/past/individually edited tasks stay.
    Selected reminder offsets apply to additions and eligible updates. Stop cancels
    reminders for removed occurrences and leaves protected ones.
11. Conversion: original task's reminders remain unchanged; future occurrences use
    the conversion form's selection. No original-day duplicate is created.
12. Notification tap: app open, background and cold launch; open the right task.
    Tap while Add/Edit/Profile is open: detail appears above it, closing returns to
    the form. Deleting inside notification detail closes it. Deleted IDs cannot crash.
13. Actions: Complete persists and cancels other requests. Snooze creates one additional
    reminder 10 minutes from interaction, survives relaunch, does not alter startTime.
    A snooze coinciding with a regular reminder produces one alert.
    Repeat snooze replaces only the supplemental reminder. Later complete/skip/delete/
    reschedule disables it. Check actions with locked screen and cold app launch.
14. Master off/on: future app notifications removed, individual selections retained;
    re-enabling schedules only future events. Past ones do not replay.
15. Queue: create enough short-interval future activities to exceed 63 events. Earliest
    events are scheduled; warning/last scheduled date displayed in Profile; reopening
    after some fire advances the queue. Test still has room. No promise of background
    refill when app is not opened.
16. Accessibility/locale: large text, VoiceOver labels, dark theme; all newly introduced
    notification screens/actions/messages in Romanian and English.

## Design notes

UNUserNotificationCenter delegate is installed during app initialization. Model
mutations and planning remain on MainActor. A single asynchronous worker processes
latest snapshots; stable request IDs and content/date comparison avoid re-adding
unchanged requests. Pending legacy IDs are removed on the first rebuild. Snooze
state belongs to the persisted task and is tied to its saved start instant.

References:
- https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app
- https://developer.apple.com/documentation/usernotifications/handling-notifications-and-notification-related-actions
