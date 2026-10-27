# PHARM D WITH HYZEN — COMPLETE APPROVED SCREEN-BY-SCREEN DESIGN SPECIFICATION

**Audience:** Claude (development / UI implementation AI). **Source:** user's final Q1–Q33 choices and subsequent custom 3D/icon/avatar/motion requirements.  
**Status:** Approved product/design specification; **NOT implemented code**. Actual repository data and routes must be audited before development.  
**Purpose:** Explain every screen from Splash, Welcome, Login and Signup to Study/PDF Studio, Shop, Campus League, Settings and Admin in the same screen-layout/action/state/motion detail used during the consultation.  
**Project:** Existing private Flutter/Dart + Kotlin Android project `Horizon003/pharm-d-with-hyzen`. Repo URL `https://github.com/Horizon003/pharm-d-with-hyzen`; access must be authorized and verified by Claude.  
**DO NOT** interpret visual mockups as current app screenshots. Previews are specification diagrams.  

## Claude: non-negotiable reading instructions

1. **Read the complete document before touching any code**; chronological later changes supersede earlier ideas. Read `DECISION_LEDGER_Q01_Q33.md` in this package too.
2. **Audit repository read-only first**. Compare all named routes/data fields with actual code and document differences. Do not assume this file proves an API exists.
3. Retain the four fixed bottom tabs: **Home / Study / PDF Studio / Shop**; Campus League is linked from Home, never a fifth tab.
4. Design foundation: Manrope typography, Deep Teal `#087F76`, Slate `#1A3440`, background `#F3F8F7`, white `#FFFFFF`, pale teal `#DDEDEA`, muted text `#507379`; Light/Dark/System; 8-point spacing, rounded premium cards, compact density only where requested.
5. **Original AI-assisted branded assets are mandatory**: custom coordinated icons/chips, premade Gen-Z academic avatars plus real DP photo option, cohesive 3D academic welcome/onboarding characters, empty/error/download artwork, smooth meaningful Flutter-compatible micro-animations, personalized Welcome/Welcome Back. Respect reduced motion and performance; actual images/animations are **to be created during implementation**, not supplied in these mockups.
6. No invented backend or faux content. Student roll number, personal contact and registration fields are private; correct answers stay on the server while the quiz is live.
7. **Never add Wallet, Top-up, Withdrawal, balance, or quiz payment controls.** App-mediated registrations/participation promoting fee-linked cash-prize Special competitions remain **unavailable unless the relevant Google Play and legal permissions are verified**; collecting fees externally does not bypass this condition. This does not automatically remove legitimate already-supported Shop payments.
8. Standard academic quiz: ONE subject, eligible Professional Year(s), **maximum 3 attempts per day and ≥1h wait**, per-student non-repeating question IDs. Special academic quiz: **TWO OR MORE admin-selected subjects** mixed/shuffled, approved private registration, **one attempt**. Do **NOT** show Paid/Free or Reward/No Reward badges on quiz cards.
9. Maintain original current routes and flows; treat suggested new child screens/routes as proposals until repository audit. No code change requested by this deliverable.

### Official selected design combinations

- **Q01 — A+B | Product tone**
- **Q02 — B | Colors and themes**
- **Q03 — B+C | Four tabs**
- **Q04 — A+B+D | Home**
- **Q05 — A | Study landing and year**
- **Q06 — A+C+D | Subjects**
- **Q07 — C+D custom | Folder exploration**
- **Q08 — C | PDF Reader**
- **Q09 — B+D+A | PDF Reader actions**
- **Q10 — B+D | PDF Studio**
- **Q11 — B+C | Scanner camera**
- **Q12 — D+B+C | Scan review**
- **Q13 — D+B+C | Export**
- **Q14 — C+D+A | PDF editing**
- **Q15 — custom D+C | Settings structure**
- **Q16 — C+A+D+B | Profile**
- **Q17 — A→D→B→C | Onboarding/Auth**
- **Q18 — A+B+D | Shop + subtle motion**
- **Q19 — B+A+D | Search**
- **Q20 — B+A+C + selective D | Downloads**
- **Q21 — B+A+C + selective D | Notifications**
- **Q22 — A+B+D | Blog, About, Contact**
- **Q23 — B+C+D | Admin**
- **Q24 — custom Campus Ranking + Quiz Duel + Event Announcement**
- **Q25 — custom A minimal public profile + quiz mechanics and later revision**
- **Q26 — custom A+B+C+D with revised Standard/Special UX**
- **Q27 — A+B+C+D | MCQ exam interface**
- **Q28 — A+B+C+D + academic refinements | Admin Quiz Management**
- **Q29 — A+B+C+D | polish and resilience**
- **Q30 — B + selective A + D | Campus entry and architecture**
- **Q31 — A+B+C+D selective | Design system**
- **Q32 — B+C+D+A final audit | Rollout**
- **Q33 — B+C+D plus A summary | AI handoff packaging**

## Screen index

| ID | Section | Screen | Route / Destination | Decision source |
|---|---|---|---|---|
| S001 | 01 • Entry / Authentication | Splash / Startup | `/splash` | Q01 Q02 Q17 Q29 Q31 Q33 |
| S002 | 01 • Entry / Authentication | Premium Welcome / Welcome Back | `/welcome` | Q17 A Q31 D Q33 |
| S003 | 01 • Entry / Authentication | Editorial Onboarding • Intro | `existing onboarding flow; audit routes` | Q17 D Q33 |
| S004 | 01 • Entry / Authentication | Login | `/login` | Q17 B Q29 |
| S005 | 01 • Entry / Authentication | Forgot Password | `/forgot-password` | Q17 B Q15 Security |
| S006 | 01 • Entry / Authentication | Registration • Personal | `/register/personal` | Q17 C Q16 |
| S007 | 01 • Entry / Authentication | Registration • Academic | `/register/academic` | Q05 Q16 Q17 C Q28 |
| S008 | 01 • Entry / Authentication | Registration • Credentials | `/register/credentials` | Q17 C Q15 Security |
| S009 | 01 • Entry / Authentication | Registration Success | `/register/success` | Q17 C Q29 C Q33 |
| S010 | 01 • Entry / Authentication | Legal & Policies | `/legal/:doc` | Q17 Q15 |
| S011 | 02 • Home / Study | Home Dashboard | `/home` | Q01–Q04 Q30 B+A Q31 Q33 |
| S012 | 02 • Home / Study | Global Search | `/search` | Q19 B+A+D |
| S013 | 02 • Home / Study | Study Landing — Resource First | `/study` | Q05 A Q31 C |
| S014 | 02 • Home / Study | Subject List | `/study/<resource>/subjects • verify path` | Q06 A+C+D |
| S015 | 02 • Home / Study | Nested Folder Explorer | `study nested routes • audit` | Q07 C+D |
| S016 | 02 • Home / Study | PDF Leaf Gallery | `study terminal folder • audit` | Q07 custom |
| S017 | 02 • Home / Study | Immersive Smart PDF Reader | `/viewer, /imported-viewer, /pdf-studio/viewer/:fileId` | Q08 C Q09 B+D+A |
| S018 | 02 • Home / Study | Reader More Tools Sheet | `PDF reader overlay` | Q09 D Q14 |
| S019 | 02 • Home / Study | Lecture Viewer Compatibility | `/lectures` | Existing route + Q05–Q09 |
| S020 | 03 • PDF Studio / Offline | PDF Studio Workspace | `/pdf-studio` | Q10 B+D |
| S021 | 03 • PDF Studio / Offline | Precision Smart Scanner Camera | `custom native Android camera screen` | Q11 B+C |
| S022 | 03 • PDF Studio / Offline | Scan Page Review Hub | `scanner review` | Q12 D |
| S023 | 03 • PDF Studio / Offline | Four-Corner Manual Crop Editor | `scanner crop editor` | Q12 B |
| S024 | 03 • PDF Studio / Offline | Enhancement / Filter Studio | `scanner filter editor` | Q12 C |
| S025 | 03 • PDF Studio / Offline | PDF Export Bottom Sheet | `scanner export` | Q13 D+B |
| S026 | 03 • PDF Studio / Offline | PDF Saved Success | `post-export screen` | Q13 C |
| S027 | 03 • PDF Studio / Offline | PDF Editor Workspace | `/create-pdf and existing editor routes` | Q14 C+D+A |
| S028 | 03 • PDF Studio / Offline | Create PDF / Import Content | `/create-pdf` | Q10 Q13 Q14 |
| S029 | 03 • PDF Studio / Offline | Downloads • Saved / In Progress / Failed | `/downloads` | Q20 B+A |
| S030 | 03 • PDF Studio / Offline | Offline Nested Library & PDF Gallery | `Downloads saved folders` | Q20 C |
| S031 | 03 • PDF Studio / Offline | Storage & Cleanup | `Settings → Storage` | Q20 D |
| S032 | 04 • Profile / Settings | Student Profile Overview | `/profile` | Q16 C+A+D+B Q33 |
| S033 | 04 • Profile / Settings | Edit Profile — Personal / Academic / Security | `/profile/edit` | Q16 D+B |
| S034 | 04 • Profile / Settings | Avatar & Photo Picker | `profile avatar picker` | Q16 B Q33 custom |
| S035 | 04 • Profile / Settings | Settings Landing — My Workspace | `/settings` | Q15 D+C |
| S036 | 04 • Profile / Settings | Appearance & Accessibility | `Settings → Appearance` | Q02 Q29 D Q31 |
| S037 | 04 • Profile / Settings | Security & Account | `Settings → Security & Account` | Q15 Security Q16 |
| S038 | 05 • Shop / Content | Shop Home & Product Catalog | `/shop` | Q18 A+B+D |
| S039 | 05 • Shop / Content | Product Detail | `/shop/p/:id` | Q18 B |
| S040 | 05 • Shop / Content | Shopping Cart | `/cart` | Q18 B+D |
| S041 | 05 • Shop / Content | Guided Checkout | `/checkout` | Q18 D |
| S042 | 05 • Shop / Content | Order Success | `/order-success` | Q18 D Q29 |
| S043 | 05 • Shop / Content | My Orders & Order Detail | `/orders` | Q18 D |
| S044 | 05 • Shop / Content | Notification Center | `/notifications` | Q21 B+A+C+D selective |
| S045 | 05 • Shop / Content | Announcements / Featured Message | `Home / Notifications / Admin content` | Q21 C Q23 |
| S046 | 05 • Shop / Content | Blog Feed | `/blog` | Q22 A |
| S047 | 05 • Shop / Content | Blog Article Reader | `/blog/:id` | Q22 B |
| S048 | 05 • Shop / Content | About Hyzen | `/about` | Q22 D + custom |
| S049 | 05 • Shop / Content | Contact Us | `/contact` | Q22 D |
| S050 | 06 • Campus League | Campus League Landing | `Home Quick Access → new League route (audit)` | Q24 custom Q26 Q30 B |
| S051 | 06 • Campus League | Standard Quiz Listing & Upcoming Card | `League → Standard` | Q26 Q28 |
| S052 | 06 • Campus League | Special Quiz Listing & Mixed-Subject Card | `League → Special` | Q26 Q28 + amendments |
| S053 | 06 • Campus League | Quiz Competition Details | `League → Event Details` | Q26 B+C |
| S054 | 06 • Campus League | Special Registration Form | `League → Special → Register` | Q26 D Q25 privacy |
| S055 | 06 • Campus League | Registration Status / Countdown | `League → Registration Status` | Q26 C+D |
| S056 | 06 • Campus League | MCQ Exam — Focused Question | `League → Quiz Attempt` | Q27 A+B+C+D |
| S057 | 06 • Campus League | Question Navigator Bottom Sheet | `Exam → Navigator` | Q27 C |
| S058 | 06 • Campus League | Review Answers & Confirm Submit | `Exam → Review/Submit` | Q27 D |
| S059 | 06 • Campus League | Quiz Result & Rank | `League → Results` | Q27 D Q24 |
| S060 | 06 • Campus League | Campus Rankings • Scopes | `League → Rankings` | Q24 A Q25 |
| S061 | 06 • Campus League | Public Competition Profile | `League → Student Profile` | Q25 A custom |
| S062 | 06 • Campus League | Student Duel Discovery & Invitation | `League → Duels` | Q24/Q25 Duel |
| S063 | 06 • Campus League | Timed MCQ Duel | `League → Active Duel` | Q24/Q25 Q27 |
| S064 | 06 • Campus League | Duel History & My Academic Performance | `League → History / Performance` | Q24 custom |
| S065 | 07 • Administration | Admin Task-First Dashboard | `/admin` | Q23 B+C+D |
| S066 | 07 • Administration | Admin Content Explorer | `/admin/sections, /admin/content/:kind` | Q23 C |
| S067 | 07 • Administration | Admin General Import & Manage | `/admin/import, /admin/manage/:section` | Q23 C+D |
| S068 | 07 • Administration | Admin Commerce & Orders | `admin commerce/orders routes • audit` | Q23 D Q18 |
| S069 | 07 • Administration | Admin Announcements & Broadcasts | `Admin announcements module` | Q21 Q23 |
| S070 | 07 • Administration | Admin Statistics | `/admin/stats` | Q23 D |
| S071 | 07 • Administration | Quiz Operations Dashboard | `Admin → Quiz Management` | Q28 A |
| S072 | 07 • Administration | CSV Question Bank Library | `Admin → MCQ Bank` | Q28 B + user refinements |
| S073 | 07 • Administration | CSV Import Mapping & Validation | `Admin → MCQ Bank → Import` | Q28 B |
| S074 | 07 • Administration | Create Quiz Wizard | `Admin → Create Quiz` | Q28 C |
| S075 | 07 • Administration | Admin Registration Inbox & Review | `Admin → Registrations` | Q28 D Q26 |
| S076 | 07 • Administration | Admin Results & Ranking Review | `Admin → Results` | Q28 D Q27 |
| S077 | 07 • Administration | Admin League Feature Controls | `Admin → Feature Controls` | Q23 Q28 D Q30 D |
| S078 | 08 • Cross-Cutting | Loading Skeletons & Empty States | `every feature module` | Q29 A Q33 assets |
| S079 | 08 • Cross-Cutting | Error & Offline Recovery | `every feature module` | Q29 B Q33 |
| S080 | 08 • Cross-Cutting | Branded Icon & Chip Component Library | `global reusable widgets` | Q02 Q31 Q33 |
| S081 | 08 • Cross-Cutting | 3D Onboarding & Personalized Animated Greeting | `startup/onboarding component` | Q17 Q29 C Q33 |

