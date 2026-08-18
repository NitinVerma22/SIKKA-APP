# Static Export Deployment Walkthrough

We have successfully configured and packaged your Next.js project for cPanel deployment, resolving the 403 Forbidden error.

## Changes Completed

1. **Created [.htaccess](file:///c:/Users/Nitin/OneDrive/Desktop/jupiter-properties-app/public/.htaccess)** inside `public/`:
   - Configured custom rewrite rules to serve static `.html` files automatically.
   - Set up automatic handling of trailing slashes and directories.
   - Redirected missing page routes to the Next.js pre-rendered `404.html` page.
2. **Added renaming scripts:**
   - Created `post-build.js` and `build.js` in the project root.
   - These scripts automatically rename the output folder `_next` to `next_assets` and replace all references to `_next/` with `next_assets/` in all HTML, JS, CSS, and data files.
   - This bypasses Apache/cPanel security rules that return a **403 Forbidden** error for files starting with an underscore.
3. **Rebuilt the Project:**
   - Ran `npm run build` which compiled the pages and automatically executed the rename & replacement scripts.
4. **Packaged the Assets:**
   - Re-created **`out_deploy.zip`** containing all files directly at its root level (including `.htaccess`, `index.html`, and `next_assets` folder instead of `_next`).

---

## Zip File Validation

We verified that `out_deploy.zip` contains:
- `index.html` (the homepage) at the root level referencing `next_assets`.
- `next_assets/` (the renamed assets folder, replacing the blocked `_next` folder).
- `.htaccess` (server configurations) at the root level.
- Sub-pages (like `about/index.html`, `contact/index.html`, etc.) in their respective directories.

---

## Deployment Steps on cPanel

1. **Upload the Zip:**
   - Upload **`out_deploy.zip`** to your target folder (e.g., `public_html/`) on cPanel.
2. **Extract:**
   - Right-click `out_deploy.zip` inside cPanel File Manager and select **Extract**.
   - Make sure you extract the contents directly into `public_html/`.
3. **Check for conflict:**
   - Look for any existing `index.php` or default files in your `public_html/` folder and rename or delete them so they don't block `index.html`.
4. **Test:**
   - Open your site in your browser (preferably in Incognito/Private mode to avoid caching issues).
