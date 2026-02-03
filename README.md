# Scoundrel Solitaire

A faithful digital adaptation of the solo card game **Scoundrel** (Zach Gage & Kurt Bieg).  
Goal: implement the complete ruleset accurately with a minimal, clear UI. Polish is secondary to correctness.

---

## 1. Game Summary

**Scoundrel** is a single-player, roguelike card game played with a modified standard deck. You explore a “Dungeon” deck by revealing **Rooms** of cards, choosing how to resolve threats (monsters), gaining health (potions), and upgrading equipment (weapons). You win by surviving through the entire Dungeon deck. You lose when your health reaches **0 or less**.

---

## 2. Components & Setup

### 2.1 Deck Composition (Dungeon)

Start with a standard 52-card deck.

Remove and do not use:

- Any **Jokers** (if present)
- **Red face cards**: J♥, Q♥, K♥, J♦, Q♦, K♦
- **Red aces**: A♥, A♦

The remaining deck (44 cards) becomes the **Dungeon**:

- **Monsters (26 cards):** all **Spades + Clubs** (A–K)
- **Weapons (9 cards):** **Diamonds 2–10**
- **Health Potions (9 cards):** **Hearts 2–10**

### 2.2 Starting Health

- Player starts at **20 Health**.
- Health cannot exceed **20**.

---

## 3. Card Types & Values

### 3.1 Monsters (Spades & Clubs)

Monsters deal damage equal to their **ordered value**:

- 2–10 = pip value
- J = 11
- Q = 12
- K = 13
- A = 14

### 3.2 Weapons (Diamonds 2–10)

- Weapon value equals its pip value (2–10).
- Weapons are **binding**: if you take one, you must equip it.
- You may equip only **one** weapon at a time.

### 3.3 Health Potions (Hearts 2–10)

- Potion value equals its pip value (2–10).
- You may use **at most one** health potion **per turn**.
- If you take a second potion in the same turn, it is discarded with **no healing**.

---

## 4. Rooms & Turn Flow

### 4.1 What is a Room?

A **Room** is a set of up to **4 face-up cards** in front of the player.

At the start of every turn:

- Reveal cards from the top of the Dungeon until there are **4 face-up cards**, or until the Dungeon runs out.

### 4.2 Turn Options

Each turn, the player chooses **one** of the following:

#### Option A — Avoid the Room

You may avoid the Room:

- Scoop up **all four** face-up cards and place them at the **bottom of the Dungeon**.
- You may avoid as many Rooms as you want…
- …but you **may not avoid two Rooms in a row**.

After avoiding:

- Start the next turn by refilling the Room up to 4 cards.

#### Option B — Resolve the Room

If you do not avoid:

- You must resolve **exactly 3** of the 4 cards, one at a time.
- After resolving 3 cards, your turn ends.
- The **4th card remains face-up** and carries forward into the next Room.

> If the Dungeon is nearly empty, the Room may have fewer than 4 cards. The game continues until the Dungeon is empty and all remaining face-up cards are resolved.

---

## 5. Resolving Cards

When you select a card in a Room, resolve it based on its type:

### 5.1 Weapons (Diamonds)

When you take a weapon:

- You **must equip** it immediately.
- If you already have a weapon equipped:
  - Discard the old weapon **and all monsters stacked on it** (see Combat).

New weapon starts “fresh” (no prior kills).

### 5.2 Health Potions (Hearts)

When you take a potion:

- If you have **not** used a potion yet this turn:
  - Increase health by the potion’s value (up to max 20).
- If you **have** already used a potion this turn:
  - The potion is discarded and provides **no healing**.

### 5.3 Monsters (Spades & Clubs)

When you take a monster, you must fight it:

- **Barehanded**, or
- With your equipped **weapon** (if you have one and it is allowed—see below).

---

## 6. Combat Rules

### 6.1 Fighting Barehanded

- Take damage equal to the monster’s full value.
- Discard the monster.

### 6.2 Fighting With a Weapon

If you have an equipped weapon:

- Damage = **max(0, monsterValue − weaponValue)**
- Place the monster **on top of the weapon** (forming a stack of slain monsters on that weapon).

#### Weapon Restriction (Descending Monster Rule)

Once a weapon has been used to slay a monster, it becomes restricted:

- After the weapon slays a monster of value **X**, it may only be used to slay monsters of value **≤ X**.
- This restriction lasts until the weapon is replaced.

Examples:

- If your weapon has slain a **Queen (12)**, you may weapon-fight a **6** (since 6 ≤ 12).
- If your weapon has slain a **6**, you may **not** weapon-fight a **Queen (12)** (since 12 > 6). You must fight barehanded.

> Monsters fought barehanded do not affect this weapon restriction.

---

## 7. End of Game

The game ends immediately when either condition occurs:

### 7.1 Loss

- Player health reaches **0 or below**.

### 7.2 Win

- The Dungeon is empty **and**
- There are no face-up cards remaining to resolve (Room is empty).

---

## 8. Scoring

### 8.1 If You Lose

- Find all remaining **monsters** still in the Dungeon (unseen/undrawn).
- Subtract their values from your health.

**Score = Health − Sum(remaining monster values)**  
(This will typically be negative.)

### 8.2 If You Win

Normally:

- **Score = remaining Health**

Special case:

- If your health is **20** and your **last resolved card** was a **Health Potion**:
  - **Score = 20 + potion value**

---

## 9. Digital Implementation Notes (Player-Facing)

### 9.1 What the UI Must Show

At minimum:

- Current health (and max health 20)
- Equipped weapon value (or none)
- The weapon’s current restriction (e.g., “weapon can slay ≤ X” once it has a slain monster)
- The 4 face-up Room cards (rank, suit, type, value)
- Dungeon remaining card count
- Discard count
- Whether **Avoid Room** is currently allowed (blocked if last turn was avoided)

### 9.2 What the UI Must Let Players Do

- Select a card from the Room to resolve
- If it is a monster: choose **weapon** or **barehanded**
- Trigger **Avoid Room** when allowed

---

## 10. Testing & Validation Requirements (Development)

Core validation cases:

- Correct deck construction (removals)
- Correct monster value mapping (A=14, face cards, etc.)
- Room fill-to-4 behavior
- Turn rule: resolve 3, carry 1
- Potion: clamp to 20 + one potion per turn
- Weapon replacement discards old weapon + its slain monster stack
- Combat damage math
- Weapon restriction enforcement (≤ last slain monster value)
- Avoid Room: moves 4 to bottom, cannot be used twice in a row
- Win/loss and both scoring modes (including win special-case)

---
