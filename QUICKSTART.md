# ⚡ QUICK START GUIDE — PreSales Pro with Claude Code

## Files in this package
- `CLAUDE.md` → Drop in your project root (Claude Code reads this automatically)
- `MASTER_PROMPT.md` → Your first message in each Claude Code session

---

## How to use

### First time setup
```bash
mkdir presales_pro
cd presales_pro
# Copy CLAUDE.md here
```

Open Claude Code in this folder, then paste the contents of MASTER_PROMPT.md as your first message.

### Subsequent sessions
Claude Code will re-read CLAUDE.md automatically. Start each session with:
> "Continue building. We completed Phase [X]. Start Phase [X+1]. Follow CLAUDE.md."

### Phase prompts (after Phase 1)

**Phase 2 — Dashboard + Projects:**
> "Phase 1 is done. Build Phase 2: Dashboard screen (mobile + web) and Projects list + detail. Use the shared widgets from Phase 1. Follow CLAUDE.md design rules."

**Phase 3 — Unit + Pipeline:**
> "Phase 2 done. Build Phase 3: Unit detail screen with the interactive horizontal pipeline stepper. The stepper must show all 7 stages, be tappable to update, and animate between states. Follow CLAUDE.md."

**Phase 4 — Requests + Installations:**
> "Phase 3 done. Build Phase 4: Requests CRUD with pipeline stage updates + Installation tracking with per-unit checklists, percentage completion, and activity timeline."

**Phase 5 — Notes + Voice:**
> "Phase 4 done. Build Phase 5: Notes feature with text + voice input (speech_to_text package). Auto-link notes to project/unit. Voice recording UI with waveform animation."

**Phase 6 — AI + Email:**
> "Phase 5 done. Build Phase 6: Email generation for accounting/supplier/storekeeper follow-ups. AI assistant using Anthropic API — suggest next actions, detect delays, daily summary."

**Phase 7 — Polish:**
> "Phase 6 done. Build Phase 7: Offline mode with Hive caching, push notifications with FCM, role-based access control (ADMIN sees everything, ENGINEER sees own projects, STOREKEEPER sees deliveries only)."

---

## Key decisions already made for you
- Flutter + Riverpod (not BLoC, not GetX)
- go_router (not Navigator 2.0 manually)
- FastAPI + PostgreSQL (not Node/Mongo)
- Cormorant Garamond + DM Sans (not Inter/Roboto)
- Phase-by-phase build (not everything at once)

Don't let Claude Code deviate from these — it will cause consistency issues later.

---

## If Claude Code gets stuck or goes off-track
Say: "Stop. Re-read CLAUDE.md and follow it exactly. Then continue."
