# Walkthrough - Workspace Restoration and Static Build Setup

We have successfully restored the clean and corrected Next.js project structure inside the active workspace `jupiter`, configured build commands for Apache/cPanel environments, and generated release ZIP files for deployment.

## Changes Made

1. **Restored Workspace File Integrity**: 
   - Copied all updated files from `jupiter-properties-app` back to the active workspace `jupiter`.
   - Verified that the source files, styles, components, public assets, and type configurations are fully complete and functional.

2. **Added Dynamic Build Configuration**:
   - Modified [next.config.ts](file:///c:/Users/Nitin/OneDrive/Desktop/jupiter/next.config.ts) to read the `BASE_PATH` environment variable.
   - Configured [package.json](file:///c:/Users/Nitin/OneDrive/Desktop/jupiter/package.json) to support cross-platform environment variables:
     - `npm run build` — Default build for root domain (URL path: `/`)
     - `npm run build:jupiter` — Subfolder build for `/jupiter` directory (URL path: `/jupiter/`)

3. **Apache client-side redirection setup**:
   - Added a generic `.htaccess` file to the static export output directory (`out/`) that handles client-side routing on Apache servers (e.g. cPanel) for both root and subdirectory deployments.

4. **Compiled Release Packages**:
   - Ran compilation and generated static output files.
   - Generated two release packages:
     - [jupiter_release_root.zip](file:///c:/Users/Nitin/OneDrive/Desktop/jupiter/jupiter_release_root.zip): For deployment directly at the domain root (e.g., `https://example.com/`).
     - [jupiter_release_subdirectory.zip](file:///c:/Users/Nitin/OneDrive/Desktop/jupiter/jupiter_release_subdirectory.zip): For deployment under the `/jupiter` folder (e.g., `https://example.com/jupiter/`).

---

## Deployment Instructions for cPanel

Depending on how you want to deploy, select the appropriate zip file:

### Option A: If you want to deploy under a subdirectory (e.g. `domain.com/jupiter/`)
1. Download [jupiter_release_subdirectory.zip](file:///c:/Users/Nitin/OneDrive/Desktop/jupiter/jupiter_release_subdirectory.zip).
2. Open your cPanel File Manager and navigate to `public_html`.
3. Create a folder named `jupiter` (if it doesn't exist).
4. Upload `jupiter_release_subdirectory.zip` inside the `public_html/jupiter` folder.
5. Extract the ZIP file there. Make sure the extracted files (like `index.html`, `_next/`, and `.htaccess`) are placed directly inside `public_html/jupiter/`.

### Option B: If you want to deploy directly to the main domain root (e.g. `domain.com/`)
1. Download [jupiter_release_root.zip](file:///c:/Users/Nitin/OneDrive/Desktop/jupiter/jupiter_release_root.zip).
2. Open your cPanel File Manager and navigate to `public_html`.
3. Upload `jupiter_release_root.zip` inside `public_html`.
4. Extract the ZIP file there. Make sure the extracted files (like `index.html`, `_next/`, and `.htaccess`) are placed directly in `public_html/`.

---

## Verification Results

- Verified that the root build compiles correctly.
- Verified that the subdirectory build compiles and injects the `/jupiter` path prefix into all asset links (CSS, JS, and Images) and internal page routing references (as verified in the generated `out/index.html`).
- Checked ZIP folder generation sizes (~1.7 MB).
