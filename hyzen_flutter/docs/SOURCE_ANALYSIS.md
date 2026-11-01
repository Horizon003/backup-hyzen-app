> Historical initial audit. See IMPLEMENTATION_REPORT.md and VALIDATION.md for the current 1.1.0+2 revision.

# HYZEN V3 — SOURCE ANALYSIS (Milestone 0, Deliverable A/B)

Status legend: **CONFIRMED** (proven in supplied source) · **NEW** (new requirement) · **PROPOSED** · **UNKNOWN** (not provable from supplied files)

Secrets policy: Firebase apiKey, admin UID, and similar values are referenced by **source location only**.
They are not copied here.

## 1. Files read
| File | Status | Role |
|---|---|---|
| 00_READ_FIRST_Genspark.md | Read fully | Handoff orientation |
| 00_Hyzen_V3_Latest_Requirements_Addendum.md | Read fully | Priority 1 requirements |
| 01_Hyzen_Genspark_A_to_Z_Master_Build_Prompt.md | Read fully | Master prompt (also pasted by the user, with only minor wording differences) |
| Hyzen_Master_Project_Reference.md | Read fully | Priority 2 continuity spec |
| 02_Hyzen_V3_Android_Design_Performance_Spec.md | Read fully | UI/perf rules |
| 03_Genspark_Execution_Checklist.md | Read fully | Gates |
| Hyzen_New_Chat_Recovery_Prompt.md | Read fully | Continuity protocol |
| PharmD_with_Hyzen_Web_App_Ready_v2.html (7,937 lines) | Backend sections inspected (Cloud, DB, Repo, auth, Drive, offline, notices, settings, themes) | Priority 4 implementation reference |
| PharmD_with_Hyzen_updated(1).html (7,782 lines) | Diffed for cloud keys/special tree | Fallback |
| Flutter project ZIP | **Not supplied** | No existing Flutter implementation, so this is a fresh project |
| Logo / UI reference images | **Not supplied** in ZIP | Only an embedded 256px white mortar-and-pestle PNG was found (v2 line 1040) |

## 2. Firebase — CONFIRMED
- Config is in `window.PW_FIREBASE_CONFIG` (v2 ~L3472). The project ID is `pharmawhisper-debd2` and only a **Web app** is registered.
- Web SDK 10.12.2 is loaded through dynamic imports (app, firestore, auth).
- The admin is identified by a **single hard-coded UID**, `window.PW_ADMIN_UID` (v2 ~L3478). `Cloud.isAdmin = (uid === adminUid)`.
- A comment says Firestore security rules also enforce the admin check, but **the rules file was not supplied, so the deployed rules are UNKNOWN.**
- **No Android app registration or `google-services.json` exists** in the source or the sandbox. This is a Milestone 1 blocker for native Android Firebase.

## 3. Firestore storage model — CONFIRMED
Each `pw_*` domain is stored as **one document**: `settings/{pw_key}` with the shape `{ value: <whole JSON>, updatedAt: <ms epoch> }`.

| Class | Keys | Behaviour |
|---|---|---|
| PUBLIC_KEYS (pulled on boot by every visitor) | pw_settings, pw_notes_tree, pw_lectures_tree, pw_mcqs_tree, pw_products, pw_blogs, pw_announcement, pw_catalog_settings, pw_delivery, pw_stats, pw_social, pw_credits, pw_about, pw_pastpapers | Primary pull: settings, announcement, notes, lectures, mcqs, pastpapers. Everything else is a secondary pull. |
| PRIVATE_KEYS (admin only) | pw_orders, pw_users, pw_messages, pw_import_history | Pulled only when isAdmin is true |
| LOCAL_KEYS (never mirrored) | pw_cart, pw_session, pw_firebase_config, pw_cloudinary_config | Device-local |
| Other collections | `orders_inbox/{id}` (create-only `{value, createdAt}`), `messages_inbox/{id}` (create-only), `verifications/{verifyToken}` (masked public order snapshot) | The admin drains the inboxes into pw_orders and pw_messages |
| Live listener | `onSnapshot(settings/pw_settings)` | Full-screen notice (`fullScreenNotice`), theme, and section flags |

**Conflict / risk:** `pw_special_tree` is written by `DB.set` (it is not a LOCAL key) but is **missing from PUBLIC_KEYS** in both HTML versions. Public clients on other devices therefore never pull it. Whether the rules allow public read of it is UNKNOWN.

Writes to `settings/*` are described in the source comments as admin-only. Student clients must therefore **never write** trees or stats.

## 4. Academic data — CONFIRMED
- The tree is Year{id,label,order,semesters[]} → Semester{id,label,order,subjects[]} → Subject{id,label,order,sections[] (+legacy topics[])} → Section{id,title,published,order,topics[],updatedAt} → Topic{id,title,published,order,files[],updatedAt} → File{id,title,pdfUrl,downloads,published,order,updatedAt}.
- Lectures follow Year → Semester → Subject → topics[]{id,title,youtubeUrl,playlistUrl?,externalUrl?,durationMin?,speaker?,published,order,updatedAt}.
- Read-time normalisers must be ported **read-only**:
  - `__ensureNestedResourceTree` converts legacy `subject.topics[]` with `pdfUrl` into a synthetic section. This applies to notes and mcqs.
  - `__normalizePastPapers` converts the legacy University → Year → Subject → papers structure.
