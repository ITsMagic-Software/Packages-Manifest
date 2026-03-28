# Packages-Manifest
Manifest for itsmagic package manager

How to upload packages
https://itsmagic.com.br/documentation/docs/topics/marketplace-submit-package

## Automated Database Build (GitHub Actions)
On every push to the `main` branch, a GitHub Actions workflow runs the build script and regenerates the database files.
This ensures the published package list and version timestamp stay in sync with the latest manifests.

What the workflow does:
- Runs `tools/compiler/buildDatabase.py`
- Validates all `packages/**/manifest.json` files
- Generates `release/autogen_database.json`
- Generates `release/autogen_database.json.gz` (GZIP compressed)
- Generates `release/autogen_version.txt` with the current date/time
- Commits and pushes the generated files back to the repository (only if they changed)

If the workflow fails, the build is stopped and the error log will indicate which package and field caused the failure.
