# Splicer

Splicer is a solo watchlist for people who already have a pile and want to finish one title at a time on this device. Search stashes a title on the stack. Draw seats the top stub on the gate. Burn records the finish and removes that stub so the backlog shrinks.

## Architecture

The board is a lane fold: Dark, Empty, Piled, or Gated. `BoardFold` is the only writer for stash, draw, and burn. Rate touches a `BurnMark` and never the lanes. That suits a watch pile because the home screen is the job (what is on the gate, what is still stacked), not a journal of everything already seen. `LaneChartStore` keeps one `LaneChart` under `spl.lane.v1` and posts `LaneFoldNotice` after a successful stash, draw, or burn so Ash and Profile reload while the fold stays owned by the board.

## Draw-then-burn

Stash writes a stub on the stack. Draw moves only the top stub onto the gate and refuses a second draw while the gate is occupied. Burn writes a `BurnMark` when the gate holds that stub, then folds back to Piled if the stack remains or to Empty if it does not. A miss writes a `SlipMark` and keeps the stub. Ash lists burns in order. Profile counts those burns and their grades. Draw on an empty stack reports Bare. Burn on a pile with nothing on the gate is refused.

## Art

Style: geometric pattern tile collage. Hard-edged tiles repeat in a tight mosaic, then a few tiles are cut and layered like spliced film frames. Subjects are solid and opaque, centered, with clear corners on cutouts. Icon, splash, and backdrop fill the canvas edge to edge. No letters, no hollow frames, no wire outlines.

- `spl_AppIcon`: A solid film-gate latch centered on a field of repeating geometric tiles, collage layers overlapping, subject filling the canvas edge to edge, no letters, no rounded mask, opaque square.
- `spl_Splash`: A tall geometric tile collage with a quiet center band, a solid splice block standing in the middle third, tiles reaching all four edges.
- `spl_Onboarding1`: A solid stack of opaque title cards beside a gate frame, geometric tile collage, subject centered, corners clear.
- `spl_Onboarding2`: A solid title card moving from a stack onto a gate, mid gesture, geometric tile collage, opaque forms, corners clear.
- `spl_Onboarding3`: A short row of solid burned seals in order, geometric tile collage, opaque marks, corners clear.
- `spl_EmptyHome`: A solid closed film can sitting alone, geometric tile collage, fully opaque metal, not glass, not a hollow frame, corners clear.
- `spl_EmptyList`: A solid closed folio, geometric tile collage, opaque cover, corners clear.
- `spl_CardBackdrop`: An edge-to-edge geometric tile field, quiet pattern, no competing subject, fills the canvas.
- `spl_ControlFace`: A solid splice block, the face of the burn control, geometric tile inlay, opaque, centered, corners clear.
- `spl_TwistHero`: A solid title card halfway from a stack onto a gate, geometric tile collage, opaque, centered, corners clear.
- `spl_SuccessMark`: A solid round seal with a thick center, geometric tile inlay, opaque, not a hollow ring, corners clear.
- `spl_HeaderDecor`: A wide horizontal cluster of geometric tiles in the center, collage, solid tiles, corners clear.

## How this differs

Bioscope is a two-seat bill with reel-the-bill for a pair tonight. Splicer is one person, two lanes, and burn-the-gate. Ash is burn order, not a growing seen shelf, and there is no streaming store.

## Build

```
xcodegen generate
xcodebuild build-for-testing -scheme Splicer -destination 'generic/platform=iOS Simulator' -jobs 2 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```
