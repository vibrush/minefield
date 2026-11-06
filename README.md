# Minefield

A local two-player competitive minesweeper duel built with Godot 4 and GDScript.

Two operators explore the same abandoned urban sector through separate 3x3 fog-of-war views. Reveal safe tiles to read adjacent mine counts, mark suspected mines with flags, avoid losing all three lives, and finish the timer with more correct flags than your opponent.

## Requirements

- Godot 4.7 or newer. Tested with `4.7.1.stable`.
- Windows, Linux, or macOS with keyboard input.
- No external libraries or plugins are required.

## Run

Open `project.godot` in Godot and press **F5**, or run:

```powershell
& "C:\Program Files\Godot\Godot.exe" --path .
```

The main scene is `res://scenes/main/main_menu.tscn`.

## Controls

| Action | Player 1 | Player 2 |
|---|---|---|
| Face / move up | `W` | `Up` |
| Face / move left | `A` | `Left` |
| Face / move down | `S` | `Down` |
| Face / move right | `D` | `Right` |
| Reveal tile ahead | `Q` | `.` |
| Place / remove flag ahead | `E` | `/` |
| Pause / resume | `Esc` | `Esc` |

A quick direction tap changes facing only. Holding a direction for 0.18 seconds starts grid movement at two tiles per second.

## Rules

- Players share one minefield but have independent vision and exploration memory.
- Vision is a 3x3 area centered on the player's tile, clipped by arena edges.
- Revealed safe tiles keep their numbers in memory. Outside vision the tile is covered by fog again; the number reappears when the player returns.
- Revealed mines are remembered only while visible. After leaving vision, the mine information is forgotten.
- Revealing a mine or stepping on a mine costs one life.
- Flags may be placed only on unrevealed tiles, cannot stack, and can be removed only by their owner.
- Flags do not block movement. Stepping on a flagged mine still causes damage.
- A flag scores one point only while it is on a real mine and still placed.
- At zero lives the player is eliminated temporarily; all their flags are removed and their live score drops.
- Respawn restores three lives and the full flag inventory, grants one reveal-only shield, and places the player at least half the arena width from the opponent.
- The match ends only when the timer reaches zero. Most correct flags wins; equal scores are a draw.

## Difficulty Profiles

| Difficulty | Grid | Mines | Flags per player | Duration |
|---|---:|---:|---:|---:|
| Easy | 10 x 10 | 12 | 12 | 3:00 |
| Medium | 16 x 16 | 40 | 40 | 5:00 |
| Hard | 20 x 24 | 90 | 90 | 8:00 |

Grids are interpreted as `columns x rows`; Hard is 20 tiles wide and 24 tiles tall.

## GDD Ambiguity Resolutions

- One shared board model drives both split-screen views; only exploration and fog state are duplicated per player.
- The acting player may not flag a tile they have already revealed as safe or are currently seeing as a mine. The opponent's memory does not affect this check.
- Enemy flags are visible only inside the viewer's current vision. A player's own flags remain visible.
- Reveal and flag interactions always target exactly the tile in front of the player. Out-of-bounds input is rejected with HUD feedback.
- Movement into the opponent's currently occupied tile is rejected. Simultaneous moves into the same tile are both rejected; swaps cannot occur.
- Respawn candidates are safe, non-bomb tiles that are not occupied by the opponent and are at least 50% of arena width away. If a board is too dense to satisfy the distance, the farthest available safe tiles are used.
- Elimination removes all placed flags immediately. Respawn refills the flag inventory and grants one protection charge that only absorbs reveal-triggered mine damage.
- Elimination removes owned flags immediately, so the player's live score can fall during a match.
- There is no early score victory; play always continues until the timer expires.
- No automatic flood-fill reveal is used. Only the directly targeted tile opens.
- UI and in-game text use an English tactical style, as requested during implementation.

## Project Structure

```text
scenes/
  game/arena.tscn              Reusable arena view scene
  game/game.tscn               Match scene with split-screen viewports and managers
  main/main_menu.tscn          Menu, difficulty selection, and field manual
  ui/hud.tscn                  Shared HUD canvas layer
  ui/player_hud.tscn           Per-player HUD panel
  ui/pause_menu.tscn           Pause overlay
  ui/result_screen.tscn        End-of-match result screen
scripts/
  autoload/game_settings.gd    Selected difficulty autoload
  config/                      Game constants and difficulty profiles
  core/                        Board model and simultaneous movement resolver
  managers/                    Bombs, grid, fog, exploration, flags, health, respawn,
                               score, audio, and match flow
  player/                      Player state and keyboard controller
  ui/                          Menu, arena rendering, HUD, pause, result, effects, theme
shaders/                       Procedural fog and menu smoke shaders
assets/audio/                  Procedurally generated WAV sound cues
tests/                         Automated board, rules, integration, and visual QA scenes
```

## Tests

Board generation and number calculations:

```powershell
& "C:\Program Files\Godot\Godot.exe" --headless --path . --script res://tests/test_board.gd
```

Rules, fog, flags, health, respawn, collision, and movement units:

```powershell
& "C:\Program Files\Godot\Godot.exe" --headless --path . --script res://tests/test_rules.gd
```

Full game-scene integration, including input mapping, HUD, audio loading, elimination, respawn, pause, and match completion:

```powershell
& "C:\Program Files\Godot\Godot.exe" --headless --path . res://tests/test_game.tscn
```

Visual QA captures the menu, overlays, split-screen gameplay, and result screen:

```powershell
& "C:\Program Files\Godot\Godot.exe" --path . res://tests/capture_screens.tscn
```

Captured PNGs are written to `%TEMP%\opencode\karhutla_captures`.

## Assets and Audio

- All visuals are drawn procedurally with Godot controls, canvas drawing, and shaders.
- Sound cues in `assets/audio/` were generated locally as 16-bit mono WAV files: reveal, flag, explosion, damage, shield, respawn, victory, denied, and UI click.
- The fog-of-war and menu background effects are custom canvas shaders.