- Section visibility uses `settings[id+"Enabled"]`. **Lectures are off unless set to true**; every other section is on unless set to false.
- Interactive MCQ questions: **none found**. MCQs are file-based.
- When a file is opened, the web build increments `stats.downloads` and `file.downloads` and saves the whole tree. **A student app cannot do this safely** because it needs settings write access and risks lost updates on a whole-tree doc. Download counting is therefore UNKNOWN/PROPOSED backend work.

## 5. Authentication — CONFIRMED vs NEW
| Kind | Behaviour |
|---|---|
| Existing admin | Firebase Auth `signInWithEmailAndPassword`, then a check against the admin UID. A non-matching Firebase user is signed out with the message "This account is not an administrator". |
| Legacy student | `pw_users[]` holds `{id, firstName, lastName, email, phone, passwordHash, createdAt}`. **`passwordHash` contains the plaintext password** (v2 L7039). Login compares plaintext, and a local `pw_session` lasts 30 days. Because pw_users is PRIVATE, this only works on the device that created it or the admin's device. **Must not be reproduced.** |
| New student (NEW) | Firebase Auth email/password in the same project, plus a separate profile document. No such collection exists, so it is a **NEW BACKEND EXTENSION**. |

**Website compatibility risk:** website `doLogin` tries Firebase first. A new student Firebase account that logs in on the website is rejected with "not an administrator" and signed out. Students will only be able to log in on the website after it is updated.

## 6. Cloudinary — CONFIRMED
- Cloud name and unsigned preset are in `window.PW_CLOUDINARY_CONFIG` (v2 ~L3479).
- Upload goes to `POST https://api.cloudinary.com/v1_1/{cloud}/auto/upload` with `file` and `upload_preset`, and the code uses `secure_url`.
- Delete uses a relative Netlify function, `/.netlify/functions/cloudinary-delete`, with an `x-pw-token` header. `PW_DELETE_TOKEN` is empty, so **delete is disabled**. The absolute production host is **UNKNOWN**.
- No API secret is present in the client (good).

## 7. Google Drive — CONFIRMED
- `driveFileId` tries these regexes in order: `/file/d/{id}`, `[?&]id={id}`, `/d/{id}`.
- Preview URL: `https://drive.google.com/file/d/{id}/preview`.
- Raw download URL: `https://drive.usercontent.google.com/download?id={id}&export=download&confirm=t`.
- The optional `PW_DOWNLOAD_ENDPOINT` and the relative `/download/{id}` proxy are host-dependent and UNKNOWN for the app.
- Offline identity: `hyzenUrlKey` returns `drive_{id}` or `url_{FNV-1a base36}`. The Flutter app will use the same keys.
- Offline metadata (`hyzen_offline_meta_v1`) contains: id, url, title, fileName, kind (notes/mcqs/special/papers), path, ctx, status (downloading/ready/failed), progress, size, mime, nativePath, downloadedAt, updatedAt, error.

## 8. Other confirmed domains (for later milestones)
- Settings defaults (v2 L3766).
- Announcement (`pw_announcement`).
- Full-screen notice (`pw_settings.fullScreenNotice`, with seen-state per notice id).
- Delivery defaults: 250 PKR default, free over 10000, plus province rates.
- Orders: verifyToken plus a masked verification doc.
- Products: stock decrement is applied by the admin when draining the inbox.
- Messages go through the inbox.
- Import history keeps 80 entries.
- There are 8 themes. The default is "Pharmacy Green" `#087747` / deep `#045936`.

## 9. Android identity
No existing Android package ID was found. Capacitor detection code exists, but there is no package ID. **PROPOSED: `com.hyzen.pharmd`**, as the master prompt specifies.

## 10. Compatibility map (old → new)
| Old | New Flutter |
|---|---|
| Cloud.pullAll / settings/{key} | `LegacySettingsDocSource` (read `value`) + cached `*Repository` |
| Repo.settings / sectionEnabled | SettingsRepository / `SectionVisibility` |
| Repo.notes / special / mcqs / pastpapers | `AcademicRepository(kind)` + ported read-only normalisers |
| Repo.lectures | LecturesRepository |
| Repo.announcement + Notices | AnnouncementRepository (live listener on settings/pw_settings only) |
| driveFileId / filePreviewUrl / hyzenRawDownloadUrl / hyzenUrlKey | `DriveService` (unit-tested parity) |
| OfflineLibrary | DownloadsRepository (Drift) + DownloadManager |
| Repo.auth.loginUser / pw_users | **Retired.** Replaced by FirebaseAuth plus `students/{uid}` (NEW) |
| Cloud.upload / destroy | CloudinaryService (upload only; delete blocked until the endpoint is known) |
| submitOrder / submitMessage | OrderInbox / MessageInbox repositories (later milestones) |
