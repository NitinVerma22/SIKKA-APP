# Implementation Plan - Restoring Workspace and Configuring Static Build

The user wants to restore the `jupiter` workspace and configure it for a static export (`out` folder) that can be easily deployed on cPanel (both at the root level or inside a `/jupiter` subdirectory).

## Proposed Changes

We will restore the project files into the main `jupiter` workspace, install dependencies, and configure build scripts to support different deployment paths.

---

### Workspace Restoration

We will copy all working project files from `jupiter-properties-app` back to the active workspace `jupiter`.

#### [NEW] All Project Files in `jupiter`
- Copy `src/`
- Copy `public/`
- Copy `package.json`
- Copy `package-lock.json`
- Copy `tsconfig.json`
- Copy `next.config.ts`
- Copy `postcss.config.mjs`
- Copy `eslint.config.mjs`
- Copy `next-env.d.ts`
- Copy `.gitignore`

---

### Build Configuration

We will modify `next.config.ts` and `package.json` to allow building with a configurable `basePath` (for subdirectory deployment like `/jupiter` on cPanel).

#### [MODIFY] [next.config.ts](file:///C:/Users/Nitin/OneDrive/Desktop/jupiter/next.config.ts)
We will update the configuration to read the `BASE_PATH` environment variable:
```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export',
  trailingSlash: true,
  basePath: process.env.BASE_PATH || undefined,
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
```

#### [MODIFY] [package.json](file:///C:/Users/Nitin/OneDrive/Desktop/jupiter/package.json)
We will add two build scripts:
1. `build` - Standard build for root domain deployment.
2. `build:jupiter` - Cross-platform script to build specifically for the `/jupiter` subdirectory.
```json
"scripts": {
  "dev": "next dev",
  "build": "next build",
  "build:jupiter": "node -e \"process.env.BASE_PATH='/jupiter'; require('child_process').execSync('next build', {stdio:'inherit'})\"",
  "start": "next start",
  "lint": "eslint"
}
```

---

### Verification and Packaging

We will run the builds and verify that:
1. `npm run build:jupiter` successfully exports the site to the `out` directory.
2. We create two zip archives:
   - `jupiter_release_root.zip` (for root deployment)
   - `jupiter_release_subdirectory.zip` (for `/jupiter` subdirectory deployment)
3. Both zip archives contain the `.htaccess` file for routing:
```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_URI} !/$
RewriteRule ^(.*)$ $1/ [R=301,L]

RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)/$ $1/index.html [L]
RewriteRule ^(.*)$ $1/index.html [L]
```

## Verification Plan

### Automated Tests
- Run `npm run build:jupiter` to verify compile succeeds.
- Run `npm run build` to verify root compile succeeds.

### Manual Verification
- Review the paths inside the generated `out/index.html` for both builds to confirm asset paths start with `/jupiter/` or `/` respectively.
