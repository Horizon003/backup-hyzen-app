# Website patch: Firebase student login (NOT APPLIED)

Status: **PROPOSED**. Do not apply until `firestore.rules.proposed` is deployed and tested on staging.
Target file: `PharmD_with_Hyzen_Web_App_Ready_v2.html`, `PW.doLogin` (around line 6997).

## Goals
- Admin login does not change. Admin = Firebase user whose uid == `PW_ADMIN_UID`.
- A Firebase student is **never** treated as admin. Admin is decided only by the uid check, and Firestore rules enforce the same check.
- A Firebase student session loads `students/{uid}`.
- The legacy `pw_users` login stays as a fallback until migration is complete.

## Replacement for the Firebase branch of `doLogin`
```js
if (Cloud.ready) {
  const uid = await Cloud.signInAdmin(u, p);           // existing helper: plain Firebase email/password
  if (uid) {
    if (uid === Cloud.adminUid) {
      /* ===== UNCHANGED existing admin block ===== */
    }
    // NEW: Firebase student (same account works in the Hyzen V3 app)
    let profile = null;
    try {
      const fs = Cloud._fs;
      const snap = await fs.getDoc(fs.doc(Cloud.db, 'students', uid));
      profile = snap.exists() ? snap.data() : null;
    } catch (e) { /* offline or rules not yet deployed */ }
    Cloud.isAdmin = false;                               // explicit: never admin
    Repo.session.save({
      role: 'student', auth: 'firebase', uid,
      userId: uid, email: u,
      name: (profile && profile.fullName) || u,
      professionalYear: profile ? profile.professionalYear : null,
      issuedAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 30*24*3600e3).toISOString()
    });
    hideSigningOverlay(); this._loginBusy = false;
    toast('Logged in'); location.hash = '#/account'; return;
  }
  // not a Firebase user -> fall through to the existing legacy login (kept for now)
}
```
Also change `logout()` so it always calls `Cloud.signOut()` (it already does when Cloud is ready).

## Admin safety
- `pullPrivate()` and every admin screen are gated by `Cloud.isAdmin`, which is set only in the uid-match branch.
- Rules check `request.auth.uid == PW_ADMIN_UID` for every private read or write. Even a tampered session cannot read `pw_users`, `pw_orders` or the inboxes.

## Migration away from plaintext `pw_users[].passwordHash`
1. Ship the patch. New signups use Firebase (the website signup form should call `createUserWithEmailAndPassword` and then write `students/{uid}`, mirroring the app).
2. Legacy login success → show a "Secure your account" prompt. It creates a Firebase account with the **same email** while the user is typing the password (client-side, at that moment only), writes `students/{uid}`, then removes that user's `passwordHash` (admin later re-saves `pw_users` without it).
3. Users who never return: the admin sends a Firebase **password reset** email after creating the account in the console. Legacy passwords are never bulk-transferred.
4. After a cut-off date, remove the legacy fallback and strip `passwordHash` from `pw_users`.

Test checklist: admin login; student login (Firebase); legacy login; student cannot open `#/admin`; student cannot read `settings/pw_users` (rules); logout clears both sessions.