---

# COMPLETE SCREEN SPECIFICATIONS


## 01 • Entry / Authentication

### S001 — Splash / Startup

**Decision:** Q01 Q02 Q17 Q29 Q31 Q33  
**Route/location:** `/splash`  
**Design intent:** Slate + Deep Teal premium branded startup with original pharmacy-academic icon mark; no forced repeated onboarding.  
**Illustrative mockup:** ![Splash / Startup](SCREEN_MOCKUPS/S001_Splash_Startup.png)

**Visual hierarchy and exact layout**

- Centered verified app logo/mascot on calm Slate or soft teal background
- Subtle brand loading/route-resolution indicator, not a fabricated progress bar
- One restrained motion accent, no clutter

**User actions and navigation**

- Resolve first launch vs returning signed-in user and route reliably
- Accessibility: reduced-motion static logo and skip long reveal

**Loading, empty, errors and permission states**

- Loading, offline auth refresh, expired session, incompatible version, crash-safe retry; never infinite spinner

**Animations and feedback:** Short native Flutter opacity/scale reveal with deterministic timeout; no heavy video on every launch

**Implementation / data rules:** Preserve real session/router behavior; assets bundled offline; do not claim auth completed before it does.

**Acceptance conditions**

- [ ] Valid session opens correct Home
- [ ] Fresh user opens Welcome
- [ ] Fails safely with real recovery action

### S002 — Premium Welcome / Welcome Back

**Decision:** Q17 A Q31 D Q33  
**Route/location:** `/welcome`  
**Design intent:** Premium academic introduction, personalized Welcome [Name]/Welcome back [Name] only when real profile is known.  
**Illustrative mockup:** ![Premium Welcome / Welcome Back](SCREEN_MOCKUPS/S002_Premium_Welcome_Welcome_Back.png)

**Visual hierarchy and exact layout**

- Sparse full-height Slate/teal branded hero and original 3D-style academic character
- Big Manrope headline, one sentence describing PHARM D WITH HYZEN
- Primary Get Started/Continue and clear Sign In route

**User actions and navigation**

- New users continue to editorial onboarding and registration/login
- Existing users can skip directly to Login/Home where permitted

**Loading, empty, errors and permission states**

- Name missing uses a neutral greeting; no empty placeholder name
- Animations disabled/shortened for returning users

**Animations and feedback:** Character enters with gentle easing, headline stagger/reveal, reduced-motion fallback; no fake typing delays

**Implementation / data rules:** Reuse verified profile displayName; avoid greeting before state resolves; do not block deep links.

**Acceptance conditions**

- [ ] Personalization sourced from real user data
- [ ] Accessible skip
- [ ] No unverified promises or ads

### S003 — Editorial Onboarding • Intro

**Decision:** Q17 D Q33  
**Route/location:** `existing onboarding flow; audit routes`  
**Design intent:** A sequence of modern editorial intro slides using original cohesive premium 3D educational characters.  
**Illustrative mockup:** ![Editorial Onboarding • Intro](SCREEN_MOCKUPS/S003_Editorial_Onboarding_Intro.png)

**Visual hierarchy and exact layout**

- Large 3D-style illustrated pharmacy student/scanner/learning companion
- Short benefit-led headline and two-line caption
- Minimal progress indicator, Next and Skip controls

**User actions and navigation**

- Swipe or Next, previous/back, Skip onboarding, Get Started last panel
- Skip returns to intended authentication route

**Loading, empty, errors and permission states**

- Offline-safe bundled assets; adapt aspect ratio, screen readers, reduced motion

**Animations and feedback:** Light parallax/crossfade and character pose transitions; do not import web-specific React animation code

**Implementation / data rules:** First-launch flag persisted; no broken route loops; original art with cleared reuse rights.

**Acceptance conditions**

- [ ] Every slide legible at 200% text scaling
- [ ] Skip works
- [ ] Onboarding not forced on returning user

### S004 — Login

**Decision:** Q17 B Q29  
**Route/location:** `/login`  
**Design intent:** Minimal professional login screen: small signature illustration, obvious fields and accessible status.  
**Illustrative mockup:** ![Login](SCREEN_MOCKUPS/S004_Login.png)

**Visual hierarchy and exact layout**

- Small brand emblem and Welcome back heading
- Email/username and password fields, password visibility, validation
- Forgot Password; prominent Sign In; create-account link

**User actions and navigation**

- Submit once, show progress, recover from invalid credentials, navigate to current authorized destination

**Loading, empty, errors and permission states**

- Empty, invalid format, wrong credentials, offline, server unavailable; no raw exceptions

**Animations and feedback:** Smooth focus and button loading, error message without aggressive shake

**Implementation / data rules:** Keep existing authentication provider, password and token contract; never add unapproved social login.

**Acceptance conditions**

- [ ] Can log into existing account
- [ ] Password hidden by default
- [ ] Keyboard not obscuring actions

### S005 — Forgot Password

**Decision:** Q17 B Q15 Security  
**Route/location:** `/forgot-password`  
**Design intent:** Calm account recovery consistent with current backend policies.  
**Illustrative mockup:** ![Forgot Password](SCREEN_MOCKUPS/S005_Forgot_Password.png)

**Visual hierarchy and exact layout**

- Back navigation, centered small lock/letter illustration
- Registered email entry, Submit, true recovery guidance
- Success or failure with safe privacy-preserving wording

**User actions and navigation**

- Request reset using existing supported auth path
- Return to login

**Loading, empty, errors and permission states**

- Rate-limit / generic account-existence-safe messaging, offline, valid email errors

**Animations and feedback:** Subtle email-sent confirmation or static reduced-motion equivalent

**Implementation / data rules:** Do not invent SMS or verification method if backend does not implement it.

**Acceptance conditions**

- [ ] Recovery request real
- [ ] No account enumeration
- [ ] No dead ends

### S006 — Registration • Personal

**Decision:** Q17 C Q16  
**Route/location:** `/register/personal`  
**Design intent:** Step one of guided registration capturing only existing necessary personal information.  
**Illustrative mockup:** ![Registration • Personal](SCREEN_MOCKUPS/S006_Registration_Personal.png)

**Visual hierarchy and exact layout**

- Progress strip Personal / Academic / Credentials
- Full name, existing required identity/contact fields, field helper text
- Continue and Back with form state saved

**User actions and navigation**

- Validated next/back, autocomplete where safe, consent for profile data

**Loading, empty, errors and permission states**

- Duplicate account, missing field, invalid phone/email, app dismissal

**Animations and feedback:** Compact stage transition, no loss of entered fields

**Implementation / data rules:** Confirm actual form/backend data model; avoid collecting roll number in public profile unnecessarily.

**Acceptance conditions**

- [ ] Validation real
- [ ] Back preserves fields
- [ ] No duplicate registration

### S007 — Registration • Academic

**Decision:** Q05 Q16 Q17 C Q28  
**Route/location:** `/register/academic`  
**Design intent:** Select university and Professional Year once; this is the source for Study and Campus eligibility.  
**Illustrative mockup:** ![Registration • Academic](SCREEN_MOCKUPS/S007_Registration_Academic.png)

**Visual hierarchy and exact layout**

- Stage progress with Academic highlighted
- University picker, Professional Year 1–5, any real necessary academic attributes
- Context helper: Study automatically shows your year-specific resources

**User actions and navigation**

- Choose/edit year, search university if backend supports, next/back

**Loading, empty, errors and permission states**

- Unknown university, unavailable program, empty options; no fake institutions

**Animations and feedback:** Picker bottom sheets, smooth state highlighting

**Implementation / data rules:** Persist genuine academic year in profile; sensitive roll number private if required.

**Acceptance conditions**

- [ ] Study does not ask for year again
- [ ] Year filter reflects profile
- [ ] Bad/missing year handled

### S008 — Registration • Credentials

**Decision:** Q17 C Q15 Security  
**Route/location:** `/register/credentials`  
**Design intent:** Final signup step with authentication credentials and clear agreements.  
**Illustrative mockup:** ![Registration • Credentials](SCREEN_MOCKUPS/S008_Registration_Credentials.png)

**Visual hierarchy and exact layout**

- Progress header and verified email/username if in model
- Password/confirm password, visibility toggles and rules
- Terms/privacy links, Create Account button

**User actions and navigation**

- Submit with duplicate-submission protection, read actual legal docs, back edits

**Loading, empty, errors and permission states**

- Weak password, existing username/email, lost connection, server rejection

**Animations and feedback:** Strength feedback without claiming unsupported security properties

**Implementation / data rules:** Use existing identity provider and password policy; preserve backend verification gates.

**Acceptance conditions**

- [ ] No plaintext persistence
- [ ] Backend errors handled
- [ ] Terms links accessible

### S009 — Registration Success

**Decision:** Q17 C Q29 C Q33  
**Route/location:** `/register/success`  
**Design intent:** Actual confirmed success screen with compact celebratory 3D graduation/academic illustration.  
**Illustrative mockup:** ![Registration Success](SCREEN_MOCKUPS/S009_Registration_Success.png)

**Visual hierarchy and exact layout**

- Success emblem and personalized welcome if available
- Brief account status and relevant next action
- Go to Home / Complete Profile as real routes permit

**User actions and navigation**

- Continue to allowed destination and never create account twice

**Loading, empty, errors and permission states**

- Pending verification is shown honestly instead of success if not completed

**Animations and feedback:** One gentle check-mark / illustration reveal plus reduced-motion static card

**Implementation / data rules:** Success visible only after server confirms creation.

**Acceptance conditions**

- [ ] No false success on timeout
- [ ] Correct created account navigation

### S010 — Legal & Policies

**Decision:** Q17 Q15  
**Route/location:** `/legal/:doc`  
**Design intent:** Readable article page for terms/privacy policy and other supported legal documents.  
**Illustrative mockup:** ![Legal & Policies](SCREEN_MOCKUPS/S010_Legal_Policies.png)

**Visual hierarchy and exact layout**

- Clear legal title, updated timestamp if available
- Readable typography, headings, links
- Back and optional share/print only when supported

**User actions and navigation**

- Scroll/accessibility links and safe back

**Loading, empty, errors and permission states**

- Loading/error/missing document; never placeholder legal terms

**Animations and feedback:** Almost static; subtle route transition

**Implementation / data rules:** Render real legally approved source texts; do not generate fictitious policy.

**Acceptance conditions**

- [ ] Correct current legal content
- [ ] Accessible text scaling


## 02 • Home / Study

### S011 — Home Dashboard

**Decision:** Q01–Q04 Q30 B+A Q31 Q33  
**Route/location:** `/home`  
**Design intent:** Academic-first Home with small premium greeting hero and genuinely useful Quick Access.  
**Illustrative mockup:** ![Home Dashboard](SCREEN_MOCKUPS/S011_Home_Dashboard.png)

**Visual hierarchy and exact layout**

- Top personalized short greeting/search and top-right notification/profile
- Small editorial hero, 4 Quick Access tiles (Study Library, PDF Studio, Campus League, Downloads)
- Real Recent Activity, announcements and selected Shop/Blog links; micro quiz teaser only if relevant upcoming/live event

**User actions and navigation**

- Search, quick access navigation, resume actual file, open legitimate announcement; no fifth tab

