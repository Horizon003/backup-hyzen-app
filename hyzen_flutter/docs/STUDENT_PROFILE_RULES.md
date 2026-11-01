# Student profile sync — owner-only rules patch

This patch is prepared, **not deployed**. The app reads and writes
`students/{firebaseAuthUid}`. Local cache and retry work already, but cross-device
sync requires the actual deployed Firestore rules to permit these operations.

Open the existing project rules and merge only the block below inside
`match /databases/{database}/documents`. Retain the existing site/store rules.
`isAdmin()` must already mean the configured website administrator. Verify it
before merging. Do not overwrite all live rules with the proposal file blindly.

```js
    match /students/{uid} {
      function noSecrets(d) {
        return !d.keys().hasAny(['password','passwordHash','pass','pwd']);
      }
      function allowedKeys(d) {
        return d.keys().hasOnly(['uid','fullName','mobile','gender','city','professionalYear',
          'institutionName','affiliationStatus','affiliatedUniversity','customUniversity',
          'customUniversityCity','rollNumber','photoUrl','email','role','createdAt','updatedAt']);
      }
      allow get: if (request.auth != null && request.auth.uid == uid) || isAdmin();
      allow list: if isAdmin();
      allow create: if request.auth != null && request.auth.uid == uid
                    && request.resource.data.uid == uid
                    && request.resource.data.role == 'student'
                    && request.resource.data.email == request.auth.token.email
                    && allowedKeys(request.resource.data)
                    && noSecrets(request.resource.data)
                    && request.resource.data.professionalYear is int
                    && request.resource.data.professionalYear >= 1
                    && request.resource.data.professionalYear <= 5;
      allow update: if request.auth != null && request.auth.uid == uid
                    && allowedKeys(request.resource.data)
                    && noSecrets(request.resource.data)
                    && request.resource.data.uid == resource.data.uid
                    && request.resource.data.email == resource.data.email
                    && request.resource.data.role == resource.data.role
                    && request.resource.data.createdAt == resource.data.createdAt
                    && request.resource.data.professionalYear is int
                    && request.resource.data.professionalYear >= 1
                    && request.resource.data.professionalYear <= 5;
      allow delete: if isAdmin();
    }

```

Acceptance: create a test student, save full profile and photo, restart the app,
then sign into that same test account on a second device. Confirm the profile
and professional year persist. Change profession and check library/search/
lectures. A different student must not read or modify the first profile.
Student edits must not change uid/email/role/createdAt or grant admin access.
