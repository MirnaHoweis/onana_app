# 🚀 PRESALES PRO — MASTER PROMPT FOR CLAUDE CODE
> Paste this as your FIRST message in a new Claude Code session.
> Make sure CLAUDE.md is already in your project root before starting.

---

You are a senior full-stack engineer and mobile architect. Read `CLAUDE.md` in the project root first — it contains the complete design system, tech stack, file structure, and build order. Everything in that file is non-negotiable.

## YOUR TASK: BUILD PHASE 1 — FOUNDATION

Start by scaffolding the complete project so all future phases build on a solid, consistent base.

---

### STEP 1 — Flutter Project Setup

Create the Flutter project:
```
flutter create flutter_app --platforms=web,android,ios
```

Then create ALL directories from the structure in CLAUDE.md before writing any files.

---

### STEP 2 — Design System (DO THIS BEFORE ANY UI)

Build the complete design system in `lib/core/theme/`:

**`app_colors.dart`** — all color constants exactly as defined in CLAUDE.md

**`app_typography.dart`** — Google Fonts setup with Cormorant Garamond (headings) + DM Sans (body). Create named text styles: `displayLarge`, `displayMedium`, `headingLarge`, `headingMedium`, `bodyLarge`, `bodyMedium`, `labelLarge`, `labelSmall`

**`app_theme.dart`** — Full `ThemeData` using the above. Light theme only (no dark mode for now). Override: `cardTheme`, `elevatedButtonTheme`, `inputDecorationTheme`, `appBarTheme`, `bottomNavigationBarTheme`, `chipTheme`

---

### STEP 3 — Shared Widget Library

Build these reusable widgets in `lib/core/widgets/`:

**`app_card.dart`**
```
White bg, 12px radius, soft shadow (blur 16, offset y4, opacity 4%)
Constructor: child, padding (default 16), onTap
```

**`app_button.dart`**
```
Primary: soft gold fill, deep charcoal text, 8px radius, 48px height
Secondary: transparent, gold border
Icon variant: leading icon + text
Loading state: circular indicator replaces text
```

**`status_badge.dart`**
```
Pill chip for pipeline stages
Map each PipelineStage enum to: label, background color (15% opacity), text color
```

**`pipeline_stepper.dart`**
```
Horizontal row of steps
Each step: circle (24px) + label below + connector line
States: completed (gold fill + checkmark), active (gold outline + pulsing dot), upcoming (gray)
Tappable — calls onStageTap(stage) callback
```

**`app_text_field.dart`**
```
Sand beige background, no visible border, focus shadow
Label floats on focus
Error state shows below
```

**`section_header.dart`**
```
Title (headingMedium) + optional subtitle (bodySmall, mutedBlueGray) + optional trailing action button
```

**`empty_state.dart`**
```
Centered SVG icon + title + subtitle + optional CTA button
```

**`loading_shimmer.dart`**
```
Shimmer placeholder cards that match the shape of real content
```

---

### STEP 4 — Router Setup

In `lib/core/router/app_router.dart`:

Use `go_router` with `ShellRoute` for bottom nav (mobile) and sidebar (web).

Routes:
```
/ → redirect to /dashboard
/login
/dashboard
/projects
/projects/:projectId
/projects/:projectId/units/:unitId
/requests
/notes
/profile

// Web-only
/pipeline
/installations
/email
/ai
/settings
```

Detect platform with `kIsWeb` — render different shell layouts.

---

### STEP 5 — Mobile Shell (Bottom Nav)

`lib/core/layout/mobile_shell.dart`:
- White bottom nav bar
- 5 tabs: Dashboard, Projects, Requests, Notes, Profile
- Thin line icons (use `flutter_svg` with custom icon set OR `lucide_icons` package)
- Active tab: gold indicator dot above icon, icon turns gold
- Inactive: mutedBlueGray
- No labels (icon-only, cleaner)

---

### STEP 6 — Web Shell (Sidebar Nav)

`lib/core/layout/web_shell.dart`:
- Left sidebar: 240px wide, sand beige bg
- Logo/app name at top (Cormorant Garamond, softGold)
- Nav items with icon + label
- Active item: white card with gold left border
- Main content area: warmWhite bg
- Top bar: search + user avatar + notifications bell

---

### STEP 7 — Backend Scaffold

In `backend/`:

**`requirements.txt`**:
```
fastapi==0.111.0
uvicorn[standard]==0.30.1
sqlalchemy==2.0.31
alembic==1.13.2
psycopg2-binary==2.9.9
pydantic==2.8.2
pydantic-settings==2.3.4
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.9
sendgrid==6.11.0
anthropic==0.30.0
openai==1.35.0
python-dotenv==1.0.1
httpx==0.27.0
```

**`app/main.py`** — FastAPI app with CORS, versioned router (`/api/v1`), lifespan for DB init

