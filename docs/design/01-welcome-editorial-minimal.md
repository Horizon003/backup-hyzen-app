# PHARM D WITH HYZEN — Screen 01: Welcome & Onboarding
Status: **DESIGN LOCKED / implementation proposed in branch**
Selected design: **A — Editorial Minimal**
Theme: **Black & White with subtle Deep Teal accent**
Date: 2026-10-28

## Global visual direction (locked)
- Primary ink: #111111; white: #FFFFFF.
- Soft panels: #F4F6F5; neutral secondary copy: #737373.
- Deep Teal accent: #087F76. Use only for eyebrow, active page indicator, tiny illustration detail and Create Account link.
- Black pill primary CTA with white text; inverse for dark mode.
- Font: existing Manrope theme. Bold editorial title (34sp, ~1.13 line-height); supporting copy (14sp, ~1.55 line-height).
- No unnecessary gradients, heavy shadows, clutter or new dependencies.
- Respect system dark mode with near-black background and light ink.

## Screen 01 layout (locked)
1. Safe-area brand row: monochrome app logo, small PHARM D WITH HYZEN label, Your pharmacy journey sublabel, right-aligned Skip action.
2. Swipeable PageView with exactly 3 pages. All use the same structure: eyebrow, bold left-aligned heading, descriptive copy, illustration inside rounded neutral panel.
3. Existing illustrations remain, converted to monochrome; tiny teal accent allowed.
4. Animated three-step page indicator: active teal elongated pill, inactive gray dots.
5. Bottom primary 56px pill; login and create-account links retained.
6. Body scrolls at small height and with large text; max layout width 520 logical pixels.

## Final copy and page actions
| Page | Eyebrow | Heading | Supporting copy | Primary CTA |
| --- | --- | --- | --- | --- |
| 1 | WELCOME TO HYZEN | Your future in pharmacy starts here. | Study smarter with notes, MCQs and past papers organised around your professional year. | Get Started → next page |
| 2 | STUDY WITH CLARITY | Your library. Always within reach. | Find subjects, explore study materials and continue your Pharm-D journey in one place. | Continue → next page |
| 3 | READY WHEN YOU ARE | Learn anywhere. Even offline. | Save your study notes and open them again when you do not have an internet connection. | Log in → /login |

## Existing functions that MUST remain unchanged
- Exactly three swipeable pages using PageController.
- Indicator follows selected page.
- Skip opens /login on every page.
- Log in opens /login.
- Create account opens /register/personal.
- Primary button advances pages 1→2→3, then opens /login.
- Splash screen and external auth logic unchanged.

## Flutter implementation
- Localized styles in lib/features/auth/presentation/splash_welcome_screens.dart; no collateral global theme changes.
- Reuses Brand.logoAsset, HyzenArt and existing welcome illustration asset.
- Test Android and Flutter Web: 320px narrow phone, 390px phone, tall phone, dark mode, small landscape height, increased text scaling and navigation.
- Respect reduced-motion preferences when polishing other global animations.

## Merge and build checklist
- [ ] Review iPhone-sized Flutter Web preview.
- [ ] Run flutter analyze and flutter test from extracted full project.
- [ ] Verify all illustrations/assets render in grayscale.
- [ ] Test Get Started, Continue, Log in, Skip, Create Account.
- [ ] Validate dark mode and accessibility at increased text scale.
- [ ] Confirm overlay file is applied by CI (cp -a lib/. hyzen_flutter/lib/) and merge only after green build.
- [ ] Do not claim a live preview or APK is deployed until verified.

## Repository architecture note
Repo stores full Flutter source in PharmD_With_Hyzen_Source_1.3.3.zip and root lib/ as build overlays. This design PR updates the overlay only, not the archived complete source. When preparing a new source release, incorporate the changes into the canonical full-source project as well.

## Next
Screen 02: Login — same palette and editorial typography, preserving actual authentication and validation.