**Loading, empty, errors and permission states**

- No recent activity, unauthorized League, offline partial data, empty announcements

**Animations and feedback:** Short greeting/hero reveal, card press feedback, no oversized promotional animation

**Implementation / data rules:** Home data truly from repo; avoid fake recents and nonexistent events; League feature flag server-enforced.

**Acceptance conditions**

- [ ] Four bottom tabs unchanged
- [ ] Campus League tile accessible
- [ ] No empty placeholder quiz teaser

### S012 — Global Search

**Decision:** Q19 B+A+D  
**Route/location:** `/search`  
**Design intent:** Context-aware fast search with global category chips and advanced filters on demand.  
**Illustrative mockup:** ![Global Search](SCREEN_MOCKUPS/S012_Global_Search.png)

**Visual hierarchy and exact layout**

- Search bar at top, Recent Searches (with Clear) when empty
- Category chips Study, PDFs, Shop, Articles as supported
- Result list with breadcrumb locations and filters bottom sheet

**User actions and navigation**

- Debounced input, select category, clear recent, apply/reset advanced filters, open actual result

**Loading, empty, errors and permission states**

- True loading/no results/network error; true result count, not invented PDF full-text index

**Animations and feedback:** Light chips/highlights and list transition after debounce

**Implementation / data rules:** Study context auto-applies year; reader PDF full-text search separate until index proven.

**Acceptance conditions**

- [ ] Search result real
- [ ] Context maintained
- [ ] Advanced filters optional

### S013 — Study Landing — Resource First

**Decision:** Q05 A Q31 C  
**Route/location:** `/study`  
**Design intent:** Library entrance goes Resource → Subject → Nested Folders → Final PDFs; year comes from saved profile.  
**Illustrative mockup:** ![Study Landing — Resource First](SCREEN_MOCKUPS/S013_Study_Landing_Resource_First.png)

**Visual hierarchy and exact layout**

- Header Study Library + current Professional Year info (not repeatedly selected)
- Compact rows for Regular Notes, Special Notes, MCQs, PPS
- Search relevant to resource section

**User actions and navigation**

- Tap a resource and navigate to scoped subject listing; access downloaded items separately

**Loading, empty, errors and permission states**

- No resources for year, changed year, backend error, offline saved content

**Animations and feedback:** Restrained list entrance and press feedback; no giant cards

**Implementation / data rules:** Do not add extra manual year prompt on Study; existing authorizations intact.

**Acceptance conditions**

- [ ] Accurate year scope
- [ ] Correct four resource categories
- [ ] No fabricated availability

### S014 — Subject List

**Decision:** Q06 A+C+D  
**Route/location:** `/study/<resource>/subjects • verify path`  
**Design intent:** Academic subject directory with clean folder icons, simple rows and optional search.  
**Illustrative mockup:** ![Subject List](SCREEN_MOCKUPS/S014_Subject_List.png)

**Visual hierarchy and exact layout**

- Breadcrumb Study / Resource, search/filter
- Simple subject rows with small branded folder icon and subtitle only when real
- Tap opens nested folder explorer

**User actions and navigation**

- Search subjects, open subject, breadcrumb navigate

**Loading, empty, errors and permission states**

- No subject for selected year, loading, offline subset

**Animations and feedback:** Stagger only a few visible rows or none on weak devices

**Implementation / data rules:** Use current repo subject taxonomy; only existing year-scoped subjects.

**Acceptance conditions**

- [ ] No duplicated year selector
- [ ] Subject list data backed

### S015 — Nested Folder Explorer

**Decision:** Q07 C+D  
**Route/location:** `study nested routes • audit`  
**Design intent:** Recursive folder navigation with breadcrumbs and custom folder-icon cards until terminal leaf.  
**Illustrative mockup:** ![Nested Folder Explorer](SCREEN_MOCKUPS/S015_Nested_Folder_Explorer.png)

**Visual hierarchy and exact layout**

- Compact top breadcrumb clickable path
- Two-column/flexible folder cards with selected custom folder icon
- Only actual nested folder names; file mixed content handled not hidden

**User actions and navigation**

- Open folder, jump to breadcrumb ancestor, back preserves scroll, optional sort

**Loading, empty, errors and permission states**

- Empty subfolder, permission denied, deep nesting, partial offline tree

**Animations and feedback:** Folder transition fades, no long cascading animations

**Implementation / data rules:** Keep actual full storage path and stable IDs; do not arbitrarily flatten hierarchy.

**Acceptance conditions**

- [ ] Recursive folder drill-down works
- [ ] Breadcrumb restores location
- [ ] Real item counts

### S016 — PDF Leaf Gallery

**Decision:** Q07 custom  
**Route/location:** `study terminal folder • audit`  
**Design intent:** Terminal study folder shows **real PDF first-page image thumbnails** in two-column grid with filename.  
**Illustrative mockup:** ![PDF Leaf Gallery](SCREEN_MOCKUPS/S016_PDF_Leaf_Gallery.png)

**Visual hierarchy and exact layout**

- Breadcrumb with folder title
- Two-column thumbnail cards, real page-one preview image, filename and minimal metadata
- Tap opens Immersive Reader

**User actions and navigation**

- Open PDF, long-press supported actions, optional download for offline

**Loading, empty, errors and permission states**

- Preview generation/loading/failure; fallback marked as unable to preview, not fake image

**Animations and feedback:** Real thumbnails fade in after generation and caching

**Implementation / data rules:** Thumbnails generated from file/document content; cache keyed by PDF revision.

**Acceptance conditions**

- [ ] Real first-page previews
- [ ] File name readable
- [ ] No mocked thumbnail

### S017 — Immersive Smart PDF Reader

**Decision:** Q08 C Q09 B+D+A  
**Route/location:** `/viewer, /imported-viewer, /pdf-studio/viewer/:fileId`  
**Design intent:** Distraction-free PDF view with visible full page, pinch-zoom and tap-reveal controls.  
**Illustrative mockup:** ![Immersive Smart PDF Reader](SCREEN_MOCKUPS/S017_Immersive_Smart_PDF_Reader.png)

**Visual hierarchy and exact layout**

- PDF canvas full screen with overlay auto-hiding
- Bottom quick-action floating dock Search/Pages/Bookmark/More
- Dock collapses into small Deep Teal page-number pill, tap to reopen

**User actions and navigation**

- Zoom, scroll, select pages, search within opened PDF, bookmark, toggle tools, reader back

**Loading, empty, errors and permission states**

- Protected/corrupt files, missing offline copy, search empty, zoom/performance large PDF

**Animations and feedback:** Fast overlay slide/fade with reduced motion; no focus-changing animation while reading

**Implementation / data rules:** Study source read-only; edit a safe copy; maintain original native/pdf viewer behavior.

**Acceptance conditions**

- [ ] No loss of reading position
- [ ] Dock collapse/expand works
- [ ] Reader search true

### S018 — Reader More Tools Sheet

**Decision:** Q09 D Q14  
**Route/location:** `PDF reader overlay`  
**Design intent:** Categorized full-width bottom sheet for advanced reader actions, separate from compact dock.  
**Illustrative mockup:** ![Reader More Tools Sheet](SCREEN_MOCKUPS/S018_Reader_More_Tools_Sheet.png)

**Visual hierarchy and exact layout**

- Grouped headings: View/Navigation, Search/Bookmarks, Share/Save/Download if supported, Edit a Copy
- Distinct icons and clear enabled/disabled affordances
- Drag handle and Close

**User actions and navigation**

- Open safe supported tool, close on overlay/back, present copy-edit option

**Loading, empty, errors and permission states**

- Unavailable actions explicitly not present or disabled with reason

**Animations and feedback:** Bottom sheet rises with short standard easing and preserved PDF scroll position

**Implementation / data rules:** Do not claim true PDF text editing/signature features if unavailable.

**Acceptance conditions**

- [ ] Reader state not reset by opening tools
- [ ] No unsupported actions

### S019 — Lecture Viewer Compatibility

**Decision:** Existing route + Q05–Q09  
**Route/location:** `/lectures`  
**Design intent:** Preserve currently supported lecture discovery/reader under new design system.  
**Illustrative mockup:** ![Lecture Viewer Compatibility](SCREEN_MOCKUPS/S019_Lecture_Viewer_Compatibility.png)

**Visual hierarchy and exact layout**

- Clean header and breadcrumb, lecture resources following existing access rules
- Actual lecture media/PDF preview and metadata
- Open/download actions only if supported

**User actions and navigation**

- Open lecture, return, download/view per existing behavior

**Loading, empty, errors and permission states**

- Empty lectures, offline file missing, permission issue

**Animations and feedback:** Subtle row/button feedback; no reimagined unsupported lecture player

**Implementation / data rules:** Fresh repo audit establishes actual lecture types and backend.

**Acceptance conditions**

- [ ] Legacy route stays functional
- [ ] Existing lectures not lost


## 03 • PDF Studio / Offline

### S020 — PDF Studio Workspace

**Decision:** Q10 B+D  
**Route/location:** `/pdf-studio`  
**Design intent:** Professional File Workspace, not a game-like dashboard; Scan and Create foremost.  
**Illustrative mockup:** ![PDF Studio Workspace](SCREEN_MOCKUPS/S020_PDF_Studio_Workspace.png)

**Visual hierarchy and exact layout**

- Top PDF Studio heading/search
- Primary Scan Document and Create PDF controls
- Recent Activity actual list, file management actions, folders if supported

**User actions and navigation**

- Scan, create/import, open file, rename/delete/share where existing or properly implemented

**Loading, empty, errors and permission states**

- No documents, unavailable file, save error, storage permission

**Animations and feedback:** Minimal card interactions; recent rows animate only after real updates

**Implementation / data rules:** Preserve local DB/files, avoid duplicate recent activity without persistent source.

**Acceptance conditions**

- [ ] Real document list
- [ ] Create/scan accessible
- [ ] No data deletion on redesign

### S021 — Precision Smart Scanner Camera

**Decision:** Q11 B+C  
**Route/location:** `custom native Android camera screen`  
**Design intent:** Replace slow Google document-scanner UX only with tested native camera + on-device edge detection.  
**Illustrative mockup:** ![Precision Smart Scanner Camera](SCREEN_MOCKUPS/S021_Precision_Smart_Scanner_Camera.png)

**Visual hierarchy and exact layout**

- Full-camera live document view with stable quadrilateral four-corner overlay
- Auto/Manual capture, flash, capture status/counter, shutter
- Horizontal bottom thumbnail strip of captured pages, Done to review

**User actions and navigation**

- Auto or manual shutter, toggle flash, retake, capture multiple pages, open review

**Loading, empty, errors and permission states**

- Camera permission denial, poor lighting, no edges, rotation, glare, blurred shot, backgrounding

**Animations and feedback:** Subtle success capture ripple, overlay movement damped; no camera-frame jank

**Implementation / data rules:** Native Kotlin CameraX/OpenCV or vetted equivalent after audit; preserve existing scanner until parity.

**Acceptance conditions**

- [ ] Real device camera tests
- [ ] Crop corners accurate
- [ ] Multi-page state survives interruption

### S022 — Scan Page Review Hub

**Decision:** Q12 D  
**Route/location:** `scanner review`  
**Design intent:** After capture, all pages appear in manageable grid with reorder/delete/rotate actions.  
**Illustrative mockup:** ![Scan Page Review Hub](SCREEN_MOCKUPS/S022_Scan_Page_Review_Hub.png)

**Visual hierarchy and exact layout**

- Large Page Review title and page count
- 2-column page thumbnail grid, drag reorder handles, selection
- Bottom Edit, Add Page, Continue to Export primary actions

**User actions and navigation**

- Reorder, rotate, delete with confirmation, rescan/add, save drafts

**Loading, empty, errors and permission states**

- No pages, failed thumbnail, accidental deletion, app lifecycle/background

**Animations and feedback:** Responsive drag feedback and subtle page replacement

**Implementation / data rules:** Changes non-destructively stored until confirmed; draft-safe snapshots.

**Acceptance conditions**

- [ ] Pages ordered as exported
- [ ] Delete undo/recover if supported
- [ ] No lost draft

### S023 — Four-Corner Manual Crop Editor

**Decision:** Q12 B  
**Route/location:** `scanner crop editor`  
**Design intent:** Dedicated perspective crop UI with drag handles and zoom magnifier for precision.  
**Illustrative mockup:** ![Four-Corner Manual Crop Editor](SCREEN_MOCKUPS/S023_Four_Corner_Manual_Crop_Editor.png)

**Visual hierarchy and exact layout**

- Document fills crop canvas; four draggable high-contrast corners
- Auto Redetect, Reset, Rotate controls
- Cancel and Apply with preview

**User actions and navigation**

- Drag corners, pinch magnifier if suitable, revert, apply warp

**Loading, empty, errors and permission states**

