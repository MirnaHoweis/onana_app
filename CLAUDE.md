# CLAUDE.md — PreSales Pro (Construction Workflow App)
> Drop this file at the root of your project. Claude Code reads it automatically every session.

---

## 🧭 WHAT THIS PROJECT IS

A **cross-platform Flutter app** (mobile + web) for managing pre-sales engineering workflows in construction projects (furniture & appliances).

**Users:** Pre-sales engineers, project managers, storekeepers, suppliers.
**Core job:** Replace chaos (WhatsApp, Excel) with a calm, fast, beautiful workflow system.

---

## 🏗️ TECH STACK (NON-NEGOTIABLE)

| Layer | Choice |
|---|---|
| Frontend | Flutter (single codebase, mobile + web) |
| State Management | Riverpod (flutter_riverpod + riverpod_annotation) |
| Backend | FastAPI (Python 3.11+) |
| Database | PostgreSQL |
| ORM | SQLAlchemy + Alembic |
| Auth | JWT (access + refresh tokens) |
| Email | SendGrid API |
| Voice | OpenAI Whisper API |
| AI Assistant | Anthropic Claude API (claude-sonnet-4-20250514) |
| Deployment | Flutter Web → Vercel / Mobile → App stores |

---

## 🎨 DESIGN SYSTEM (NEVER DEVIATE)

### Color Tokens (define in `lib/core/theme/app_colors.dart`)

```dart
// Backgrounds
static const warmWhite   = Color(0xFFF8F6F2);
static const sandBeige   = Color(0xFFEDE7DF);

// Accent
static const softGold    = Color(0xFFC8A96A);
static const softGoldLight = Color(0xFFDDC48A);

// Text
static const deepCharcoal = Color(0xFF1C1C1C);
static const mutedBlueGray = Color(0xFF6B7C85);

// Status
static const successGreen = Color(0xFF6BAE8E);
static const warningAmber = Color(0xFFD4A843);
static const errorRed     = Color(0xFFBF6B6B);

// Surfaces
static const cardSurface  = Color(0xFFFFFFFF);
static const divider      = Color(0xFFE8E3DB);
```

### Typography (define in `lib/core/theme/app_typography.dart`)
- **Display / Headings:** `Cormorant Garamond` (Google Fonts) — luxury editorial
- **Body / UI:** `DM Sans` — clean, readable, modern
- **Monospace / codes:** `JetBrains Mono`

### Spacing & Radius
- Radius: `12px` (cards), `8px` (buttons/chips), `20px` (bottom sheets)
- Card elevation: `BoxShadow(blurRadius: 16, offset: Offset(0,4), color: Color(0x0A000000))`
- Grid: 16px base unit, 24px section padding

