# Hyzen Rive mascot handoff

The production rigged mascot export belongs at `hyzen_mascot.riv`.

Required state machine names: `welcome`, `loading`, `peeking`, `studying`, `downloading`, `success`, and `error`.

The Flutter wrapper is `lib/core/widgets/rive_mascot.dart`. It checks for the asset at runtime and uses the approved transparent pose pack as a safe fallback until the binary Rive export is supplied. Do not rename the state machines without updating the wrapper and tests.