- Corners outside image, invalid quadrilateral, extreme perspective, low confidence

**Animations and feedback:** Smooth but precise handle movement; no interpolated crop distortion during drag

**Implementation / data rules:** Transform mathematically valid; original unmodified retained for recovery.

**Acceptance conditions**

- [ ] Correct perspective crop
- [ ] Cancelable edit
- [ ] Original retained

### S024 — Enhancement / Filter Studio

**Decision:** Q12 C  
**Route/location:** `scanner filter editor`  
**Design intent:** Controlled image improvements optimized for readability, not cosmetic overprocessing.  
**Illustrative mockup:** ![Enhancement / Filter Studio](SCREEN_MOCKUPS/S024_Enhancement_Filter_Studio.png)

**Visual hierarchy and exact layout**

- Large scanned page preview
- Horizontal preset chips Original, Magic, B&W, Grayscale
- Brightness/Contrast adjust controls; Apply to This Page / All

**User actions and navigation**

- Select preset, compare before/after, adjust sliders, apply per-page/all, undo

**Loading, empty, errors and permission states**

- Low quality, unsupported filter, multi-page processing in progress

**Animations and feedback:** Crossfade before/after and accessible feedback without blocking navigation

**Implementation / data rules:** Non-destructive transformations and memory-efficient preview/cache.

**Acceptance conditions**

- [ ] Original recoverable
- [ ] Apply All consistent
- [ ] No color clipping beyond defined limits

### S025 — PDF Export Bottom Sheet

**Decision:** Q13 D+B  
**Route/location:** `scanner export`  
**Design intent:** Compact export sheet first, with optional advanced settings rather than full-screen clutter.  
**Illustrative mockup:** ![PDF Export Bottom Sheet](SCREEN_MOCKUPS/S025_PDF_Export_Bottom_Sheet.png)

**Visual hierarchy and exact layout**

- Filename and number of pages, PDF as explicit output
- Quality/compression and page size under Advanced Settings
- Local save destination, export progress; real optional OCR only if supported

**User actions and navigation**

- Edit name, export, expand details, handle duplicate filename

**Loading, empty, errors and permission states**

- Insufficient storage, permissions, export failure, cancellation and retry

**Animations and feedback:** Bottom sheet standard motion and nonblocking progress with real values

**Implementation / data rules:** Do not promise cloud destinations or multilingual OCR without verified provider.

**Acceptance conditions**

- [ ] Saved PDF opens correctly
- [ ] Page order intact
- [ ] No phantom success

### S026 — PDF Saved Success

**Decision:** Q13 C  
**Route/location:** `post-export screen`  
**Design intent:** Confirmation only after successful local PDF write and index update.  
**Illustrative mockup:** ![PDF Saved Success](SCREEN_MOCKUPS/S026_PDF_Saved_Success.png)

**Visual hierarchy and exact layout**

- Original branded save-success icon/character
- Saved filename/path and page count
- Open, Share, Save to Device buttons where supported

**User actions and navigation**

- Open in reader, share via Android share sheet, open file location if supported

**Loading, empty, errors and permission states**

- Share target missing, canceled save, invalid PDF

**Animations and feedback:** One gentle success animation and reduced motion equivalent

**Implementation / data rules:** File save status tied to actual filesystem operation; prevent duplicate export.

**Acceptance conditions**

- [ ] Success after write complete
- [ ] Open/share from true file
- [ ] No duplicate item

### S027 — PDF Editor Workspace

**Decision:** Q14 C+D+A  
**Route/location:** `/create-pdf and existing editor routes`  
**Design intent:** Adobe-inspired floating editing controls without claiming enterprise PDF authoring features.  
**Illustrative mockup:** ![PDF Editor Workspace](SCREEN_MOCKUPS/S027_PDF_Editor_Workspace.png)

**Visual hierarchy and exact layout**

- Document canvas with independent Read/Edit states
- Collapsible floating edit shortcut rail, More grouped tools sheet
- Contextual bottom controls for drawing thickness, opacity, color and active tool

**User actions and navigation**

- Select/edit tool, change brush, annotate, undo/redo, save new copy, collapse rail

**Loading, empty, errors and permission states**

- Unsupported PDF, protected original resource, unsaved changes, crash draft recovery

**Animations and feedback:** Floating dock compresses/reveals quickly, context controls adjust naturally

**Implementation / data rules:** Study originals preserved, edits on a safe copy; no invented certified signatures/full original-text edit.

**Acceptance conditions**

- [ ] Actual annotation persisted
- [ ] Undo/redo safe
- [ ] Editing never destroys original

### S028 — Create PDF / Import Content

**Decision:** Q10 Q13 Q14  
**Route/location:** `/create-pdf`  
**Design intent:** Clean PDF creation flow from supported camera/images/documents.  
**Illustrative mockup:** ![Create PDF / Import Content](SCREEN_MOCKUPS/S028_Create_PDF_Import_Content.png)

**Visual hierarchy and exact layout**

- Create PDF title and real input choices Camera/Images/Files if supported
- Selected pages preview/reorder
- Continue to same export settings as scanner

**User actions and navigation**

- Add images/files, reorder, cancel, export; preserve existing importer routes

**Loading, empty, errors and permission states**

- Unsupported format, oversized file, missing permission, interrupted import

**Animations and feedback:** Import previews fade in when ready

**Implementation / data rules:** Maintain existing create/import behavior; no fabricated Word-to-PDF format support.

**Acceptance conditions**

- [ ] Input retained
- [ ] Export valid
- [ ] No feature regression

### S029 — Downloads • Saved / In Progress / Failed

**Decision:** Q20 B+A  
**Route/location:** `/downloads`  
**Design intent:** Smart Offline Library management with compact honest download rows.  
**Illustrative mockup:** ![Downloads • Saved / In Progress / Failed](SCREEN_MOCKUPS/S029_Downloads_Saved_In_Progress_Failed.png)

**Visual hierarchy and exact layout**

- Tabbed top navigation Saved / In Progress / Failed
- Search and compact file row with actual progress/retry
- Saved tab leads into nested resource/subject/folder hierarchy

**User actions and navigation**

- Open saved, retry failure, cancel download, remove offline copy safely

**Loading, empty, errors and permission states**

- 0 saved, interrupted/background download, network offline, permission error

**Animations and feedback:** Animated progress based only on real network bytes; subtle retry feedback

**Implementation / data rules:** Persist transfer job state; deleting cached copy never removes source document.

**Acceptance conditions**

- [ ] Downloads survive restart
- [ ] Failure retry works
- [ ] Source never deleted

### S030 — Offline Nested Library & PDF Gallery

**Decision:** Q20 C  
**Route/location:** `Downloads saved folders`  
**Design intent:** Saved-only resource→subject→nested folders→real PDF leaf thumbnail hierarchy.  
**Illustrative mockup:** ![Offline Nested Library & PDF Gallery](SCREEN_MOCKUPS/S030_Offline_Nested_Library_PDF_Gallery.png)

**Visual hierarchy and exact layout**

- Breadcrumb from Downloads / resource / subject
- Compact folders using Study icon family
- Two-column real first-page downloaded PDF previews at terminal leaf

**User actions and navigation**

- Navigate offline, open local PDF, remove copy, return to folder

**Loading, empty, errors and permission states**

- Only items actually saved locally appear; corrupted cache error and retry

**Animations and feedback:** Low-motion transitions and cached thumbnails load instantly where possible

**Implementation / data rules:** Match Study folder tree via stable ancestry metadata; local DB ensures listing offline.

**Acceptance conditions**

- [ ] Airplane mode navigation succeeds
- [ ] No placeholders for unsaved files

### S031 — Storage & Cleanup

**Decision:** Q20 D  
**Route/location:** `Settings → Storage`  
**Design intent:** Storage usage and safe offline clean-up tools housed only in Settings, not Downloads primary tab.  
**Illustrative mockup:** ![Storage & Cleanup](SCREEN_MOCKUPS/S031_Storage_Cleanup.png)

**Visual hierarchy and exact layout**

- Local used space and breakdown based on real bytes
- Remove unused downloads, failed transfer entries; confirmation
- Explain removal of local copy vs source

**User actions and navigation**

- Review cleanup, confirm, cancel, view storage details

**Loading, empty, errors and permission states**

- Unknown storage stats, locked/in-use PDF, failure to delete

**Animations and feedback:** Controlled progress and safe success feedback

**Implementation / data rules:** Do not erase source academic content, active scanner drafts or user files accidentally.

**Acceptance conditions**

- [ ] Storage metrics correct
- [ ] Bulk actions reversible where feasible


## 04 • Profile / Settings

### S032 — Student Profile Overview

**Decision:** Q16 C+A+D+B Q33  
**Route/location:** `/profile`  
**Design intent:** Elegant academic identity overview with Personal / Academic / Security sections.  
**Illustrative mockup:** ![Student Profile Overview](SCREEN_MOCKUPS/S032_Student_Profile_Overview.png)

**Visual hierarchy and exact layout**

- Top user avatar or selected premade avatar and academic identity card
- Personal/Academic/Security tabs or equivalent accessible segmented UI
- Edit Profile separate action, competitive public profile separate from private fields

**User actions and navigation**

- View sections, open Edit Profile, change photo/avatar, My Year

**Loading, empty, errors and permission states**

- Missing profile photo uses chosen avatar/default; partial profile fields honest

**Animations and feedback:** Smooth tab transitions, subtle header entrance, reduced-motion support

**Implementation / data rules:** No roll number/contact exposure to leaderboard; use real profile source.

**Acceptance conditions**

- [ ] Academics reflect current year
- [ ] Selected avatar persists
- [ ] Security actions backed

### S033 — Edit Profile — Personal / Academic / Security

**Decision:** Q16 D+B  
**Route/location:** `/profile/edit`  
**Design intent:** Dedicated editable screen with categorized tabs and preview/save behavior.  
**Illustrative mockup:** ![Edit Profile — Personal / Academic / Security](SCREEN_MOCKUPS/S033_Edit_Profile_Personal_Academic_Security.png)

**Visual hierarchy and exact layout**

- Name and allowed personal fields
- University / Professional Year (and private roll number where existing)
- Security tab links to safe Security & Account settings

**User actions and navigation**

- Edit, validate, Save, Cancel, navigate tabs with unsaved-changes confirmation

**Loading, empty, errors and permission states**

- Missing permission, duplicate username, field validation, network conflict

**Animations and feedback:** Short save feedback only after backend confirms

**Implementation / data rules:** Respect existing auth uniqueness/backend rules; changing year reruns Study filter.

**Acceptance conditions**

- [ ] Edits persist
- [ ] Back preserves unsaved changes prompt
- [ ] No PII to public route

### S034 — Avatar & Photo Picker

**Decision:** Q16 B Q33 custom  
**Route/location:** `profile avatar picker`  
**Design intent:** User may upload a real photo OR choose premade original curated avatar; neither is mandatory.  
**Illustrative mockup:** ![Avatar & Photo Picker](SCREEN_MOCKUPS/S034_Avatar_Photo_Picker.png)

**Visual hierarchy and exact layout**

- Top preview circle large enough to see art
- Tabs: Premade Avatars / Upload Photo
- Grid of academic and contemporary Gen-Z friendly original avatars; crop/preview/save for photos

**User actions and navigation**

- Select premade, import photo, crop, preview light/dark, confirm, revert

**Loading, empty, errors and permission states**

- No gallery permission, unsupported image, upload failure, missing internet

**Animations and feedback:** Card tap scale/selection ring, gentle updated-avatar reveal

**Implementation / data rules:** Store stable avatar ID vs uploaded URL; avoid gender stereotypes; optimized licensed assets.

**Acceptance conditions**

- [ ] Avatar persists across login
- [ ] Works without photo
- [ ] Correct public/private mapping

### S035 — Settings Landing — My Workspace

**Decision:** Q15 D+C  
**Route/location:** `/settings`  
**Design intent:** Searchable organized settings categories with tall dark-Slate centered My Workspace hero.  
**Illustrative mockup:** ![Settings Landing — My Workspace](SCREEN_MOCKUPS/S035_Settings_Landing_My_Workspace.png)

**Visual hierarchy and exact layout**

- Tall Slate identity card: avatar **above centered display name**
- Edit Profile and My Year buttons within/below identity hero
- Your Preferences cards below, Security & Account group, then Appearance/Storage/Downloads/Support

**User actions and navigation**

- Search settings, enter subpages, change available values, sign out as supported

**Loading, empty, errors and permission states**

- Unconfigured security feature explicitly not live, unavailable sync state

**Animations and feedback:** Tactile setting-row feedback, limited hero motion

**Implementation / data rules:** Do not put avatar alongside name in card (user explicitly chose vertical centered layout).

**Acceptance conditions**

- [ ] Correct hero geometry
- [ ] Settings search finds only existing actions

### S036 — Appearance & Accessibility

