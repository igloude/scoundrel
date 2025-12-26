Below is a detailed, Cursor-friendly checklist. Each line is intentionally a single, discrete task you can check off.

## A. Project bootstrap

* [ ] Create a new repo folder with a `main.lua` that launches in Love2D.
* [ ] Add `conf.lua` to set window title, dimensions, and vsync.
* [ ] Implement `love.load()` with a single `game = {}` state holder.
* [ ] Implement `love.update(dt)` as a pass-through to a game update function.
* [ ] Implement `love.draw()` as a pass-through to a game draw function.
* [ ] Implement `love.keypressed(key)` as a pass-through to a game input handler.
* [ ] Implement `love.mousepressed(x, y, button)` as a pass-through to a game input handler.
* [ ] Add a `R` hotkey that resets the run to a fresh game state.
* [ ] Add a debug flag that can be toggled with `D`.
* [ ] Add a RNG seed value stored in state.
* [ ] Add a debug option to use a fixed RNG seed.

## B. Domain model

* [ ] Define a `SUITS` constant containing the four suits.
* [ ] Define a `RANKS` constant containing A,2..10,J,Q,K.
* [ ] Create a `Card` table shape with `suit` and `rank`.
* [ ] Implement `cardToString(card)` returning a stable identifier string.
* [ ] Implement `rankToValue(rank)` returning a numeric value per rules.
* [ ] Implement `isMonster(card)` per Scoundrel suit mapping.
* [ ] Implement `isWeapon(card)` per Scoundrel suit mapping.
* [ ] Implement `isPotion(card)` per Scoundrel suit mapping.
* [ ] Implement `cardType(card)` returning `"monster" | "weapon" | "potion"`.

## C. Deck + piles

* [ ] Implement `createStandardDeck()` that returns 52 unique cards.
* [ ] Implement `shuffle(deck, rng)` using a Fisher–Yates shuffle.
* [ ] Implement `drawCard(deck)` that pops and returns the top card.
* [ ] Implement `discardCard(discard, card)` that appends a card to discard.
* [ ] Implement `countDeck(deck)` returning the number of remaining cards.
* [ ] Implement `countDiscard(discard)` returning the discard size.

## D. Game state shape

* [ ] Define a `ROOM_SIZE` constant (e.g., 4).
* [ ] Define `MAX_HP` constant per Scoundrel rules.
* [ ] Define a `RunState` enum-like table (e.g., dealing/awaiting/resolving/gameOver/victory).
* [ ] Create `createNewGameState(seed)` returning the initial state object.
* [ ] Add `state.hp` to game state.
* [ ] Add `state.maxHp` to game state.
* [ ] Add `state.deck` to game state.
* [ ] Add `state.discard` to game state.
* [ ] Add `state.room` to game state.
* [ ] Add `state.weapon` to game state.
* [ ] Add `state.runState` to game state.
* [ ] Add `state.lastLogLine` to game state.
* [ ] Add `state.errorMessage` to game state.
* [ ] Add `state.turnFlags` to game state for rule-specific flags.

## E. Rules helpers (pure functions)

* [ ] Implement `roomIsFull(state)` returning whether room has `ROOM_SIZE` cards.
* [ ] Implement `deckIsEmpty(state)` returning whether deck has no cards.
* [ ] Implement `roomIsEmpty(state)` returning whether room has no cards.
* [ ] Implement `dealOneToRoom(state)` that draws one card into room if possible.
* [ ] Implement `dealRoomUpToFull(state)` that fills room until full or deck empty.
* [ ] Implement `removeRoomCard(state, index)` returning `(newState, removedCard)`.
* [ ] Implement `pushToDiscard(state, card)` returning newState with card discarded.
* [ ] Implement `setLog(state, text)` returning newState with log updated.
* [ ] Implement `setError(state, text)` returning newState with error updated.
* [ ] Implement `clearError(state)` returning newState with error cleared.

## F. Core action validation

* [ ] Implement `isValidRoomIndex(state, index)` returning true/false.
* [ ] Implement `canTakeFromRoom(state, index)` returning `(bool, reason)`.
* [ ] Implement `canFleeFromRoom(state, index)` returning `(bool, reason)`.
* [ ] Implement `canAct(state)` returning `(bool, reason)` based on `runState`.

## G. Action resolution: take card

