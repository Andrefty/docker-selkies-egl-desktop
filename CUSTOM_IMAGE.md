# Custom Selkies Image Workflow

The upstream image can look stale if it is not rebuilt recently.
This repo is configured so your fork can publish a Steam-enabled custom image to GHCR only when you explicitly run the workflow.

## What this custom image does

1. Installs Steam from Valve's `steam_latest.deb` plus pressure-vessel related dependencies on amd64 builds.
2. Pre-bootstraps Steam client files during image build and stores a reusable seed in the image.
3. Hydrates Steam seed files into runtime home on first launch (works with Apptainer `--home` bind behavior).
4. Supports disabling Steam prebootstrap from workflow input if you need faster builds.
5. Keeps LibreOffice optional (off by default).
6. Rebuilds with `no-cache: true` so Lutris/Heroic/Selkies/KasmVNC version checks happen at build time.
7. Runs only via manual `workflow_dispatch`.
8. Does not run on schedule, push, or pull request by default.

## 1) Fork and publish

1. Fork this repository to your GitHub account.
2. In your fork, open Actions and enable workflows.
3. Run workflow [`.github/workflows/container-publish.yml`](.github/workflows/container-publish.yml) via `workflow_dispatch`.
4. Optional input: `include_libreoffice=true` if you want LibreOffice in that build.
5. Optional input: `steam_prebootstrap=false` if you want to skip Steam prebootstrap for faster builds.
6. Published image location:
   - `ghcr.io/<your-github-user>/nvidia-egl-desktop-custom:latest`

## 1.1) Cost control

1. The workflow is manual-only, so no background rebuilds consume Actions minutes.
2. Pushes and pull requests do not trigger image builds by default.
3. Storage/transfer billing depends on your GitHub plan and usage; manual runs keep usage predictable.

## 2) Use custom image in SLURM jobs

Use `IMAGE_URI` when submitting jobs.

```bash
sbatch -p xl --export=ALL,IMAGE_URI=docker://ghcr.io/<your-github-user>/nvidia-egl-desktop-custom:latest job_selkies.sh

sbatch -p xl --export=ALL,IMAGE_URI=docker://ghcr.io/<your-github-user>/nvidia-egl-desktop-custom:latest job_selkies_webrtc.sh

sbatch -p xl --export=ALL,IMAGE_URI=docker://ghcr.io/<your-github-user>/nvidia-egl-desktop-custom:latest job_selkies_webrtc_tunnel.sh
```

## 2.1) If your GHCR package is private

Apptainer can pull private GHCR images when credentials are exported.
Use a GitHub token with package read access.

```bash
sbatch -p xl \
   --export=ALL,IMAGE_URI=docker://ghcr.io/<your-github-user>/nvidia-egl-desktop-custom:latest,APPTAINER_DOCKER_USERNAME=<your-github-user>,APPTAINER_DOCKER_PASSWORD=<github-token-with-read-packages> \
   job_selkies_webrtc_tunnel.sh
```

## 3) Reproducible tags (recommended)

Instead of `latest`, pin a dated tag:

```text
docker://ghcr.io/<your-github-user>/nvidia-egl-desktop-custom:24.04-YYYYMMDDHHMMSS
```

Pinning makes rollback/debug easier when testing changes.

## 4) Build right before playing

If freshness matters for launchers/apps, trigger `workflow_dispatch` before starting your SLURM job.
This is usually enough; publishing publicly is optional.

## 5) Steam notes

1. Steam prebootstrap can add build time, but reduces first interactive setup friction.
2. Seed files are stored outside `/home/ubuntu` inside the image and copied into runtime home on first launch.
3. If you need the smallest build time, set `steam_prebootstrap=false` and let Steam bootstrap at runtime.
