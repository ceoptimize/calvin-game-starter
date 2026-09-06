# Calvin's Game Starter

## What this is

This folder is the home for your game and for two AI coding tools, Claude Code and Codex, that help you build it.

## First-time setup

### Get this folder onto the computer

Open PowerShell. You do not need to open it as an administrator. Run:

```powershell
winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
```

Close PowerShell and open it again so Git is found. Then run:

```powershell
git clone https://github.com/ceoptimize/calvin-game-starter.git
cd calvin-game-starter
```

Stay in that same PowerShell window for the next step.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

The script checks Git and installs Node.js, uv, Unity Hub, Claude Code, Codex, the Unity skills, and the Unity MCP connection. It is safe to run again at any time. It also lets PowerShell run the small helper scripts that Node installs, which Codex needs. Windows may ask for permission during installs. A parent should say yes.

When the script finishes, close PowerShell and open it again in this folder. That is how Windows notices the new programs.

## Sign in

Ask a parent to help with this part. Run `claude` once and follow the browser sign-in. Then run `codex login` once and follow the browser sign-in. Both tools will ask if you trust this folder the first time. Answer yes.

## Create the Unity project

Open Unity Hub. If no Unity 6 editor is installed, install the newest Unity 6 editor with a version starting with `6000.`. Click **New project** and choose the **Universal 3D** template, also called URP. Set **Location** to this folder and **Project name** to `Game`. Your project must end up at `<this folder>\Game\`.

## Connect Unity to the AI tools

In Unity, open **Window > Package Manager**. Click **+**, then **Add package from git URL**. Paste:

```text
https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#main
```

Open **Window > MCP for Unity**. Leave **Transport** set to **HTTP**. Under **Local Server**, click **Start Server** and wait for it to say it is running. Open **Advanced Settings** in that window and turn on **Auto-Start Server on Editor Load** so it starts every time Unity opens. Claude Code and Codex both connect to it at `http://127.0.0.1:8080/mcp`. Claude Code uses this repo's `.mcp.json`, and `setup.ps1` registers the address for Codex.

## Every day

Open the `Game` project in Unity. Open a terminal in this folder and run `claude`. For a new feature, type `/route` followed by what you want. Claude plans and reviews the work, and Codex writes the code. Nothing is committed until you say so.

## Keep everything up to date

These are the only four update commands you need:

```text
claude update
codex update
npx skills update -g
git pull
```

`claude update` updates Claude Code.

`codex update` updates Codex. It may print an npm command to run instead. Run that command.

`npx skills update -g` updates your shared AI skills.

`git pull` updates this starter folder from Git.

## Finding more skills

Tell Claude, `find a skill for X`, with what you want in place of `X`. The `find-skills` skill searches for you. Install a skill with:

```text
npx skills add <owner/repo> --skill <name> -g --copy
```

## If something breaks

Run `claude doctor`. Run `codex doctor`. You can also run `setup.ps1` again. If the AI tools cannot see Unity, open **Window > MCP for Unity** and check that **Local Server** says it is running. Press **Start Server** if not.

## Art and sound

For textures and UI images, ask Codex to use `$imagegen` and keep prompts in `Game/Assets/Art/STYLE.md`. Get 3D models and sounds from free packs such as Kenney (kenney.nl), Poly Haven (polyhaven.com), Mixamo (mixamo.com) for character animation, and Freesound (freesound.org). Always write down the pack and its license in `Game/Assets/Art/CREDITS.md`.
