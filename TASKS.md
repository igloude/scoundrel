# Tasks

## A. Project bootstrap

* [x] Create a new repo folder with a `main.lua` that launches in Love2D.
* [x] Add `conf.lua` to set window title, dimensions, and vsync.
* [x] Implement `love.load()` with a single `game = {}` state holder.
* [x] Implement `love.update(dt)` as a pass-through to a game update function.
* [x] Implement `love.draw()` as a pass-through to a game draw function.
* [x] Implement `love.keypressed(key)` as a pass-through to a game input handler.
* [x] Implement `love.mousepressed(x, y, button)` as a pass-through to a game input handler.
* [x] Add a `R` hotkey that resets the run to a fresh game state.
* [x] Add a debug flag that can be toggled with `D`.
* [x] Add a RNG seed value stored in state.
* [x] Add a debug option to use a fixed RNG seed.

## B. Domain model

* [x] Define a `SUITS` constant containing the four suits.
* [x] Define a `RANKS` constant containing A,2..10,J,Q,K.
* [x] Create a `Card` table shape with `suit` and `rank`.
* [x] Implement `cardToString(card)` returning a stable identifier string.
* [x] Implement `rankToValue(rank)` returning a numeric value per rules.
* [x] Implement `isMonster(card)` per Scoundrel suit mapping.
* [x] Implement `isWeapon(card)` per Scoundrel suit mapping.
* [x] Implement `isPotion(card)` per Scoundrel suit mapping.
* [x] Implement `cardType(card)` returning `"monster" | "weapon" | "potion"`.

## C. Deck + piles

* [x] Implement `createStandardDeck()` that returns 52 unique cards.
* [x] Implement `shuffle(deck, rng)` using a Fisher–Yates shuffle.
* [x] Implement `drawCard(deck)` that pops and returns the top card.
* [x] Implement `discardCard(discard, card)` that appends a card to discard.
* [x] Implement `countDeck(deck)` returning the number of remaining cards.
* [x] Implement `countDiscard(discard)` returning the discard size.

## D. Game state shape

* [x] Define a `ROOM_SIZE` constant (e.g., 4).
* [x] Define `MAX_HP` constant per Scoundrel rules.
* [x] Define a `RunState` enum-like table (e.g., dealing/awaiting/resolving/gameOver/victory).
* [x] Create `createNewGameState(seed)` returning the initial state object.
* [x] Add `state.hp` to game state.
* [x] Add `state.maxHp` to game state.
* [x] Add `state.deck` to game state.
* [x] Add `state.discard` to game state.
* [x] Add `state.room` to game state.
* [x] Add `state.weapon` to game state.
* [x] Add `state.runState` to game state.
* [x] Add `state.lastLogLine` to game state.
* [x] Add `state.errorMessage` to game state.
* [x] Add `state.turnFlags` to game state for rule-specific flags.

## E. Rules helpers (pure functions)

* [x] Implement `roomIsFull(state)` returning whether room has `ROOM_SIZE` cards.
* [x] Implement `deckIsEmpty(state)` returning whether deck has no cards.
* [x] Implement `roomIsEmpty(state)` returning whether room has no cards.
* [x] Implement `dealOneToRoom(state)` that draws one card into room if possible.
* [x] Implement `dealRoomUpToFull(state)` that fills room until full or deck empty.
* [x] Implement `removeRoomCard(state, index)` returning `(newState, removedCard)`.
* [x] Implement `pushToDiscard(state, card)` returning newState with card discarded.
* [x] Implement `setLog(state, text)` returning newState with log updated.
* [x] Implement `setError(state, text)` returning newState with error updated.
* [x] Implement `clearError(state)` returning newState with error cleared.

## F. Core action validation

* [x] Implement `isValidRoomIndex(state, index)` returning true/false.
* [x] Implement `canTakeFromRoom(state, index)` returning `(bool, reason)`.
* [x] Implement `canFleeFromRoom(state, index)` returning `(bool, reason)`.
* [x] Implement `canAct(state)` returning `(bool, reason)` based on `runState`.

