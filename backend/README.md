# Career Center Backend (PHP + MySQL)

## 1) Quick start

1. Copy `config.example.php` to `config.php` and set DB credentials.
2. Create database in phpMyAdmin, then import:
   - `backend/database/schema.sql`
   - `backend/database/seed.sql`
3. Run API locally:

```bash
cd backend/public
php -S 127.0.0.1:8080 router.php
```

API base URL: `http://127.0.0.1:8080`

## 2) Test endpoints

- `GET /health`
- `POST /auth/register`
- `POST /auth/login`
- `GET /contacts`
- `GET /news`
- `GET /stories`
- `GET /staff`
- `GET /vacancies?q=...`
- `POST /admin/news` (Bearer `admin`/`staff`)
- `PUT /admin/news/{id}` (Bearer `admin`/`staff`)
- `DELETE /admin/news/{id}` (Bearer `admin`/`staff`)
- `POST /admin/staff` (Bearer `admin`/`staff`)
- `PUT /admin/staff/{id}` (Bearer `admin`/`staff`)
- `DELETE /admin/staff/{id}` (Bearer `admin`/`staff`)

## 3) Seed admin/staff users

- Admin:
  - Login: `admin@aksibgu.local`
  - Password: `admin123`
- Staff:
  - Login: `staff.content@aksibgu.local`
  - Password: `admin123`
  - Login: `staff.news@aksibgu.local`
  - Password: `admin123`

## 4) Web admin panel

- URL: `http://127.0.0.1:8080/admin/login.php`
- Login with `admin` or `staff` account.
- Available sections:
  - Dashboard (`/admin/index.php`)
  - News CRUD (`/admin/news.php`)
  - Stories CRUD (`/admin/stories.php`)
  - Staff CRUD (`/admin/staff.php`)
  - Users & roles (`/admin/users.php`) admin only
  - Audit log (`/admin/audit.php`) admin only
  - Contacts CRUD (`/admin/contacts.php`)
  - Vacancies CRUD (`/admin/vacancies.php`)
  - Content Backup (`/admin/backup.php`) export/import JSON
- Image upload:
  - in News (`image_file`) and Staff (`photo_file`)
  - files are saved to `backend/public/uploads/`
  - allowed formats: jpg/png/webp
  - crop before save:
    - News: aspect ratio `16:9`
    - Staff: aspect ratio `1:1`
- Quick actions in admin tables:
  - show/hide without opening edit form (news/stories/staff)
  - quick up/down sort buttons (stories/staff)
  - drag-and-drop reorder + save button (stories/staff)
  - table search + status filters (news/stories/staff)
  - JSON export/import for content tables (admin only)

> Change password and JWT secret before production.
