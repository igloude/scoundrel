# Updates

- Corrected rank values to treat A as 14 for monster damage.
- Implemented full room/turn flow: resolve exactly 3 from a full room, carry 1, and reset per-turn flags.
- Added avoid-room action (move all face-up cards to bottom), with the no-consecutive-avoid rule.
- Enforced one-potion-per-turn rule and per-turn tracking.
- Implemented weapon monster stacking and proper discard when replacing weapons.
- Updated scoring for win/loss, end screens, and HUD/controls text to match rules.
- Adjusted debug/state handling to account for weapon stacks, avoid status, and negative HP.
