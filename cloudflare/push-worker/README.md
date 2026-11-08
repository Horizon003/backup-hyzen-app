# Hyzen free push Worker (phase 1)

This Cloudflare Worker is the **trusted FCM sender** for the existing Firebase Spark project `pharmawhisper-debd2`.
It is not a replacement for Firebase Auth, Firestore or Firebase Cloud Messaging.
**Not deployed by committing these files.** The Cloudflare owner must connect/deploy their account and add the secret.

## Security contract

- Only `POST /send` triggers an all-students FCM notification.
- Callers must supply a **valid Firebase Auth ID token** from the existing Firebase project.
- The Worker verifies the token's Google signature, issuer, audience and timing, then compares the signed `sub` to the existing admin UID.
- FCM OAuth uses a Firebase/Google **service account key** stored as a Cloudflare **Secret**, never bundled in Flutter, GitHub or GitHub Pages.
- Browser origin is restricted. Do not confuse CORS with authentication.
- Current phase permits only the public topic `hyzen_announcements_v1`. **Do not send private data over topics.**
- FCM acceptance does not guarantee every phone receives a notification; permissions, app state, network, OEM settings and subscriptions matter.
- There is no general rate limit, audit history or durable delivery receipt in this starter. Add these before substantial public rollout.

## Mobile-friendly Cloudflare setup

1. From your own account open [Cloudflare Workers & Pages](https://dash.cloudflare.com/), choose the Free plan and create a Worker.
2. Connect GitHub repository `Horizon003/pharm-d-with-hyzen` (after the PR is merged) as the build source. Set **root directory** to `cloudflare/push-worker` and deploy command `npx wrangler deploy`. If Cloudflare Git integration does not support that layout, use a computer or mobile browser GitHub Codespace for `npm install && npx wrangler deploy`.
3. From **Firebase Console → Project Settings → Service accounts**, create a dedicated Google service account for sending FCM; grant only the Firebase Cloud Messaging API Admin permission (confirm project permissions). Download its JSON privately. **Never upload it to chat or GitHub.**
4. In the Worker → Settings → Variables and Secrets, create a **Secret** named `SERVICE_ACCOUNT_JSON` and paste the *entire* downloaded JSON. This is sensitive and should be handled in a secure browser/session.
5. Confirm `FIREBASE_PROJECT_ID`, `ADMIN_UID` and `ALLOWED_ORIGIN` from `wrangler.toml` have the expected values. The last one is only for GitHub Pages.
6. Open `https://<your-worker>.workers.dev/health`; it should return `{"ok":true,"service":"hyzen-push"}`.
7. Set the Android build-time public API endpoint: `--dart-define=HYZEN_PUSH_API_URL=https://<your-worker>.workers.dev`; rebuild and distribute a **signed real Android APK** for testing. Existing users' APKs do not gain push support until updated.

## Flutter

The app subscribes authenticated Android users to `hyzen_announcements_v1`, requests Android 13+ permission, receives messages in the foreground inbox, and on tapped notifications after background/terminated launch. System notification banners are handled by Android/FCM when the app is backgrounded; foreground banners need separate local-notification UI if desired.

`Admin → Push notifications` exposes the send form. It refuses to send when the endpoint is not configured. Only Firebase UID from `Backend.adminUid` can access the page, and the Worker **independently verifies** that same UID.

## Limits and next phases

This is **all-students announcement push** only. College/year targeting, individual reminders, OS scheduled study alerts, moderation/rate limiting, audit logs, user opt-out, FCM subscription cleanup across devices and stronger abuse controls require additional work. Spark and Cloudflare Free can cover modest traffic within quotas, but limits and policies can change.

The original admin 'announcement' and 'full-screen notice' features remain separate and unaffected.
