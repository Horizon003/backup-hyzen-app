# Hyzen push deployment and professional rankings

## Actual state

Worker `hyzen-onesignal-sender` uploaded to the connected Cloudflare account.
D1 `hyzen-push` exists and schema.sql was applied. No paid plan was enabled.
OneSignal App ID is c8344ed8-429a-4c09-8f74-6cc120918dda. The connected OneSignal
app listing sees it, but credential-status API returned 401. Uploaded FCM credentials
were not changed. API acceptance is not evidence of phone delivery.

## Owner setup on a phone

1. Open https://dash.cloudflare.com/?to=/:account/workers/workers-and-pages once.
   Cloudflare reported that this account has no workers.dev subdomain. Complete
   that free initialization. Open `hyzen-onesignal-sender` and enable its workers.dev
   address. Record the HTTPS URL.
2. OneSignal → this app → Settings → Keys & IDs → App API Key. Copy it directly
   into Cloudflare → hyzen-onesignal-sender → Settings → Variables and Secrets:
   name `ONESIGNAL_REST_API_KEY`, type **Secret**. Deploy the variable change.
   Do not paste it into chat, GitHub, Flutter, Pages or a source file.
3. Firebase → Firestore → Rules: back up the current deployed rules. In the existing
   `match /databases/{database}/documents`, merge the membership block below.
   Replace any existing block for this exact collection rather than adding an
   overlapping broad allow. Preserve all unrelated app/admin rules.

```rules
function hyzenAdmin() {
  return request.auth != null &&
    request.auth.uid == 'Vv6HtZjmUvfVACzvuyL2pFx5HR33';
}
match /campusMemberships/{uid} {
  allow get: if hyzenAdmin() || (request.auth != null && request.auth.uid == uid);
  allow list: if hyzenAdmin();
  allow create, update: if hyzenAdmin()
    && request.resource.data.verified is bool
    && request.resource.data.academicYear is int
    && request.resource.data.academicYear >= 1
    && request.resource.data.academicYear <= 5;
  allow delete: if hyzenAdmin();
}
```

4. Populate administrator-verified records in `campusMemberships/{Firebase UID}`:
   `verified: true`, `academicYear: 1..5`, `campusId: canonical college ID`,
   `alias: display alias`, `optOut: false` for consenting rank participants,
   `pushOptOut: false`. Students cannot self-verify or change these fields. The
   collection name is retained for migration compatibility; ranking groups are
   **all colleges within the same academicYear**. College is only a push filter.
5. Build Flutter with `--dart-define=PUSH_API_BASE=https://YOUR_WORKER.workers.dev`.
   Without the URL the Admin Center shows an explicit configuration error and the
   existing inbox remains usable. Firebase stays Spark. Do not deploy the old
   experimental FCM Worker or enable Firebase Blaze.
6. On an Android device with Play Services: sign in, open Notifications → push
   preferences → Enable, grant permission. Confirm a real OneSignal subscription
   and matching Firebase UID external_id in OneSignal. Send to a verified test
   audience from Admin → Push Notification Center. Check foreground/background/
   terminated, click routing, account switching, offline inbox and repeated retries.
   Preserve the same message ID on retry. History says accepted, never delivered,
   until separate delivery/device evidence exists.

## Explicit limits and release gates

- Remote scheduled sending is disabled. Local study reminder schedules stay in the
  existing Android notification plugin. These require closed-app/offline/reboot
  testing on a real device; Firebase or OneSignal does not prove local scheduling.
- OneSignal's current official identity-verification documentation says Flutter
  cannot supply the verification JWT. Do not turn that dashboard toggle on for this
  Flutter SDK. Firebase UID login maps identities but is not impersonation-proof.
  Only non-sensitive announcement content should be sent until a supported identity
  verification integration is completed. No emails, phone numbers, private notes or
  health data are mapped as tags.
- All, college and professional audiences are selected from server-read verified
  records, not editable OneSignal tags. The sender is bounded to 3,000 profiles.
- New material/rank/update/task types are admin-composed sends. Automatic backend
  event triggers and automatic streak/goal reminder generation are not finished;
  no nonfunctional trigger UI has been added.
- Ranking source groups `professional-1`…`professional-5`; weekly, monthly and
  professional-total scores use the existing validated scoring policy. Its existing
  Cloud Functions implementation remains **not deployed**. Those functions require
  Blaze and must not be deployed under this Spark-only request. A free ranking
  runtime migration remains a separate incomplete part of this integration.
- Do not merge/publish Pages or a production release until relevant CI and real
  Android delivery pass. Production APK must use the existing owner signing secrets
  and existing certificate fingerprint. No replacement signing key is permitted.

## Rollback

Keep PR #10 unmerged to preserve main. Disable the new Worker if needed; retain
the D1 send history. Restore the backed-up membership rules if reverting the
membership policy. No existing Firestore data or releases were deleted.