* [ ] Implement `applyTake(state, index)` as the single entry point for “take”.
* [ ] Implement `resolveTakeMonster(state, card)` returning newState.
* [ ] Implement `resolveTakeWeapon(state, card)` returning newState.
* [ ] Implement `resolveTakePotion(state, card)` returning newState.
* [ ] Implement `applyDamage(state, amount)` clamping HP and setting gameOver if needed.
* [ ] Implement `applyHeal(state, amount)` clamping to max HP.
* [ ] Implement `equipWeapon(state, weaponCard)` handling replacement rules.
* [ ] Implement `clearWeaponUseFlags(state)` per rules when equipping or after fights.
* [ ] Implement `computeMonsterDamage(state, monsterCard)` per rules using weapon if applicable.
* [ ] Implement `afterSuccessfulTake(state)` that refills room and checks end conditions.
* [ ] Implement `afterFailedTake(state)` that still refills room if rules require it.

## H. Action resolution: flee

* [ ] Implement `applyFlee(state, index)` as the single entry point for “flee”.
* [ ] Implement `resolveFleeCard(state, card)` per rules (discard/put back/etc.).
* [ ] Implement `applyFleePenalty(state)` per rules (if any).
* [ ] Implement `afterFlee(state)` that refills room and checks end conditions.

## I. Win/lose + invariants

* [ ] Implement `isGameOver(state)` returning true when HP <= 0.
* [ ] Implement `isVictory(state)` per rules (deck empty + room empty, etc.).
* [ ] Implement `updateRunState(state)` to set `gameOver` or `victory` when applicable.
* [ ] Implement `assertNoDuplicateCards(state)` in debug mode.
* [ ] Implement `assertHpInRange(state)` in debug mode.
* [ ] Implement `assertRoomSizeValid(state)` in debug mode.

## J. Minimal rendering

* [ ] Implement `layoutRoomSlots()` returning rectangles for each room position.
* [ ] Implement `drawCardRect(card, rect, index)` drawing a rectangle and text label.
* [ ] Implement `drawRoom(state)` drawing all current room slots.
* [ ] Implement `drawHud(state)` drawing HP/maxHP, deck count, discard count, weapon.
* [ ] Implement `drawLog(state)` drawing the last action result line.
* [ ] Implement `drawError(state)` drawing the current error message if present.
* [ ] Implement `drawEndScreen(state)` rendering “Victory” or “Game Over”.

## K. Minimal input wiring

* [ ] Implement `indexFromMouseClick(x, y)` returning the clicked room index or nil.
* [ ] Implement mouse left-click to attempt `applyTake` on clicked card.
* [ ] Implement mouse right-click to attempt `applyFlee` on clicked card.
* [ ] Implement keys `1`-`4` to attempt `applyTake` for that index.
* [ ] Implement keys `F` + `1`-`4` chord to attempt `applyFlee` for that index.
* [ ] Implement `ESC` to quit or return to a simple menu state.
* [ ] Implement `R` to reset the run state cleanly.

## L. Debug utilities

* [ ] Implement `P` hotkey to print a concise state dump to console.
* [ ] Implement `showSeed` in HUD when debug is enabled.
* [ ] Implement a debug overlay listing room cards with full IDs.
* [ ] Implement a “fixed seed” toggle key (e.g., `S`) for reproducible runs.
* [ ] Implement a minimal auto-play key (e.g., `Space`) for stress-testing.

## M. Acceptance checks

* [ ] Verify the initial deal fills the room correctly.
* [ ] Verify taking a potion heals and clamps to max HP.
* [ ] Verify taking a weapon equips and handles replacement properly.
* [ ] Verify taking a monster applies correct damage per weapon rules.
* [ ] Verify flee behaves exactly per rules and does not soft-lock.
* [ ] Verify the game reaches “Victory” when end condition is met.
* [ ] Verify the game reaches “Game Over” when HP reaches 0.
* [ ] Verify no duplicated card exists across deck/room/discard/weapon in debug checks.
* [ ] Verify reset fully restarts with a fresh shuffled deck (or same deck with fixed seed).

If you paste the Scoundrel suit→type mapping and the exact weapon/monster interaction rules you’re using (a few bullet points is enough), I can refine the “per rules” checklist items into concrete tasks (e.g., “weapon can be applied once per monster, remainder damage applies to player,” etc.) without leaving any ambiguity.
