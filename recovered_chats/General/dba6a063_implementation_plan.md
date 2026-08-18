# Static Export Analysis & cPanel Deployment Plan

We have thoroughly analyzed the codebase and the Next.js static build behavior. This plan outlines the technical analysis of why you encountered issues, why the `.txt` files exist, and the proposed changes to ensure a smooth, working cPanel deployment.

## Technical Analysis & Findings

### 1. Why do `.txt` files exist in the build?
Under Next.js App Router (Next.js 13+ and Next.js 16.2.10 used here), running a static build (`output: 'export'`) generates two files for every route:
- **`index.html`** (e.g., `out/about/index.html`): The pre-rendered HTML page used when a user directly loads the URL or shares a link.
- **`__next._full.txt`, `index.txt`, etc.** (e.g., `out/about/__next._full.txt`): The serialized React Server Component (RSC) payload. Next.js uses this data for client-side navigation. When a user clicks a link (using Next.js `<Link>`) inside the app, the router fetches this `.txt` file instead of reloading the entire HTML page.
- **Can they be disabled?** No. There is no config in Next.js to disable these. Removing them will break the page transitions and cause React hydration errors. They must be uploaded along with the HTML files.

### 2. Why did you get "Page Not Found" (404) on cPanel?
A 404 error on a cPanel Apache server with Next.js static exports usually happens due to:
1. **Incorrect Upload Directory:** If the files are uploaded to a subfolder like `public_html/out/` instead of `public_html/`, accessing `domain.com` will result in a 404 (or directory listing). Next.js asset paths start with absolute paths (e.g. `/_next/static/...`), meaning they **must** be hosted at the root directory of the domain/subdomain.
2. **Conflicting Index File:** If there is an existing `index.php` or `default.html` in the root `public_html/` directory, Apache might prioritize it over `index.html`.
3. **Apache Directory Slash Redirects or Rewrite Rules:** If a user accesses a URL without a trailing slash (e.g. `domain.com/about`) and the server's `.htaccess` is missing or has incorrect rewrite rules, it can fail to locate the directory.

---

## Proposed Changes

### [Component Name] cPanel Configuration & Packaging

To make deployment plug-and-play and resolve 404 errors automatically, we will add a custom `.htaccess` routing rule configuration and package it directly into the static build.

#### [NEW] [.htaccess](file:///c:/Users/Nitin/OneDrive/Desktop/jupiter-properties-app/public/.htaccess)
We will create a `.htaccess` file inside the `public/` directory. Next.js automatically copies all files in `public/` to the build output (`out/`) during build. This file will:
- Prevent directory listings (`Options -Indexes`).
- Set `index.html` as the default index file (`DirectoryIndex index.html`).
- Ensure Apache redirects are handled correctly.
- Set up a fallback to the Next.js `404.html` page for any invalid URLs.

```apache
# Disable directory index browsing
Options -Indexes

# Set default document
DirectoryIndex index.html

# Enable rewrite engine
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /

  # Serve existing files/directories directly
  RewriteCond %{REQUEST_FILENAME} -f [OR]
  RewriteCond %{REQUEST_FILENAME} -d
  RewriteRule ^ - [L]

  # Fallback to Next.js 404 page for missing routes
  ErrorDocument 404 /404.html
</IfModule>
```

---

## Action Checklist

1. **Create `.htaccess`** in [public/](file:///c:/Users/Nitin/OneDrive/Desktop/jupiter-properties-app/public/).
2. **Run `npm run build`** to generate the fresh build in `out/` which will now include the `.htaccess` file automatically.
3. **Zip the contents** of the `out` directory into `out_deploy.zip`.
4. **Provide instructions** to deploy the zip file to `public_html` and check for conflicting files (like `index.php`).

---

## Verification Plan

### Automated Verification
- Verify that `out/.htaccess` exists after building.
- Check that `out_deploy.zip` contains `.htaccess` and `index.html` files at the root of the archive.
