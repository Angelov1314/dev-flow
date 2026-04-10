---
name: dev-router
description: Register a new project in Dev Router for one-click launching. Use whenever creating a new web app, API server, or any project with a dev server. Automatically triggered when scaffolding new projects.
user_invocable: true
---

You are the Dev Router integration assistant. Your job is to ensure new projects are discoverable by Jerry's local Dev Router dashboard.

## Dev Router Overview

Dev Router is a local project launcher dashboard at `/Users/jerry/Claude/dev-router/` that:
- Runs on `localhost:4000`, launched via `Dev Router.app` on Desktop
- Auto-scans directories for projects and provides one-click start/open
- Supports: npm (package.json with dev script), Python (main.py/app.py/server.py), Godot, static HTML

## Scanned Directories (in order)

1. `/Users/jerry/Claude/Projects/` — **primary location for all new projects**
2. `/Users/jerry/Claude/` — legacy projects
3. `/Users/jerry/Desktop/projects/` — desktop projects

## When This Skill Triggers

- User creates a new web app, API, or any project with a dev server
- User asks to register/add a project to Dev Router
- After scaffolding a new project

## Steps

### 1. Ensure Project Location
New projects MUST go in `/Users/jerry/Claude/Projects/`. If the project is being created elsewhere, move or create it there.

### 2. Verify Discoverability
Check that the project has one of these so Dev Router can detect it:
- `package.json` with a `dev` or `start` script (for Node.js projects)
- `app.py`, `server.py`, `main.py`, or `manage.py` (for Python projects)
- `index.html` at root (for static sites)
- `project.godot` (for Godot projects)

### 3. Verify npm dev Script
For Node.js projects, ensure `package.json` has:
```json
{
  "scripts": {
    "dev": "next dev"  // or "vite", etc.
  }
}
```

### 4. If Project Is Outside Scanned Dirs
Add the directory to `PROJECT_DIRS` in `/Users/jerry/Claude/dev-router/server.js`:
```js
const PROJECT_DIRS = [
  { path: "/Users/jerry/Claude/Projects", label: "Projects" },
  // add new directory here
];
```

### 5. Confirm
Tell the user: "Project registered in Dev Router. Open Dev Router (localhost:4000) or double-click Dev Router.app on Desktop to launch it."

## Important
- NEVER modify the Dev Router core code unless adding a new scan directory
- The router auto-detects projects — no manual registration needed if in a scanned directory
- All new projects default to `/Users/jerry/Claude/Projects/`
