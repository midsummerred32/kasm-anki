# Anki on Kasm Workspaces

Custom Kasm image that adds Anki on top of Kasm's `core-ubuntu-focal` base image,
with a bot that keeps both Anki and the Kasm base image pinned to their latest
versions automatically.

## How it works

- **`versions.env`** is the single source of truth for `ANKI_VERSION` and
  `KASM_BASE_TAG`.
- **`.github/workflows/update-versions.yml`** runs daily (and on manual
  dispatch). It checks:
  - the latest Anki release tag via the GitHub API
  - the latest clean semver tag of `kasmweb/core-ubuntu-focal` via the Docker
    Hub API
  - if either is newer than what's pinned, it updates `versions.env` and opens
    a PR for you to review/merge.
- **`.github/workflows/build-image.yml`** runs on every push to `main` that
  touches `Dockerfile`, `versions.env`, or `anki.desktop`. It builds the image
  with the pinned versions as build args and pushes to GHCR
  (`ghcr.io/<owner>/<repo>`), tagged `latest` and `anki-<version>`.

So the flow is: bot opens PR → you review/merge → build workflow fires
automatically → new image lands in GHCR.

## One-time setup

1. Push this repo to GitHub.
2. Nothing else to configure — both workflows use the built-in
   `GITHUB_TOKEN`, which already has permission to push to GHCR for your own
   repo's packages.
3. Optionally make the GHCR package public: repo → Packages → your image →
   Package settings → Change visibility.

## Registering the image in Kasm

1. Kasm admin panel → **Workspaces → Images → Add Image**.
2. Image name: `ghcr.io/<owner>/<repo>:latest`
3. Container type / friendly name / memory-CPU limits: same as you'd use for
   `kasmweb/core-ubuntu-focal`.
4. Assign it to a user group.

If your GHCR package is private, add a registry credential in
**Workspaces → Registries** with a GitHub PAT that has `read:packages` scope.

## Notes / things to double check periodically

- Anki occasionally changes its release asset naming and packaging (it moved
  from `anki-<version>-linux-qt6.tar.zst` to `anki-<version>-linux-x86_64.tar.zst`
  as of the 26.05 "Briefcase" repackaging, for example). If a build ever fails
  after a version bump, check the current instructions at
  [docs.ankiweb.net/platform/linux/installing.html](https://docs.ankiweb.net/platform/linux/installing.html)
  and adjust the `wget` URL / extracted folder name / dependency list in the
  `Dockerfile` to match.
- For Anki data (collection, sync login, add-ons) to persist across sessions,
  configure a persistent profile / persistent home directory for this image in
  Kasm — otherwise everything resets when the container is destroyed.
- The dependency list in the `Dockerfile` covers Anki's Qt6 GUI requirements
  as of late 2025/2026 builds; if you see a "missing shared library" error on
  launch, the error message will name the missing `.so` — install the
  matching `apt` package and add it to the `RUN apt-get install` line.