## G. Action resolution: take card

* [x] Implement `applyTake(state, index)` as the single entry point for "take".
* [x] Implement `resolveTakeMonster(state, card)` returning newState.
* [x] Implement `resolveTakeWeapon(state, card)` returning newState.
* [x] Implement `resolveTakePotion(state, card)` returning newState.
* [x] Implement `applyDamage(state, amount)` clamping HP and setting gameOver if needed.
* [x] Implement `applyHeal(state, amount)` clamping to max HP.
* [x] Implement `equipWeapon(state, weaponCard)` handling replacement rules.
* [x] Implement `clearWeaponUseFlags(state)` per rules when equipping or after fights.
* [x] Implement `computeMonsterDamage(state, monsterCard)` per rules using weapon if applicable.
* [x] Implement `afterSuccessfulTake(state)` that refills room and checks end conditions.
* [x] Implement `afterFailedTake(state)` that still refills room if rules require it.

## H. Action resolution: flee

* [x] Implement `applyFlee(state, index)` as the single entry point for "flee".
* [x] Implement `resolveFleeCard(state, card)` per rules (discard/put back/etc.).
* [x] Implement `applyFleePenalty(state)` per rules (if any).
* [x] Implement `afterFlee(state)` that refills room and checks end conditions.

## I. Win/lose + invariants

* [x] Implement `isGameOver(state)` returning true when HP <= 0.
* [x] Implement `isVictory(state)` per rules (deck empty + room empty, etc.).
* [x] Implement `updateRunState(state)` to set `gameOver` or `victory` when applicable.
* [x] Implement `assertNoDuplicateCards(state)` in debug mode.
* [x] Implement `assertHpInRange(state)` in debug mode.
* [x] Implement `assertRoomSizeValid(state)` in debug mode.

## J. Minimal rendering

* [x] Implement `layoutRoomSlots()` returning rectangles for each room position.
* [x] Implement `drawCardRect(card, rect, index)` drawing a rectangle and text label.
* [x] Implement `drawRoom(state)` drawing all current room slots.
* [x] Implement `drawHud(state)` drawing HP/maxHP, deck count, discard count, weapon.
* [x] Implement `drawLog(state)` drawing the last action result line.
* [x] Implement `drawError(state)` drawing the current error message if present.
* [x] Implement `drawEndScreen(state)` rendering "Victory" or "Game Over".

## K. Minimal input wiring

* [x] Implement `indexFromMouseClick(x, y)` returning the clicked room index or nil.
* [x] Implement mouse left-click to attempt `applyTake` on clicked card.
* [x] Implement mouse right-click to attempt `applyFlee` on clicked card.
* [x] Implement keys `1`-`4` to attempt `applyTake` for that index.
* [x] Implement keys `F` + `1`-`4` chord to attempt `applyFlee` for that index.
* [x] Implement `ESC` to quit or return to a simple menu state.
* [x] Implement `R` to reset the run state cleanly.

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
* [ ] Verify taking 3 cards in a room moves to the next room while retaining the last un-chosen card
* [ ] Verify flee behaves exactly per rules and does not soft-lock.
* [ ] Verify the game reaches “Victory” when end condition is met.
* [ ] Verify the game reaches “Game Over” when HP reaches 0.
* [ ] Verify no duplicated card exists across deck/room/discard/weapon in debug checks.
* [ ] Verify reset fully restarts with a fresh shuffled deck (or same deck with fixed seed).

If you paste the Scoundrel suit→type mapping and the exact weapon/monster interaction rules you’re using (a few bullet points is enough), I can refine the “per rules” checklist items into concrete tasks (e.g., “weapon can be applied once per monster, remainder damage applies to player,” etc.) without leaving any ambiguity.
