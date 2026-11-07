# Real Flutter Study Progress Preview

This feature is implemented in the maintained Flutter application, not the
standalone HTML concept preview.

## Source

- `lib/features/study_progress/study_tracker.dart`: local timer, daily/weekly
  goals, streak and recent-break calculations, persistent tasks and due checks.
- `lib/features/study_progress/study_progress_screen.dart`: responsive light/dark
  Study Progress interface and Home study tracker card.
- `lib/features/notifications/notifications_screen.dart`: in-app reminder inbox.

## Access after a successful GitHub Pages deploy

- App home: https://horizon003.github.io/pharm-d-with-hyzen/
- Direct Flutter route: https://horizon003.github.io/pharm-d-with-hyzen/#/study-progress

Home has a Study Time panel that navigates to this route.

## Important limits

- Data is saved on the current device/browser and separated by signed-in user
  when Firebase authentication is available.
- One focused minute counts toward a streak day.
- Due reminders are shown in the in-app notification inbox while the Flutter
  app is running, or when the user next opens the planner. Closed-app Android
  notification-panel alarms/push are **not implemented**.
- Campus rankings need an authenticated shared data model and should never
  invent another student's statistics or a rank.
- Real-phone scanner accuracy and OS background notifications are separate
  native device-acceptance tasks.