**Decision:** Q02 Q29 D Q31  
**Route/location:** `Settings → Appearance`  
**Design intent:** User-selectable Light / Dark / System modes, readability and reduced-motion preferences.  
**Illustrative mockup:** ![Appearance & Accessibility](SCREEN_MOCKUPS/S036_Appearance_Accessibility.png)

**Visual hierarchy and exact layout**

- Three meaningful theme options with small preview tiles
- Text scaling, motion preference and helpful explanations
- Contrast-safe states consistent with Slate/Teal colors

**User actions and navigation**

- Set theme, preview immediately, restore System, reduce animation

**Loading, empty, errors and permission states**

- System auto switch, accessibility high text scale, low contrast, missing saved value

**Animations and feedback:** Live theme crossfade only when permitted; reduced-motion instant switch

**Implementation / data rules:** No hard-coded light cards that become unreadable in dark mode.

**Acceptance conditions**

- [ ] All screens honor theme
- [ ] Text fits at enlarged scale
- [ ] Screen readers label controls

### S037 — Security & Account

**Decision:** Q15 Security Q16  
**Route/location:** `Settings → Security & Account`  
**Design intent:** Organized future-safe security grouping: App Lock, Change Password, Change Username.  
**Illustrative mockup:** ![Security & Account](SCREEN_MOCKUPS/S037_Security_Account.png)

**Visual hierarchy and exact layout**

- List with clear descriptions and lock/credential icons
- Actual implemented actions enabled; planned unavailable actions marked without deceptive controls
- Recovery/verification links only if real

**User actions and navigation**

- Navigate existing authorized security flow; explain disabled planned actions

**Loading, empty, errors and permission states**

- Reauthentication required, old password incorrect, recovery errors

**Animations and feedback:** Subtle success acknowledgment after server response

**Implementation / data rules:** Detailed security, verification and recovery mechanics were deliberately not finalized; Claude must audit first and request approvals.

**Acceptance conditions**

- [ ] Cannot falsely change credentials
- [ ] Sensitive actions protected


## 05 • Shop / Content

### S038 — Shop Home & Product Catalog

**Decision:** Q18 A+B+D  
**Route/location:** `/shop`  
**Design intent:** Small editorial Shop feature banner followed immediately by usable product catalog.  
**Illustrative mockup:** ![Shop Home & Product Catalog](SCREEN_MOCKUPS/S038_Shop_Home_Product_Catalog.png)

**Visual hierarchy and exact layout**

- Compact editorial hero with licensed image; real categories/search/filter
- Clean product cards with actual images, names, price and availability
- Cart icon badge reflects actual cart

**User actions and navigation**

- Browse products, filter, search, add supported variant/quantity, open detail

**Loading, empty, errors and permission states**

- Sold out, missing images, slow network, empty catalog and price changes

**Animations and feedback:** Very subtle add-to-cart, image fade-in and badge count feedback

**Implementation / data rules:** Never invent stock, prices, shipping or checkout provider; preserve actual Shop data.

**Acceptance conditions**

- [ ] Pricing matches backend
- [ ] Cart totals accurate
- [ ] Shop still usable on narrow screens

### S039 — Product Detail

**Decision:** Q18 B  
**Route/location:** `/shop/p/:id`  
**Design intent:** Uncluttered product detail with rich photos and transparent purchase information.  
**Illustrative mockup:** ![Product Detail](SCREEN_MOCKUPS/S039_Product_Detail.png)

**Visual hierarchy and exact layout**

- Real product image gallery above concise name/price
- Variant/size/quantity selection only if product supports
- Description, availability, add-to-cart footer

**User actions and navigation**

- Select variant, increment quantity within stock, Add to Cart, return

**Loading, empty, errors and permission states**

- Product removed, unavailable variant, failed cart mutation, missing stock

**Animations and feedback:** Tap/thumbnail feedback and small add-to-cart confirmation

**Implementation / data rules:** No fictitious reviews/ratings, returns policies or delivery promises.

**Acceptance conditions**

- [ ] Valid variant controls
- [ ] Correct cart line item
- [ ] Back restores position

### S040 — Shopping Cart

**Decision:** Q18 B+D  
**Route/location:** `/cart`  
**Design intent:** Compact cart rows and transparent cost summary linked to current backend pricing.  
**Illustrative mockup:** ![Shopping Cart](SCREEN_MOCKUPS/S040_Shopping_Cart.png)

**Visual hierarchy and exact layout**

- Product thumbnail, name, variant, quantity controls and remove
- Subtotal / supported charges / total only from actual checkout
- Proceed to Checkout prominent

**User actions and navigation**

- Adjust quantity, remove/undo if supported, checkout

**Loading, empty, errors and permission states**

- Empty cart, out-of-stock, price changed, server sync conflict

**Animations and feedback:** Micro quantity changes and cart updates without jumping layout

**Implementation / data rules:** No fabricated checkout totals; existing guest/auth behavior audited.

**Acceptance conditions**

- [ ] Totals consistent
- [ ] Unavailable items blocked
- [ ] No silent item deletion

### S041 — Guided Checkout

**Decision:** Q18 D  
**Route/location:** `/checkout`  
**Design intent:** Stepwise review of delivery/customer/payment method **only when currently supported**.  
**Illustrative mockup:** ![Guided Checkout](SCREEN_MOCKUPS/S041_Guided_Checkout.png)

**Visual hierarchy and exact layout**

- Compact progress with Customer → Delivery → Review (actual steps vary)
- Validated address/contact inputs and honest shipping/payment options
- Order summary with confirm action

**User actions and navigation**

- Next/back retain input, choose real payment method, submit once

**Loading, empty, errors and permission states**

- Address invalid, stock changed, payment/ordering failed, slow network

**Animations and feedback:** Progress and action feedback, not excessive celebration

**Implementation / data rules:** Existing Shop checkout distinct from prohibited Quiz wallet/contest fees.

**Acceptance conditions**

- [ ] No duplicate orders
- [ ] Accurate final charges
- [ ] Confirmation server-verified

### S042 — Order Success

**Decision:** Q18 D Q29  
**Route/location:** `/order-success`  
**Design intent:** Confirmed order screen with genuine order number/status, nothing fabricated.  
**Illustrative mockup:** ![Order Success](SCREEN_MOCKUPS/S042_Order_Success.png)

**Visual hierarchy and exact layout**

- Branded success illustration
- Order ID and receipt summary only if returned
- View My Orders, Continue Shopping actions

**User actions and navigation**

- Open order detail/history, continue browsing

**Loading, empty, errors and permission states**

- Payment pending vs order placed must be differentiated

**Animations and feedback:** Short checkmark/parcel motion and reduced motion version

**Implementation / data rules:** Do not infer shipment or delivery estimate.

**Acceptance conditions**

- [ ] Only after real accepted order
- [ ] Back doesn’t resubmit

### S043 — My Orders & Order Detail

**Decision:** Q18 D  
**Route/location:** `/orders`  
**Design intent:** Purchase history with clear live status and drill-down.  
**Illustrative mockup:** ![My Orders & Order Detail](SCREEN_MOCKUPS/S043_My_Orders_Order_Detail.png)

**Visual hierarchy and exact layout**

- Compact chronology cards and order search/filter if backend supports
- Order detail lists items, amounts, status and next supported action
- No fake tracking button

**User actions and navigation**

- View details, contact support/reorder only if existing

**Loading, empty, errors and permission states**

- No orders, cancellation/failure, network sync stale

**Animations and feedback:** Subtle status highlight and list transitions

**Implementation / data rules:** Use backend order state, never infer shipping progress.

**Acceptance conditions**

- [ ] Prior orders unchanged
- [ ] Correct authorization per user

### S044 — Notification Center

**Decision:** Q21 B+A+C+D selective  
**Route/location:** `/notifications`  
**Design intent:** Categorized real Academic / Announcements / Orders feeds with compact chronological rows.  
**Illustrative mockup:** ![Notification Center](SCREEN_MOCKUPS/S044_Notification_Center.png)

**Visual hierarchy and exact layout**

- Category tabs, read/unread state
- Featured important announcement only when genuine
- Overflow Mark Read and Archive/Delete only if supported

**User actions and navigation**

- Open source item, mark read, supported long press/menu operations

**Loading, empty, errors and permission states**

- No notifications, read sync conflict, blocked category or offline cached subset

**Animations and feedback:** Subtle unread indicator and viewed-row animation

**Implementation / data rules:** Separate admin broadcasts from user-specific notification data.

**Acceptance conditions**

- [ ] Unread count correct
- [ ] Announcements not duplicated fictitiously

### S045 — Announcements / Featured Message

**Decision:** Q21 C Q23  
**Route/location:** `Home / Notifications / Admin content`  
**Design intent:** Lightweight announcement detail with genuine importance and timestamps.  
**Illustrative mockup:** ![Announcements / Featured Message](SCREEN_MOCKUPS/S045_Announcements_Featured_Message.png)

**Visual hierarchy and exact layout**

- Featured compact announcement hero, headline, safe rich content and links
- Back to feed, related content links only if valid

**User actions and navigation**

- View announcement, open authorized attachment/link

**Loading, empty, errors and permission states**

- Expired or removed notice, unavailable attachment

**Animations and feedback:** Small expansion reveal only once

**Implementation / data rules:** Admin publishing controls must not expose draft notices.

**Acceptance conditions**

- [ ] Only published notices visible
- [ ] Correct audience filtering

### S046 — Blog Feed

**Decision:** Q22 A  
**Route/location:** `/blog`  
**Design intent:** Editorial academic Blog with tasteful small featured section and chronological real articles.  
**Illustrative mockup:** ![Blog Feed](SCREEN_MOCKUPS/S046_Blog_Feed.png)

**Visual hierarchy and exact layout**

- Compact feature image/card only when real featured article
- Article list with genuine thumbnail/title/excerpt/date
- Category/subject chips if content supports

**User actions and navigation**

- Open article, search/filter if supported

**Loading, empty, errors and permission states**

- No posts, missing cover, unpublish, network error

**Animations and feedback:** Image fade-in and subtle list reveal

**Implementation / data rules:** No fabricated articles or stock content.

**Acceptance conditions**

- [ ] Real published posts only
- [ ] Appropriate images and authors

### S047 — Blog Article Reader

**Decision:** Q22 B  
**Route/location:** `/blog/:id`  
**Design intent:** Distraction-free comfortable long-form article experience.  
**Illustrative mockup:** ![Blog Article Reader](SCREEN_MOCKUPS/S047_Blog_Article_Reader.png)

**Visual hierarchy and exact layout**

- Real cover, title, date/author if recorded
- Well-spaced headings, body, images and accessible captions
- Minimal back/share/bookmark controls only when real

**User actions and navigation**

- Read, scroll, share link where supported, return

**Loading, empty, errors and permission states**

- Missing unpublished article, failed remote image, offline

**Animations and feedback:** Gentle image reveal; no scroll hijacking

**Implementation / data rules:** Sanitize rich text and external embeds; avoid broken links.

**Acceptance conditions**

- [ ] Text accessible at scale
- [ ] Images alt text when possible

### S048 — About Hyzen

**Decision:** Q22 D + custom  
**Route/location:** `/about`  
**Design intent:** Founder-centric authentic About page: **real owner photo centered at top**, then **rectangular Slate→Teal gradient introduction card**.  
**Illustrative mockup:** ![About Hyzen](SCREEN_MOCKUPS/S048_About_Hyzen.png)

**Visual hierarchy and exact layout**

- Centered owner photo at top with clean background
- Immediately below: rectangular gradient intro card with actual owner bio
- Mission/academic context and links only with approved content

**User actions and navigation**

- Open supported socials/contact, return

**Loading, empty, errors and permission states**

- Founder photo or text unavailable -> omit gracefully; never invent owner identity/bio

**Animations and feedback:** Small photo and card reveal with reduced-motion equivalent

**Implementation / data rules:** Do not use unauthorized founder image or generated impersonation as real photo.

**Acceptance conditions**

- [ ] Owner photo centered
- [ ] Intro card rectangular
- [ ] Approved authentic text

### S049 — Contact Us

**Decision:** Q22 D  
**Route/location:** `/contact`  
**Design intent:** Reliable concise Contact form or supported actual contact channel.  
**Illustrative mockup:** ![Contact Us](SCREEN_MOCKUPS/S049_Contact_Us.png)

**Visual hierarchy and exact layout**

- Short header and category/subject, message, reply details
- Accessible validation and privacy note
- Send button with clear final status

**User actions and navigation**

- Submit existing form, launch official contact link if configured

**Loading, empty, errors and permission states**

- Validation, network failure, support unavailable, duplicate send

**Animations and feedback:** Submit loading then subtle real success, never fabricated sent state

**Implementation / data rules:** Use existing backend contact receiver; ensure PII handled properly.

**Acceptance conditions**

- [ ] True submission status
- [ ] No lost drafts
- [ ] Contact destination verified