### Component Rules
- Cards: white bg, 12px radius, soft shadow, 16–20px internal padding
- Buttons: gold fill (#C8A96A), deep charcoal text, 8px radius, 48px height
- Inputs: sandBeige bg, no border (use shadow on focus), 12px radius
- Bottom nav (mobile): white bg, gold indicator dot, thin line icons
- Status chips: pill shape, colored bg at 15% opacity + matching text

---

## 📁 PROJECT STRUCTURE

```
presales_pro/
├── CLAUDE.md                    ← this file
│
├── flutter_app/                 ← Flutter project root
│   ├── lib/
│   │   ├── core/
│   │   │   ├── theme/           ← app_colors.dart, app_typography.dart, app_theme.dart
│   │   │   ├── router/          ← go_router setup
│   │   │   ├── api/             ← dio client, interceptors
│   │   │   ├── utils/
│   │   │   └── widgets/         ← shared components
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── dashboard/
│   │   │   ├── projects/
│   │   │   ├── units/
│   │   │   ├── requests/        ← workflow pipeline
│   │   │   ├── installations/
│   │   │   ├── notes/
│   │   │   ├── email/
│   │   │   └── ai_assistant/
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── web/
│
├── backend/                     ← FastAPI project root
│   ├── app/
│   │   ├── api/
│   │   │   └── v1/
│   │   │       ├── auth.py
│   │   │       ├── projects.py
│   │   │       ├── units.py
│   │   │       ├── requests.py
│   │   │       ├── installations.py
│   │   │       ├── notes.py
│   │   │       └── ai.py
│   │   ├── models/              ← SQLAlchemy models
│   │   ├── schemas/             ← Pydantic schemas
│   │   ├── services/            ← business logic
│   │   ├── db/
│   │   └── main.py
│   ├── alembic/
│   ├── requirements.txt
│   └── .env.example
│
└── docs/
    ├── db_schema.md
    └── api_endpoints.md
```

---

## 🔄 WORKFLOW PIPELINE STAGES

This is the core data model. Every **Request** has a `status` enum:

```
MATERIAL_REQUEST → PO_REQUESTED → PO_CREATED → DELIVERY → 
STOREKEEPER_CONFIRMED → INSTALLATION_IN_PROGRESS → INSTALLATION_COMPLETE
```

UI renders this as a **horizontal stepper** with:
- Gold fill = current stage
- Soft green = completed stages
- Muted gray = future stages
- Tap on any stage = bottom sheet to update

---

## 📐 SCREEN MAP

### Mobile (Bottom Nav)
1. **Dashboard** — daily summary cards, pending actions, delay alerts
2. **Projects** — list → Project Detail → Units list
3. **Requests** — kanban or list, filterable by stage
4. **Notes** — voice + text, linked to project/unit
5. **Profile** — user info, role, settings

### Web (Sidebar Nav)
1. **Dashboard** — same as mobile + charts
2. **Projects** — table view with inline edit
3. **Pipeline** — kanban board per project
4. **Installations** — per-unit checklist + % tracker
5. **Email** — draft/send follow-ups
6. **AI Assistant** — chat interface + suggestions panel
7. **Settings**

---

## 🤖 AI ASSISTANT RULES

Use **Claude API** (`claude-sonnet-4-20250514`) for:
- `/api/v1/ai/suggest-actions` → analyze pending items, return next 3 actions
- `/api/v1/ai/detect-delays` → scan POs + deliveries, flag overdue
- `/api/v1/ai/daily-summary` → generate morning digest
- `/api/v1/ai/note-to-task` → convert voice/text note to structured task

System prompt context: always include user's active projects + pending requests snapshot.

---

## 🗄️ DATABASE RULES

- All tables: `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
- All tables: `created_at`, `updated_at` timestamps
- Soft delete: `deleted_at TIMESTAMP NULL`
- All status fields: PostgreSQL ENUM types
- Use Alembic for all migrations — never edit DB directly

---

## ⚡ PERFORMANCE RULES

- Flutter: use `const` constructors everywhere possible
- Riverpod: use `AsyncNotifierProvider` for API data, `NotifierProvider` for local state
- API: all list endpoints paginated (default 20/page)
- Images: WebP format, cached with `cached_network_image`
- Web: lazy load routes with `go_router`

---

## 🚦 BUILD ORDER (PHASES)

When starting a new session, build in this order:

### Phase 1 — Foundation (do this first, always)
- [ ] `pubspec.yaml` with all dependencies
- [ ] `app_colors.dart`, `app_typography.dart`, `app_theme.dart`
- [ ] Shared widgets: `AppCard`, `AppButton`, `AppChip`, `StatusBadge`, `PipelineStepperWidget`
- [ ] FastAPI scaffold + DB connection + auth endpoints
- [ ] PostgreSQL schema + Alembic migrations

### Phase 2 — Core Screens
- [ ] Login / Auth flow
- [ ] Dashboard screen (mobile + web)
- [ ] Projects list + detail
- [ ] Unit detail with pipeline view

### Phase 3 — Workflow Features
- [ ] Request CRUD + pipeline updates
- [ ] Installation tracking + checklists
- [ ] Notes (text + voice)

### Phase 4 — Intelligence Layer
- [ ] Email generation
- [ ] AI assistant integration
- [ ] Delay detection

### Phase 5 — Polish
- [ ] Offline mode (Hive/Drift local cache)
- [ ] Push notifications (FCM)
- [ ] Role-based access (ADMIN, ENGINEER, STOREKEEPER)
- [ ] Animations + transitions

---

## 🚫 NEVER DO

- Never use `setState` — always Riverpod
- Never hardcode colors/text — always use theme tokens
- Never skip error states — every screen needs loading/error/empty UI
- Never use `Navigator.push` — always `context.go()` via go_router
- Never commit `.env` files
- Never use Material default blue theme — always use AppTheme

---

## pubspec.yaml DEPENDENCIES (USE THESE EXACT PACKAGES)

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^14.0.0
  dio: ^5.4.3
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10
  cached_network_image: ^3.3.1
  intl: ^0.19.0
  hive_flutter: ^1.1.0
  speech_to_text: ^6.6.1
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0
  fl_chart: ^0.68.0
  table_calendar: ^3.1.0
  uuid: ^4.4.0
  shared_preferences: ^2.2.3
  flutter_local_notifications: ^17.1.2

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  json_serializable: ^6.7.1
```