**`app/db/database.py`** — async SQLAlchemy engine + session factory

**`.env.example`**:
```
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/presales_pro
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
SENDGRID_API_KEY=
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
```

---

### STEP 8 — Database Models

In `backend/app/models/`, create SQLAlchemy models for ALL tables:

```sql
-- Users
users (id, email, full_name, hashed_password, role ENUM['ADMIN','ENGINEER','STOREKEEPER'], 
       avatar_url, is_active, created_at, updated_at, deleted_at)

-- Projects  
projects (id, name, location, client_name, start_date, end_date, status 
          ENUM['PLANNING','ACTIVE','ON_HOLD','COMPLETED'], created_by UUID→users, 
          created_at, updated_at, deleted_at)

-- Units
units (id, project_id UUID→projects, name, type ENUM['VILLA','APARTMENT','COMMERCIAL'],
       floor, block, notes, created_at, updated_at)

-- Requests (the core workflow entity)
requests (id, unit_id UUID→units, title, description, category 
          ENUM['FURNITURE','APPLIANCE','FINISHING','OTHER'],
          status ENUM['MATERIAL_REQUEST','PO_REQUESTED','PO_CREATED','DELIVERY',
                      'STOREKEEPER_CONFIRMED','INSTALLATION_IN_PROGRESS','INSTALLATION_COMPLETE'],
          priority ENUM['LOW','MEDIUM','HIGH','URGENT'],
          supplier_name, po_number, po_date, expected_delivery_date, 
          actual_delivery_date, assigned_to UUID→users,
          created_by UUID→users, created_at, updated_at)

-- Request Status History (audit trail)
request_history (id, request_id UUID→requests, from_status, to_status, 
                 changed_by UUID→users, notes, created_at)

-- Installation Tracking
installations (id, request_id UUID→requests UNIQUE, 
               completion_percentage INT DEFAULT 0,
               start_date DATE, estimated_end_date DATE, actual_end_date DATE,
               is_partial BOOLEAN DEFAULT false, notes TEXT, created_at, updated_at)

-- Installation Checklist Items
installation_items (id, installation_id UUID→installations, item_name, 
                    is_completed BOOLEAN DEFAULT false, completed_at,
                    completed_by UUID→users, sort_order INT)

-- Notes
notes (id, title, content TEXT, voice_url, project_id UUID→projects NULL,
       unit_id UUID→units NULL, request_id UUID→requests NULL,
       created_by UUID→users, created_at, updated_at, deleted_at)

-- Email Drafts
email_drafts (id, subject, body TEXT, recipient_type ENUM['ACCOUNTING','SUPPLIER','STOREKEEPER'],
              recipient_email, request_id UUID→requests NULL, 
              is_sent BOOLEAN DEFAULT false, sent_at,
              created_by UUID→users, created_at)
```

Create `alembic/` setup and initial migration.

---

### STEP 9 — Auth Endpoints

`backend/app/api/v1/auth.py`:
- `POST /auth/register` 
- `POST /auth/login` → returns access_token + refresh_token
- `POST /auth/refresh`
- `GET /auth/me`

Use bcrypt for passwords, JWT for tokens.

---

### STEP 10 — Dio API Client (Flutter)

`lib/core/api/api_client.dart`:
- Base URL from environment/config
- Auth interceptor: attach Bearer token to every request
- Refresh interceptor: auto-refresh on 401, retry original request
- Error handling: convert API errors to typed `AppException`

`lib/core/api/api_endpoints.dart`: All endpoint constants as static strings.

---

## ✅ WHEN PHASE 1 IS DONE

Tell me "Phase 1 complete" and list exactly what was built. Then I will ask you to start Phase 2 (Dashboard + Projects screens).

## ⚠️ RULES TO FOLLOW THROUGHOUT

1. **Every widget must use theme tokens** — no hardcoded hex values anywhere
2. **Every screen needs 3 states**: loading (shimmer), error (with retry), empty state
3. **Use `const` constructors** wherever possible
4. **Riverpod only** — no `setState`, no `ChangeNotifier`
5. **Type everything** — no `dynamic`, no `var` where type is known
6. **After each file, verify it compiles** — run `flutter analyze` frequently
7. **Keep files under 200 lines** — split into smaller widgets aggressively
8. **Comment complex business logic** only — no obvious comments

---

## 📌 PHASE REFERENCE (DON'T BUILD AHEAD)

| Phase | Focus |
|---|---|
| **1 (NOW)** | Foundation: design system, widgets, router, backend scaffold, DB |
| 2 | Dashboard + Projects list/detail |
| 3 | Unit detail + Pipeline stepper (interactive) |
| 4 | Requests CRUD + installation tracking |
| 5 | Notes + voice input |
| 6 | Email generation + AI assistant |
| 7 | Offline mode + push notifications + roles |

Build only Phase 1. Stop and report when done.