## 06 • Campus League

### S050 — Campus League Landing

**Decision:** Q24 custom Q26 Q30 B  
**Route/location:** `Home Quick Access → new League route (audit)`  
**Design intent:** New separate competitive learning section reached from Home, **not** a fifth navigation tab.  
**Illustrative mockup:** ![Campus League Landing](SCREEN_MOCKUPS/S050_Campus_League_Landing.png)

**Visual hierarchy and exact layout**

- TOP dark-Slate Join Community card with real configured link
- Standard/Special segmented selector and current/upcoming event card with Register
- Below: Campus Rankings My Year/My University/Overall; MCQ Duels & My Performance

**User actions and navigation**

- Join legitimate community, switch tabs, open event, ranking or duels

**Loading, empty, errors and permission states**

- Feature disabled, community link missing, no upcoming quiz, eligibility unknown

**Animations and feedback:** Small badge/card reveal and tab motion with server states

**Implementation / data rules:** No monetary price/reward/free/paid labels; hidden feature modules obey server flag and compliance hold.

**Acceptance conditions**

- [ ] Campus reachable Home
- [ ] No fifth tab
- [ ] Real event only

### S051 — Standard Quiz Listing & Upcoming Card

**Decision:** Q26 Q28  
**Route/location:** `League → Standard`  
**Design intent:** Standard accessible subject-specific academic quiz list; users see relevant Professional Year.  
**Illustrative mockup:** ![Standard Quiz Listing & Upcoming Card](SCREEN_MOCKUPS/S051_Standard_Quiz_Listing_Upcoming_Card.png)

**Visual hierarchy and exact layout**

- Standard header, current quiz date/topic/subject (ONE subject only)
- Register/Join or Resume only when eligible
- Attempts remaining and 1-hour cooldown truthful status when available

**User actions and navigation**

- Register according to actual rules, view details, resume active attempt

**Loading, empty, errors and permission states**

- No quiz scheduled, 3/day exhausted, cooldown active, questions exhausted

**Animations and feedback:** Compact CTA availability/disabled transition

**Implementation / data rules:** Question bank subject/year filtering enforced server-side; no fee labels.

**Acceptance conditions**

- [ ] Only one subject displayed
- [ ] 3/day max and cooldown accurate

### S052 — Special Quiz Listing & Mixed-Subject Card

**Decision:** Q26 Q28 + amendments  
**Route/location:** `League → Special`  
**Design intent:** Special community-announced academic event card with TWO OR MORE admin-selected subjects and ONE attempt.  
**Illustrative mockup:** ![Special Quiz Listing & Mixed-Subject Card](SCREEN_MOCKUPS/S052_Special_Quiz_Listing_Mixed_Subject_Card.png)

**Visual hierarchy and exact layout**

- Special event title, targeted Professional Year(s), list of selected subjects/topics
- Real date/start-end, countdown and current registration status
- View/Request Registration action; no monetary or reward labels

**User actions and navigation**

- Open competition details, request registration if eligible, view pending/approved status

**Loading, empty, errors and permission states**

- Compliance-blocked event must not be accessible/registrable; no published event fallback

**Animations and feedback:** Restrained countdown change and state swap

**Implementation / data rules:** If external fees plus cash prizes, app facilitation blocked without legal/Play approval even if money absent in UI.

**Acceptance conditions**

- [ ] Mixed subjects clearly listed
- [ ] Single attempt
- [ ] Blocked contests inaccessible

### S053 — Quiz Competition Details

**Decision:** Q26 B+C  
**Route/location:** `League → Event Details`  
**Design intent:** Transparent event details page before registration or quiz start.  
**Illustrative mockup:** ![Quiz Competition Details](SCREEN_MOCKUPS/S053_Quiz_Competition_Details.png)

**Visual hierarchy and exact layout**

- Title/type and academic audience
- Real calendar/timezone, subjects/topics, question count, duration, attempts and start-end window
- Live countdown if scheduled; clear eligibility/rules link

**User actions and navigation**

- Review rules, register if allowed, join when server permits

**Loading, empty, errors and permission states**

- Not yet open, closed, registration full, missing policy, scheduled date moved

**Animations and feedback:** Simple countdown with no blinking, reduced motion

**Implementation / data rules:** Show only actually configured policies, not fabricated scores/rewards.

**Acceptance conditions**

- [ ] Real event metadata
- [ ] Correct timer and closed/open states

### S054 — Special Registration Form

**Decision:** Q26 D Q25 privacy  
**Route/location:** `League → Special → Register`  
**Design intent:** Private admin-review registration prefilled from real student profile; user reviews before submit.  
**Illustrative mockup:** ![Special Registration Form](SCREEN_MOCKUPS/S054_Special_Registration_Form.png)

**Visual hierarchy and exact layout**

- Step header Personal / Academic / Confirm
- Full name, email, phone/WhatsApp, roll number privately reviewed
- Quiz title and rules, explicit consent and Submit Registration

**User actions and navigation**

- Verify/edit permitted data, submit once, inspect privacy note, back/cancel

**Loading, empty, errors and permission states**

- Profile missing fields, duplicate request, network loss, registration closed

**Animations and feedback:** Step progress and submit progress; no false instant approval

**Implementation / data rules:** Admin-only fields protected; no display of roll number in public profile, leaderboard, search logs.

**Acceptance conditions**

- [ ] One request per student/event
- [ ] Status correct
- [ ] Private data properly scoped

### S055 — Registration Status / Countdown

**Decision:** Q26 C+D  
**Route/location:** `League → Registration Status`  
**Design intent:** Registration result and event readiness page with real Pending/Approved/Rejected/Closed states.  
**Illustrative mockup:** ![Registration Status / Countdown](SCREEN_MOCKUPS/S055_Registration_Status_Countdown.png)

**Visual hierarchy and exact layout**

- Academic competition summary and status tile
- Countdown until scheduled start; subject list and join eligibility
- Contact organizer only via vetted real channel, no fee collecting CTA

**User actions and navigation**

- Refresh status, re-check scheduling, Start when approved/window open

**Loading, empty, errors and permission states**

- Approval reversed, rescheduled event, compliance blocked, network offline

**Animations and feedback:** Status/clock updates without jitter; no celebratory success before approval

**Implementation / data rules:** Cannot start Special with status pending/rejected; server decides eligibility.

**Acceptance conditions**

- [ ] Start gated by approval
- [ ] Countdown accurate
- [ ] Blocked event inaccessible

### S056 — MCQ Exam — Focused Question

**Decision:** Q27 A+B+C+D  
**Route/location:** `League → Quiz Attempt`  
**Design intent:** Full-screen focused single-question exam with four large options and prominent server countdown.  
**Illustrative mockup:** ![MCQ Exam — Focused Question](SCREEN_MOCKUPS/S056_MCQ_Exam_Focused_Question.png)

**Visual hierarchy and exact layout**

- Header exam title, time left, progress Question X of N
- One actual MCQ plus four A–D option cards and Bookmark/Flag
- Previous / Save & Next; Navigator icon; Exit confirmation

**User actions and navigation**

- Select/change answer, flag, next/previous, open navigator, review final

**Loading, empty, errors and permission states**

- Network drop, expired time, double tap, crash restore, late submit, unknown answer

**Animations and feedback:** Quick option highlight and progress, no blocking wrong/correct reveal during timed exam

**Implementation / data rules:** Never bundle answer key/correct option to client while live; server authoritative time and attempt.

**Acceptance conditions**

- [ ] Same attempt after restart
- [ ] Timer cannot pause via client
- [ ] Answers preserved safely

### S057 — Question Navigator Bottom Sheet

**Decision:** Q27 C  
**Route/location:** `Exam → Navigator`  
**Design intent:** Grid navigation for Answered, Unanswered and Flagged states without losing timer.  
**Illustrative mockup:** ![Question Navigator Bottom Sheet](SCREEN_MOCKUPS/S057_Question_Navigator_Bottom_Sheet.png)

**Visual hierarchy and exact layout**

- Bottom sheet with 1..N numbered cells; teal answered, neutral unanswered, amber flagged
- Legend clearly communicates states beyond color
- Tap grid tile to navigate; Close/Review button

**User actions and navigation**

- Jump, mark flag, return to question, review unanswered

**Loading, empty, errors and permission states**

- Question count larger than viewport, narrow devices, screen readers

**Animations and feedback:** Bottom sheet standard eased animation; timer remains visible or clear

**Implementation / data rules:** Unanswered distinguishable to color-blind learners; preserve focus.

**Acceptance conditions**

- [ ] Status accurate
- [ ] Navigation does not reset answers
- [ ] Clock continues

### S058 — Review Answers & Confirm Submit

**Decision:** Q27 D  
**Route/location:** `Exam → Review/Submit`  
**Design intent:** Last checkpoint before final submission, with accurate counts and warning for unanswered.  
**Illustrative mockup:** ![Review Answers & Confirm Submit](SCREEN_MOCKUPS/S058_Review_Answers_Confirm_Submit.png)

**Visual hierarchy and exact layout**

- Answered/Unanswered/Flagged tallies and direct jump links
- Explicit Submit Test confirmation dialog
- Remaining time and notice that submitting closes attempt

**User actions and navigation**

- Review, return to MCQ, confirm exactly once, handle timeout forced submit

**Loading, empty, errors and permission states**

- Network failure during submit, conflicting second device, expired attempt

**Animations and feedback:** Subtle confirm sheet with haptics when enabled

**Implementation / data rules:** Idempotent server submission; never claim submitted if request unresolved.

**Acceptance conditions**

- [ ] Submit idempotent
- [ ] State recoverable
- [ ] Late attempt policy honest

### S059 — Quiz Result & Rank

**Decision:** Q27 D Q24  
**Route/location:** `League → Results`  
**Design intent:** Verified scorecard after server grade processing; ranking visible only when permitted by competition rules.  
**Illustrative mockup:** ![Quiz Result & Rank](SCREEN_MOCKUPS/S059_Quiz_Result_Rank.png)

**Visual hierarchy and exact layout**

- Compact celebratory crest and completion status
- Accuracy, correct count, time used and rank where verified
- Review explanations only after allowed release; standard next-attempt eligibility

**User actions and navigation**

- View rankings, retry Standard if eligible, close to League

**Loading, empty, errors and permission states**

- Pending grading, contest locked, ranking delayed, appeal/irregularity review

**Animations and feedback:** Small result reveal and count-up only if genuine and accessible

**Implementation / data rules:** Exact scoring formula/rank aggregation unresolved and must be approved before public leaderboard.

**Acceptance conditions**

- [ ] No invented rank
- [ ] Correct pending state
- [ ] No Special retake

### S060 — Campus Rankings • Scopes

**Decision:** Q24 A Q25  
**Route/location:** `League → Rankings`  
**Design intent:** Year, University and Overall leaderboards using opted-in public usernames.  
**Illustrative mockup:** ![Campus Rankings • Scopes](SCREEN_MOCKUPS/S060_Campus_Rankings_Scopes.png)

**Visual hierarchy and exact layout**

- Compact top-3 podium/leader highlight when enough real records
- My Year / My University / Overall segmented scopes
- Ranked rows with username, score/rank and open competition profile

**User actions and navigation**

- Switch scope, view consenting competitor, find own position

**Loading, empty, errors and permission states**

- No participants, unranked student, opt-out, delayed/under-review scores

**Animations and feedback:** Moderate score row transitions; avoid confetti on every refresh

**Implementation / data rules:** Never expose roll number, private full name, email, WhatsApp or payment info.

**Acceptance conditions**

- [ ] Ranking server derived
- [ ] Scope enforced
- [ ] Opt-out respected

### S061 — Public Competition Profile

**Decision:** Q25 A custom  
**Route/location:** `League → Student Profile`  
**Design intent:** Public-by-choice competition identity, not full academic/legal student profile.  
**Illustrative mockup:** ![Public Competition Profile](SCREEN_MOCKUPS/S061_Public_Competition_Profile.png)

**Visual hierarchy and exact layout**

- Avatar/premade icon, PUBLIC username, rank, score and permitted duel performance
- University/Year only if user explicitly permits
- Challenge button if mutual eligibility and opt-in

**User actions and navigation**

- Challenge, block/report if supported, return

**Loading, empty, errors and permission states**

- Hidden profile, blocked invites, ineligible year/topic

**Animations and feedback:** Subtle identity header and safe action confirmation

**Implementation / data rules:** Roll number, contacts, personal identifiers remain private in all API responses.

**Acceptance conditions**

- [ ] Public fields audited
- [ ] Permission-aware details
- [ ] No leaks

### S062 — Student Duel Discovery & Invitation

**Decision:** Q24/Q25 Duel  
**Route/location:** `League → Duels`  
**Design intent:** Opt-in student matching/selection with invitation and safety controls.  
**Illustrative mockup:** ![Student Duel Discovery & Invitation](SCREEN_MOCKUPS/S062_Student_Duel_Discovery_Invitation.png)

