# Hostinger Deployment Guide for Studio News

This guide outlines the step-by-step process to deploy your Laravel project to **Hostinger Shared Hosting**.

---

## Phase 1: Local Preparation

Before uploading, prepare your project files locally:

### 1. Build Frontend Assets
Run the production build command in your terminal so all CSS and Javascript are compiled:
```bash
npm run build
```

### 2. Zip the Project
Create a ZIP archive of the project folder. To keep the file size small and avoid uploading unnecessary files, **DO NOT include the following folders in your ZIP**:
* `node_modules` (Not needed in production)
* `.git` / `.github`
* `storage/framework/cache/data/*`
* `storage/framework/sessions/*`
* `storage/framework/views/*.php`
* `storage/logs/*.log`

---

## Phase 2: Uploading to Hostinger

### 1. Upload via File Manager
1. Log in to your **Hostinger hPanel**.
2. Go to **Websites** ➔ **Manage** ➔ **File Manager**.
3. Open the `public_html` folder.
4. Upload your project ZIP file directly into `public_html`.
5. Extract the ZIP file there. 
   *(Note: You can move files so that the Laravel root directory is directly inside `public_html`, meaning folders like `app`, `config`, and `public` are directly in `public_html`).*

### 2. Change the Domain Document Root (Crucial Step)
Laravel serves its files through the `/public` folder. You must tell Hostinger to point your domain to the `/public` subfolder instead of the main directory.
1. Go to **Hostinger hPanel** ➔ **Websites** ➔ **Manage**.
2. Scroll to **Website Settings** ➔ **General** (or search "Folder" or "Change Document Root" in hPanel search).
3. Change the path of the website directory to point to `public_html/public`.
4. Click **Save**.

---

## Phase 3: Setup the Database (MySQL)

We recommend using MySQL instead of SQLite on Hostinger for production speed and reliability.

### 1. Create a MySQL Database on Hostinger
1. In hPanel, search for **Databases** ➔ **MySQL Databases**.
2. Enter a **Database Name**, **Username**, and a secure **Password**.
3. Click **Create**.
4. Note down the details:
   * **Database Name** (starts with `u123456789_...`)
   * **Database User** (starts with `u123456789_...`)
   * **Host** (usually `localhost` or `mysql.hostinger.com`)
   * **Password**

### 2. Configure the `.env` File
1. In Hostinger **File Manager**, find the `.env` file in your root folder.
2. Edit the `.env` file and update the following variables:
   ```env
   APP_ENV=production
   APP_DEBUG=false
   APP_URL=https://yourdomain.co.in

   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1 (or host name provided by Hostinger)
   DB_PORT=3306
   DB_DATABASE=your_hostinger_database_name
   DB_USERNAME=your_hostinger_database_user
   DB_PASSWORD=your_database_password
   ```
3. Save changes.

---

## Phase 4: Production Commands & Symlink

You need to run migrations and link your storage folder so uploaded images show up.

### Option A: Using SSH (Recommended)
1. Go to hPanel ➔ **Advanced** ➔ **SSH Access** and enable it.
2. Connect to your server using PuTTY (Windows) or terminal (`ssh user@ip`).
3. Navigate to your project directory:
   ```bash
   cd public_html
   ```
4. Run the migrations:
   ```bash
   php artisan migrate --force
   php artisan db:seed --force
   ```
5. Create the storage link:
   ```bash
   php artisan storage:link
   ```

### Option B: Using Web Routes (If SSH is not available)
If your Hostinger plan does not support SSH, you can run these commands by adding a temporary route in `routes/web.php`:
1. Open `routes/web.php` in File Manager.
2. Append this code temporarily at the bottom:
   ```php
   Route::get('/run-setup', function () {
       \Artisan::call('migrate:fresh --seed --force');
       \Artisan::call('storage:link');
       return "Database seeded and Storage linked successfully!";
   });
   ```
3. Visit `https://yourdomain.co.in/run-setup` in your browser once.
4. **IMPORTANT:** Delete this route immediately from `routes/web.php` after it prints the success message.

---

## Phase 5: Verification & HTTPS

1. Go to hPanel ➔ **Advanced** ➔ **SSL** and make sure SSL is installed and active on your domain.
2. Visit your domain: `https://yourdomain.co.in`.
3. Check the admin panel at: `https://yourdomain.co.in/adminnitin` to ensure you can login and upload magazines.
