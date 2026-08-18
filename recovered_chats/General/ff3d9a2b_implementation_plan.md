# Convert to Pure SPA for Hostinger Static Deployment

The current app uses TanStack Start, which mandates Server-Side Rendering (SSR) and outputs a Node server. To allow deployment to standard static hosting (like Hostinger's `public_html` directory), we need to convert the application architecture into a pure Client-Side Rendered (CSR) Single Page Application (SPA).

## Proposed Changes

We will remove the SSR wrapper and switch to a standard Vite + React + TanStack Router SPA setup.

### Core Configuration
#### [MODIFY] [vite.config.ts](file:///c:/Users/Nitin/Downloads/lovable-project-a20223f9%20%281%29/vite.config.ts)
- Replace `@lovable.dev/vite-tanstack-config` with standard Vite configuration.
- Add standard plugins: `@vitejs/plugin-react`, `@tanstack/router-plugin/vite`, `vite-tsconfig-paths`, and `@tailwindcss/vite`.

### Entry Points
#### [NEW] [index.html](file:///c:/Users/Nitin/Downloads/lovable-project-a20223f9%20%281%29/index.html)
- Create a standard HTML file at the root to serve as the SPA entry point.
- Include a `<div id="root"></div>` and a script tag pointing to `src/main.tsx`.

#### [NEW] [src/main.tsx](file:///c:/Users/Nitin/Downloads/lovable-project-a20223f9%20%281%29/src/main.tsx)
- Create the standard React 19 client entry point.
- Bootstraps the application using `createRoot` and mounts the `RouterProvider`.

### Route Modifications
#### [MODIFY] [src/routes/__root.tsx](file:///c:/Users/Nitin/Downloads/lovable-project-a20223f9%20%281%29/src/routes/__root.tsx)
- Remove all `@tanstack/react-start` imports (like `HeadContent`, `Scripts`, `createRootRouteWithContext`).
- Switch to using `createRootRouteWithContext` from `@tanstack/react-router`.
- Remove the `RootShell` component that hardcoded `<html>` and `<body>` tags (these will now be handled by `index.html`).

#### [DELETE] [src/start.ts](file:///c:/Users/Nitin/Downloads/lovable-project-a20223f9%20%281%29/src/start.ts)
- No longer needed in a pure SPA.

#### [DELETE] [src/server.ts](file:///c:/Users/Nitin/Downloads/lovable-project-a20223f9%20%281%29/src/server.ts)
- SSR entry point is no longer required.

## Verification Plan

### Automated Build
- Run `npm run build` locally.
- Verify that a `dist/` directory is successfully created containing pure static files (`index.html`, `assets/`, etc.).

### Manual Verification
- Compress the `dist/` directory into a `.zip` file for the user to download and deploy on Hostinger.