**Visual hierarchy and exact layout**

- Public opt-in competitors list with year/university filters only if consent
- Choose opponent and view duel topics/timer rules before invitation
- Send challenge; incoming invites Accept/Decline

**User actions and navigation**

- Find, invite, accept/decline, block and report, cancel if allowed

**Loading, empty, errors and permission states**

- No eligible players, invite expired, rapid invite abuse, blocked student

**Animations and feedback:** Short invitation sent status (actual server acknowledgement only)

**Implementation / data rules:** No forced public student directory. Rate limits and admin moderation required.

**Acceptance conditions**

- [ ] No spam to opted-out users
- [ ] Invitation state true
- [ ] Sensitive data hidden

### S063 — Timed MCQ Duel

**Decision:** Q24/Q25 Q27  
**Route/location:** `League → Active Duel`  
**Design intent:** Challenge-specific MCQ screen reuses focused exam components and server-secured timing.  
**Illustrative mockup:** ![Timed MCQ Duel](SCREEN_MOCKUPS/S063_Timed_MCQ_Duel.png)

**Visual hierarchy and exact layout**

- Opponent usernames, challenge topic(s), neutral progress/timer
- Same A–D question interaction and clear remaining questions
- Result pending after submit, not assuming other student finished

**User actions and navigation**

- Answer, submit, view post-duel score, return to history

**Loading, empty, errors and permission states**

- Opponent disconnects, match invalid, queue/cancel, duplicate duel session

**Animations and feedback:** Minimal challenge start/reveal, no gaming-heavy effects

**Implementation / data rules:** Duel scoring fairness and possible retry/rank impact remain decisions to approve; **no fees**.

**Acceptance conditions**

- [ ] Only eligible paired attempts
- [ ] Clock enforced
- [ ] Question secrecy intact

### S064 — Duel History & My Academic Performance

**Decision:** Q24 custom  
**Route/location:** `League → History / Performance`  
**Design intent:** Academic improvement view separated from monetary gamification.  
**Illustrative mockup:** ![Duel History & My Academic Performance](SCREEN_MOCKUPS/S064_Duel_History_My_Academic_Performance.png)

**Visual hierarchy and exact layout**

- Compact duel chronology, outcome/status and study topic
- Subject-wise accuracy, attempts, time trends from real completed events
- Clear distinction practice data vs published competition score

**User actions and navigation**

- Filter history, open verified result, review performance

**Loading, empty, errors and permission states**

- No attempts, pending opponent, under-review duel or unavailable metrics

**Animations and feedback:** Subtle chart/row reveal and skeletons

**Implementation / data rules:** Do not fabricate performance charts with insufficient data.

**Acceptance conditions**

- [ ] Accurate history
- [ ] No fake improvement trend
- [ ] Private progress user-only


## 07 • Administration

### S065 — Admin Task-First Dashboard

**Decision:** Q23 B+C+D  
**Route/location:** `/admin`  
**Design intent:** Authorized admin landing organized around genuine tasks and recent records.  
**Illustrative mockup:** ![Admin Task-First Dashboard](SCREEN_MOCKUPS/S065_Admin_Task_First_Dashboard.png)

**Visual hierarchy and exact layout**

- Top Overview hero with priority actions, pending counts, actual incoming orders/messages
- Modules Content/Commerce/Announcements/Stats/Quizzes
- Quick access to nested explorer and imports

**User actions and navigation**

- Open task, assign action if supported, navigate management

**Loading, empty, errors and permission states**

- Unauthorized account, unavailable data, stale metric, zero tasks

**Animations and feedback:** Compact count update, no decorative animation on sensitive actions

**Implementation / data rules:** Role enforcement server-side; do not reveal admin screens via client-only route check.

**Acceptance conditions**

- [ ] Role gates correct
- [ ] Real task counts
- [ ] Working original admin routes

### S066 — Admin Content Explorer

**Decision:** Q23 C  
**Route/location:** `/admin/sections, /admin/content/:kind`  
**Design intent:** Academic content explorer mirroring authentic resource→subject→folder hierarchy.  
**Illustrative mockup:** ![Admin Content Explorer](SCREEN_MOCKUPS/S066_Admin_Content_Explorer.png)

**Visual hierarchy and exact layout**

- Breadcrumb tree and compact folder rows
- Actual create/edit/import action bar where supported
- Explicit year/resource tagging, file references and preview

**User actions and navigation**

- Open content, manage permissioned items, bulk import with preview

**Loading, empty, errors and permission states**

- Nested empty, validation failure, missing file, parent folder moved

**Animations and feedback:** Quick folder navigation, confirmation for destructive actions

**Implementation / data rules:** Respect existing storage references and foreign keys; no blind deletion of original PDFs.

**Acceptance conditions**

- [ ] Content hierarchy intact
- [ ] Correct permission
- [ ] Safe writes

### S067 — Admin General Import & Manage

**Decision:** Q23 C+D  
**Route/location:** `/admin/import, /admin/manage/:section`  
**Design intent:** Generic content import/manage surface separate from new quiz CSV studio.  
**Illustrative mockup:** ![Admin General Import & Manage](SCREEN_MOCKUPS/S067_Admin_General_Import_Manage.png)

**Visual hierarchy and exact layout**

- File picker and import mapping when existing
- Preview changes and warnings before confirm
- Target section/category breadcrumb and history

**User actions and navigation**

- Review import, confirm, correct errors, cancel safely

**Loading, empty, errors and permission states**

- Bad file type, duplicates, partial save, unauthorized import

**Animations and feedback:** Progress tied to real processed records

**Implementation / data rules:** Do not mistake legacy document import for quiz MCQ CSV import; keep both flows distinct.

**Acceptance conditions**

- [ ] Existing imports still function
- [ ] Rollback plan
- [ ] Correct tags

### S068 — Admin Commerce & Orders

**Decision:** Q23 D Q18  
**Route/location:** `admin commerce/orders routes • audit`  
**Design intent:** Modular orders/products management with accurate financial info related to Shop only.  
**Illustrative mockup:** ![Admin Commerce & Orders](SCREEN_MOCKUPS/S068_Admin_Commerce_Orders.png)

**Visual hierarchy and exact layout**

- Overview/Commerce tabs, product catalog editing and order list
- Real order status, search/filter and buyer detail per role
- No quiz Wallet/contest payment screen

**User actions and navigation**

- Manage catalog/orders under existing rules, view audit status

**Loading, empty, errors and permission states**

- No orders, permission denied, stock conflict

**Animations and feedback:** Task feedback and restrained table/list transitions

**Implementation / data rules:** Preserve legitimate e-commerce provider and Shop workflow; monetized quiz exclusion separate.

**Acceptance conditions**

- [ ] Shop orders unaffected
- [ ] Correct admin-only access

### S069 — Admin Announcements & Broadcasts

**Decision:** Q21 Q23  
**Route/location:** `Admin announcements module`  
**Design intent:** Create and manage real academic broadcast notices with audience targeting.  
**Illustrative mockup:** ![Admin Announcements & Broadcasts](SCREEN_MOCKUPS/S069_Admin_Announcements_Broadcasts.png)

**Visual hierarchy and exact layout**

- Draft/published list, Compose announcement and audience options
- Priority/featured flag, schedule only if backend can support
- Preview on student feed before publish

**User actions and navigation**

- Draft/edit/publish/unpublish with confirmation and scope

**Loading, empty, errors and permission states**

- Wrong audience, incomplete content, expired campaign

**Animations and feedback:** Publish success only after server acknowledgement

**Implementation / data rules:** School/year segmentation must match actual data policies.

**Acceptance conditions**

- [ ] Unpublished not visible publicly
- [ ] Actual publish state propagated

### S070 — Admin Statistics

**Decision:** Q23 D  
**Route/location:** `/admin/stats`  
**Design intent:** Modular stats sourced from real counts, not decorative mock analytics.  
**Illustrative mockup:** ![Admin Statistics](SCREEN_MOCKUPS/S070_Admin_Statistics.png)

**Visual hierarchy and exact layout**

- Metric cards, trend chart only if historical data available
- Filters/timeframe and neutral status
- Link to source list where supported

**User actions and navigation**

- Change period, drill into authorized reports, export if real

**Loading, empty, errors and permission states**

- Insufficient statistics, delayed aggregation, unauthorized data

**Animations and feedback:** Minimal chart transitions, accessible tabular alternative

**Implementation / data rules:** No fabrication of earnings/quiz prize metrics or personal data exposure.

**Acceptance conditions**

- [ ] Numbers traceable to data
- [ ] Date filters correct

### S071 — Quiz Operations Dashboard

**Decision:** Q28 A  
**Route/location:** `Admin → Quiz Management`  
**Design intent:** New admin module home with direct pathways to Question Bank, Quiz Creation, Registrations, Results and Flags.  
**Illustrative mockup:** ![Quiz Operations Dashboard](SCREEN_MOCKUPS/S071_Quiz_Operations_Dashboard.png)

**Visual hierarchy and exact layout**

- Compact dark-Slate top overview/quick actions
- Grid of modules: Bank, Schedule, Registrations, Results, Duels, Controls
- Needs Attention showing only real counts/import warnings

**User actions and navigation**

- Import CSV, create scheduled quiz, review tasks, change safe settings

**Loading, empty, errors and permission states**

- No quizzes, import backlog, permission denied, disabled League

**Animations and feedback:** Small task cards and success feedback

**Implementation / data rules:** Admin server role; controller off until backend validated.

**Acceptance conditions**

- [ ] All module entries present
- [ ] No fake numbers
- [ ] Actions role-gated

### S072 — CSV Question Bank Library

**Decision:** Q28 B + user refinements  
**Route/location:** `Admin → MCQ Bank`  
**Design intent:** Master question bank tagged with Professional Year, Subject and Topic.  
**Illustrative mockup:** ![CSV Question Bank Library](SCREEN_MOCKUPS/S072_CSV_Question_Bank_Library.png)

**Visual hierarchy and exact layout**

- Download blank CSV template, Sample CSV and Import Guide
- Filter bank by Year → Subject → Topic → status
- Question preview WITHOUT exposing live answer keys to students

**User actions and navigation**

- Download template, upload new batch, inspect draft, manage active/archived questions

**Loading, empty, errors and permission states**

- Duplicated IDs, unknown year/subject, version conflict, access denied

**Animations and feedback:** File pick/check progress and safe batch status

**Implementation / data rules:** Unique IDs, validated four options and one correct answer; answer key server-side.

**Acceptance conditions**

- [ ] Templates downloadable
- [ ] Tags correct
- [ ] No accidental public answers

### S073 — CSV Import Mapping & Validation

**Decision:** Q28 B  
**Route/location:** `Admin → MCQ Bank → Import`  
**Design intent:** Import wizard separates file selection, mapping, row-level validation, preview and commit.  
**Illustrative mockup:** ![CSV Import Mapping & Validation](SCREEN_MOCKUPS/S073_CSV_Import_Mapping_Validation.png)

**Visual hierarchy and exact layout**

- Source file summary and column mapping question_id, professional_year, subject, topic, question, option_a–d, correct_option
- Errors table by row, duplicate IDs, blank answers, invalid options
- Confirm Import only if valid; rejected rows report

**User actions and navigation**

- Upload, map fields, preview, fix source, commit; prevent duplicate bulk writes

**Loading, empty, errors and permission states**

- Malformed CSV, special Unicode, Excel BOM, rows missing, oversized file

**Animations and feedback:** Progress based on rows; no optimistic false success

**Implementation / data rules:** Atomic/idempotent import batches with audit log and answer secrecy.

**Acceptance conditions**

- [ ] Invalid rows blocked
- [ ] Accurate total imported
- [ ] No content corruption

### S074 — Create Quiz Wizard

**Decision:** Q28 C  
**Route/location:** `Admin → Create Quiz`  
**Design intent:** Guided four-stage flow: Type/Year → Subjects/Bank → Schedule/Rules → Review/Publish.  
**Illustrative mockup:** ![Create Quiz Wizard](SCREEN_MOCKUPS/S074_Create_Quiz_Wizard.png)

**Visual hierarchy and exact layout**

- Choose Standard or Special and target eligible Professional Year(s)
- Standard exactly ONE subject; Special TWO+ admin-selected subjects, quotas by subject
- Question count, duration, topics, registration/window, preview and preflight

**User actions and navigation**

- Save draft, select bank tags, review preview, schedule/publish eligible quiz

**Loading, empty, errors and permission states**

- Insufficient unused question pool, mismatched year, overlapping schedule, incomplete rules

**Animations and feedback:** Step progress and nonblocking validation feedback

**Implementation / data rules:** Mix Special eligible subject questions into one shuffled stream; not consecutive subject blocks.

**Acceptance conditions**

- [ ] Correct subject count rules
- [ ] User-year targeting
- [ ] Preflight blocks invalid publish

