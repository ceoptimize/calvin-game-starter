# Project

- Build a polished 3D multiplayer game in Unity 6 with C# and URP.
- Keep the Unity project in `Game/`.
- Read `Game/ProjectSettings/ProjectVersion.txt` before using any Unity API.
- Target the exact editor version recorded in that file.

# Workflow

- Work on one feature at a time.
- The Unity rules below apply only to work that touches `Game/`. Editing this README, `setup.ps1`, or the config files needs no Unity.
- Before reporting a game feature done, use Unity MCP to check the console for errors.
- Enter play mode with Unity MCP and confirm the feature works.
- Exit play mode after the check.
- If a task touches `Game/` and Unity MCP is not connected, say so and stop. Do not guess.

# Multiplayer

- Use Netcode for GameObjects, package `com.unity.netcode.gameobjects`.
- Design the game to be server-authoritative.
- Never trust client-reported positions, health, or scores.
- Use NetworkVariables for state.
- Use `[Rpc]` methods for events, choosing the `SendTo` target explicitly (`SendTo.Server` for client requests, `SendTo.ClientsAndHost` for broadcasts).
- Start with host mode, where one player is the server.
- Use Unity Relay for joining over the internet.

# Graphics

- Use URP.
- Put a Global Volume with post-processing in the first scene.
- Include Bloom, Color Adjustments, Vignette, and ACES Tonemapping.
- Use a real-time directional light.
- Add baked lighting or Adaptive Probe Volume lighting.
- Use a Cinemachine camera.
- Never ship the default skybox.
- Never ship the default grey material on any object.
- Give each new visual element game feel when relevant.
- Consider screen shake, hit-stop, and tweened UI.

# Art pipeline

- Keep all art under `Game/Assets/Art/`.
- Treat `Game/Assets/Art/STYLE.md` as the style sheet.
- Start every image-generation prompt by quoting the style sheet.
- Record every third-party pack and its license in `Game/Assets/Art/CREDITS.md`.
- Get 3D models and audio from free packs.
- Generate textures and UI when useful.
- Never generate a texture that a chosen pack already provides in the chosen style.

# Code

- Prefer small MonoBehaviours.
- Use ScriptableObjects for tunable data.
- Use the new Input System.
- Never use `GameObject.Find` in gameplay code.
- Never use `Resources.Load`.
- Put pure logic in plain C# classes.
- Add EditMode tests for pure logic under `Game/Assets/Tests/`.

# Git

- Never commit `Library/`, `Temp/`, `Logs/`, or `UserSettings/`.
- Commit only when the user asks.
- Never delete an asset without asking first.

# Codex

- Keep the default model in `.codex/config.toml`. Do not change it.
- Work only inside this repository.
