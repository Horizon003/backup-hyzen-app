# Mascot Motion — Checkpoint 1

## Approved identity

The panda identity follows the supplied mascot board: black-and-white panda, graduation cap with gold tassel, white pharmacy lab coat, black academic clothing, and premium soft 3D rendering. The supplied board and app icons remain references; production transparent pose exports are stored under `hyzen_flutter/assets/mascot/`.

## Production states

| State | Asset | Current use |
|---|---|---|
| Welcome | `mascot_idle_welcome.png` | Splash and first onboarding page |
| Peeking | `mascot_peeking.png` | Home welcome hero |
| Studying | `mascot_studying.png` | Study-oriented onboarding page |
| Downloading | `mascot_downloading.png` | Offline/download onboarding and empty Downloads state |
| Success | `mascot_success_wave.png` | Reserved for download completion and success feedback |

## Motion behavior

`HyzenMascot` is a reusable state-driven Flutter widget in `lib/core/widgets/mascot_motion.dart`. It uses an `AnimatedSwitcher` for state changes and a short rise-and-settle transform for entrance feedback. The motion is intentionally finite rather than an infinite ticker so it does not block `pumpAndSettle`, accessibility flows, or route transitions. `MediaQuery.disableAnimationsOf(context)` reduces the motion to a quick state transition.

## Next integration batch

- Wire `downloading` and `success` states into the real download row/progress lifecycle.
- Add scanner capture/crop success and error states.
- Add studying/thinking states to study empty/loading/error surfaces.
- Add document/PDF Studio contextual mascot states without covering editing controls.
- Add update-available and offline/error states with restrained scale and semantic labels.
- Produce device screenshots and verify large text, dark mode, narrow phones, and reduced motion.