### S075 — Admin Registration Inbox & Review

**Decision:** Q28 D Q26  
**Route/location:** `Admin → Registrations`  
**Design intent:** Secure Special registrant list with privacy-preserving approval workflow.  
**Illustrative mockup:** ![Admin Registration Inbox & Review](SCREEN_MOCKUPS/S075_Admin_Registration_Inbox_Review.png)

**Visual hierarchy and exact layout**

- Tabs Pending / Approved / Rejected; private applicant fields in authorized detail
- Student full name, email, phone/WhatsApp, roll number only for admin role
- Approve/Reject with recorded reason, timestamp/audit

**User actions and navigation**

- Open request, verify eligibility, approve or reject, safe export only if authorized

**Loading, empty, errors and permission states**

- Duplicate requests, contest closed, blocked compliance, incomplete details

**Animations and feedback:** Small status badge update, no premature confirmation

**Implementation / data rules:** Payment verification must NOT be included as backdoor fee-linked cash-prize flow; blocked by compliance.

**Acceptance conditions**

- [ ] No PII leaks
- [ ] Approval required before start
- [ ] Decision auditable

### S076 — Admin Results & Ranking Review

**Decision:** Q28 D Q27  
**Route/location:** `Admin → Results`  
**Design intent:** Admin verifies genuine attempts and scoring before relevant leaderboard publication.  
**Illustrative mockup:** ![Admin Results & Ranking Review](SCREEN_MOCKUPS/S076_Admin_Results_Ranking_Review.png)

**Visual hierarchy and exact layout**

- Quiz selector, pending/verified/flagged attempts
- Participant pseudonymous name/ID, score, time, anomalies; secure details for role
- Approve publish/recalculate only per audited approved policy

**User actions and navigation**

- Inspect attempts, pause publication, resolve suspicious statuses

**Loading, empty, errors and permission states**

- Absent scoring formula, ungraded attempts, duplicate submission, dispute

**Animations and feedback:** Stable tables, clear alert indication; no animation hiding anomaly

**Implementation / data rules:** Scoring, best-vs-latest attempt and tie policy deliberately pending user approval; do not choose silently.

**Acceptance conditions**

- [ ] Published rank reproducible
- [ ] Pending clearly marked
- [ ] Auditable actions

### S077 — Admin League Feature Controls

**Decision:** Q23 Q28 D Q30 D  
**Route/location:** `Admin → Feature Controls`  
**Design intent:** Server-authoritative feature flags for approved academic modules; separate League entry from hidden/blocked features.  
**Illustrative mockup:** ![Admin League Feature Controls](SCREEN_MOCKUPS/S077_Admin_League_Feature_Controls.png)

**Visual hierarchy and exact layout**

- Rows Standard Quizzes, Special compliant events, Rankings, Duels, Community CTA
- Current state, dependency/health warnings, confirmation dialogs
- Monetary contest capability shown as Not Available, never switchable

**User actions and navigation**

- Enable/disable tested compliant module; inspect deployment readiness

**Loading, empty, errors and permission states**

- Unauthorized toggle, offline admin, missing server-side checks, dependency unavailable

**Animations and feedback:** Immediate confirmation from server, no optimistic security toggle

**Implementation / data rules:** Admin switches are not legal clearance; hard gate prohibited flows and PII routes.

**Acceptance conditions**

- [ ] Server protects disabled APIs
- [ ] No illegal feature toggle
- [ ] Correct UI fallback


## 08 • Cross-Cutting

### S078 — Loading Skeletons & Empty States

**Decision:** Q29 A Q33 assets  
**Route/location:** `every feature module`  
**Design intent:** Content-shaped skeleton components and distinct original AI-assisted empty illustrations matching task.  
**Illustrative mockup:** ![Loading Skeletons & Empty States](SCREEN_MOCKUPS/S078_Loading_Skeletons_Empty_States.png)

**Visual hierarchy and exact layout**

- Home cards, Study rows, PDF thumbnails, Shop products, quiz results each receive matching skeleton
- Empty copy explains what is missing and offers one real next action
- No generic endless spinner

**User actions and navigation**

- Retry, clear filter, open downloads, return; depend on context

**Loading, empty, errors and permission states**

- Actual loading, true empty, filtered empty, unavailable server must be different

**Animations and feedback:** Subtle shimmer only if device not in reduced-motion mode; state illustration idle motion optional

**Implementation / data rules:** Original illustrated icons/characters optimized into small assets; no fabricated records.

**Acceptance conditions**

- [ ] Skeleton matches eventual layout
- [ ] No false data
- [ ] Meaningful empty CTA

### S079 — Error & Offline Recovery

**Decision:** Q29 B Q33  
**Route/location:** `every feature module`  
**Design intent:** Task-specific branded recovery screens; never lose drafts, scans or existing downloaded PDFs.  
**Illustrative mockup:** ![Error & Offline Recovery](SCREEN_MOCKUPS/S079_Error_Offline_Recovery.png)

**Visual hierarchy and exact layout**

- Original low-key error/offline character illustration
- Short plain reason and actionable Retry / Open Saved Files
- Safe failed download and unsynced draft warnings

**User actions and navigation**

- Retry with bounded backoff, open cache, retain unsaved state

**Loading, empty, errors and permission states**

- Offline vs server error vs denied permission vs corrupted PDF distinguished

**Animations and feedback:** Small static or looped icon, no looping heavy video

**Implementation / data rules:** Server-timed quiz never claims pause on offline; submission status requires confirmation.

**Acceptance conditions**

- [ ] Local PDFs usable offline
- [ ] No data lost
- [ ] Honest retry state

### S080 — Branded Icon & Chip Component Library

**Decision:** Q02 Q31 Q33  
**Route/location:** `global reusable widgets`  
**Design intent:** Custom original coherent icon system and interaction tokens reused everywhere.  
**Illustrative mockup:** ![Branded Icon & Chip Component Library](SCREEN_MOCKUPS/S080_Branded_Icon_Chip_Component_Library.png)

**Visual hierarchy and exact layout**

- Unified 24dp icon grid and consistent stroke/visual weight
- Deep Teal selected chips, Slate headings, rounded 14–18px cards
- Semantic danger/disabled, loading and focus states, labels and text scaling

**User actions and navigation**

- Press/select/reorder, accessibility focus, long press where supported

**Loading, empty, errors and permission states**

- High contrast, dark mode, missing raster assets, slow hardware

**Animations and feedback:** Pressed scale / gentle color interpolation and reduced-motion static feedback

**Implementation / data rules:** Generate original AI-assisted motifs; convert needed functional icons to production vectors; no unlicensed scraped sets.

**Acceptance conditions**

- [ ] Icons recognizable at 24dp
- [ ] Chip state not color-only
- [ ] Every screen consistent

### S081 — 3D Onboarding & Personalized Animated Greeting

**Decision:** Q17 Q29 C Q33  
**Route/location:** `startup/onboarding component`  
**Design intent:** Original visual character/animation system, including Welcome, [Name] and Welcome back, [Name].  
**Illustrative mockup:** ![3D Onboarding & Personalized Animated Greeting](SCREEN_MOCKUPS/S081_3D_Onboarding_Personalized_Animated_Greeting.png)

**Visual hierarchy and exact layout**

- One cohesive family of charming but premium academic 3D-style characters
- Open animation storyboard: mascot enters → brand/name reveal → screen settles
- Alternate still assets for reduced motion and faster repeated sessions

**User actions and navigation**

- Skip intro, proceed to app, change avatar preferences separately

**Loading, empty, errors and permission states**

- Name missing, returning path, cold startup, underpowered device

**Animations and feedback:** Prefer Flutter-native animation, Lottie/Rive if license/runtime available; image sequences only when performance tested

**Implementation / data rules:** Use real displayName; voice/typing sound not required or auto-played; no slow mandatory wait.

**Acceptance conditions**

- [ ] Animated and reduced-motion paths usable
- [ ] No skipped authentication


---

# APP-WIDE UI TOKENS AND DESIGN CONSTITUTION

| Topic | Exact locked behavior / specification |
|---|---|
| Product character | Premium Academic + Minimal Professional (Q01 A+B) |
| Palette | Deep Teal #087F76; Slate #1A3440; light BG #F3F8F7; white #FFFFFF; pale teal #DDEDEA; muted #507379 |
| Typography | Manrope hierarchy, approximately 14–16sp body as appropriate; text scale / system font respected |
| Spacing | 8pt rhythm based on 4/8 multiples; compact row lists only Study folders, Settings and Admin |
| Cards | Rounded approximately 14–18px; borders and low shadows; large dark Slate treatment selectively on Welcome/About/League |
| Navigation | Exactly four fixed bottom tabs Home / Study / PDF Studio / Shop; profile via header |
| Motion | Consistent natural easing, short duration, reduced-motion alternative; no startup waiting or frame-drop animation |
| Avatars | Photo upload/crop optional; premade original Gen-Z academic avatars; persistence per user; public profile privacy |
| Icons | Curated original custom family; must stay legible at normal touch-target sizes; optimized vector/raster exports, licensed provenance |
| Onboarding | Original cohesive 3D-style character scenes, personalized animated greeting, return-user skip |
| Offline | Downloads, Study local PDFs, draft scanner work usable offline; competitive timed test never falsely treated as offline-only |
| Compliance | Wallet/Quiz monetary functions absent, fee-linked prize contest facilitation blocked until lawful approved |

# DESIGN RESOURCE RESEARCH REQUIRED FOR CLAUDE

- https://uiverse.io/ — UX/interaction inspiration only; reimplement in native Flutter.
- https://github.com/nextlevelbuilder/ui-ux-pro-max-skill — UI/UX Pro Max skill; **verify it is installed** before invoking. If not installed, read public docs safely; do not execute external scripts without review/permission.
- https://opensourceui.in/ — component and layout ideas.
- https://www.toools.design/free-open-source-icon-libraries — icon reference research and licensing checks.
- https://jitter.video/templates/ui-elements/ — animation ideas and valid exports when licensing permits.
- https://www.ripplix.com — motion inspiration and component concepts.
- https://www.reactbits.dev/ — React motion concepts; **do not paste React code into Flutter**.

# MANDATORY REPOSITORY AND SECURITY GATES

1. Read the project README/START_HERE and inspect current GitHub branch, lockfiles, Flutter and Kotlin libraries, router, auth, local persistence, services, admin authorization and storage. Preserve existing state and working user data before modifying anything.
2. Keep route/feature mapping verified: names in this screen catalog are design destinations, not a claim that each route exists.
3. PDF scanner must be tested on a real Android device before replacing Google scanner; live quad detection, 4-corner warp, multi-page, thumbnail/draft recoverability and result PDF correctness.
4. Downloaded academic PDFs must not be deleted at source by offline copy management. Original Study PDFs not edited in place.
5. Quiz questions are assigned server-side using stable IDs and versioning; Standard nonrepeat across previous attempts of that competition; cap/cooldown and Special single attempt transactionally enforced. Live answer keys never returned to clients. Public ranking uses approved scoring policy, which remains unresolved until explicitly approved.
6. Server-side admin checks; prevent PII leaks including roll number/email/phone. Feature flags never override legal/platform blocks.
7. Import CSV with downloadable blank/example file and row validation; check required columns and Professional Year/Subject/Topic match.
8. Every phase must report changed real paths, test command/results, Android validation where applicable, before/after screenshots, regressions, unresolved blockers and rollback strategy.

# OPEN DECISIONS — DO NOT SILENTLY INVENT

- Exact quiz scoring weight, best-versus-latest attempt, ties, ranking publication, timeouts/reconnects, daily reset timezone and exhaustion of unused questions.
- Exact detailed App Lock, username change, password verification/recovery behavior (existing backend policy first).
- Community URL, logo/owner photograph and approved genuine About biography text.
- Any feature dependent on unobserved real external backend, payment, delivery/shipping or storage provider.

# FINAL CLAUDE REQUEST (COPY INTO CLAUDE CHAT)

> Read `HYZEN_CLAUDE_SCREEN_BY_SCREEN_DESIGN.md` from start to end, every screen ID and the `DECISION_LEDGER_Q01_Q33.md` and `MASTER_BLUEPRINT.md` attachments. These reflect my actual selected Q1–Q33 layouts and custom refinements. This is NOT a greenfield project. Connect to my authorized GitHub `Horizon003/pharm-d-with-hyzen`, perform a read-only A-to-Z audit first, build a route-to-screen mapping from observed code, and then plan feature-by-feature implementation and tests. Preserve four tabs, existing data and routes, original Slate+Deep Teal+Manrope premium UI, AI-generated assets/animations, the full scanner, offline, Shop, and Campus League requirements. No wallet, topup, withdrawals or unapproved fee-linked prize contest registration. Do not call a design mockup a functioning feature. Use tests and user approval for unresolved security/scoring/compliance decisions.
