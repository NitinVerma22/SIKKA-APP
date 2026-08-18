# Task List: Migrate React to Laravel

- `[x]` Create new Laravel project (`purer-laravel`)
- `[x]` Configure MySQL database connection
- `[x]` Create database migrations (Articles, Categories, etc.) to prepare for a dynamic news site
- `[x]` Set up Tailwind CSS and front-end assets via Vite
- `[x]` Migrate master layout from React `site-layout.tsx` to `app.blade.php`
- `[x]` Migrate homepage (`index.blade.php` / `welcome.blade.php`)
- `[/]` Migrate About, Contact, Privacy, Careers pages
- `[ ]` Migrate Article listing and detail pages
- `[ ]` Migrate remaining pages (Magazine, Competition, etc.)
- `[x]` Set up basic Controllers for routing

**Phase 2: Admin Panel (Filament)**
- `[/]` Switch to SQLite temporarily for seamless testing
- `[ ]` Install Filament v3
- `[ ]` Generate Category Resource for Admin Panel
- `[ ]` Generate Article Resource for Admin Panel
- `[ ]` Create default Admin User

**Phase 3: Custom Admin Panel (Full CRUD & Responsive)**
- `[x]` Create migrations for Banners, Articles (details), Categories (name_hi)
- `[x]` Make Admin UI beautiful and mobile-responsive
- `[x]` Add Edit/Delete for Articles with all frontend details
- `[x]` Create Banners CRUD
**Phase 4: Online Magazines**
- `[x]` Create migration and Model for Magazines (PDF uploads)
- `[x]` Create Admin Magazine CRUD (Controllers, Routes, Views)
- `[x]` Design frontend Online Magazine page
- `[x]` Seed dummy magazine data
- `[x]` Update Walkthrough
- `[ ]` Create default Admin User
