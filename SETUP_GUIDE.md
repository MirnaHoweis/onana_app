# 🔗 GitHub + Vercel Setup Guide
> Do this once. After that, every push to `main` auto-deploys.

---

## STEP 1 — Create the GitHub Repo

```bash
# In your presales_pro folder
git init
git add .
git commit -m "Initial commit — PreSales Pro"

# On GitHub: create a new repo called "presales-pro" (no README, no .gitignore)
# Then connect it:
git remote add origin https://github.com/YOUR_USERNAME/presales-pro.git
git branch -M main
git push -u origin main
```

---

## STEP 2 — Connect Vercel to GitHub

1. Go to [vercel.com](https://vercel.com) → **Add New Project**
2. Import your `presales-pro` GitHub repo
3. **Framework Preset:** select **Other**
4. **Root Directory:** leave as `/` (the vercel.json at root handles routing)
5. **Build Command:** leave empty (GitHub Actions does the build)
6. **Output Directory:** `flutter_app/build/web`
7. Click **Deploy** — it'll fail the first time, that's fine. You just need the project to exist.

---

## STEP 3 — Get Your Vercel IDs

Run this in your terminal after installing Vercel CLI (`npm i -g vercel`):

```bash
vercel login
vercel link   # in your presales_pro folder — links to the project you just created
cat .vercel/project.json
```

You'll see:
```json
{
  "orgId": "team_xxxxxxxxxxxx",
  "projectId": "prj_xxxxxxxxxxxx"
}
```

Save both values — you need them in Step 4.

---

## STEP 4 — Add GitHub Secrets

Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these 4 secrets:

| Secret Name | Value | How to get it |
|---|---|---|
| `VERCEL_TOKEN` | Your Vercel token | vercel.com → Settings → Tokens → Create |
| `VERCEL_ORG_ID` | `orgId` from Step 3 | From `.vercel/project.json` |
| `VERCEL_PROJECT_ID` | `projectId` from Step 3 | From `.vercel/project.json` |
| `API_BASE_URL` | Your backend URL | Add this later when backend is deployed |

---

## STEP 5 — Test It

```bash
git add .
git commit -m "Add CI/CD pipeline"
git push origin main
```

Go to your GitHub repo → **Actions** tab. You should see the workflow running.
When it's green ✅ → your Flutter web app is live on Vercel.

---

## STEP 6 — Backend Deployment (Do Later)

When you're ready to deploy FastAPI, pick one:

### Option A: Railway (Recommended — easiest)
1. Go to [railway.app](https://railway.app) → New Project → Deploy from GitHub
2. Select the `presales-pro` repo → set root directory to `backend/`
3. Railway auto-detects FastAPI. Add env vars from `.env.example`
4. Copy the Railway URL → add it as `API_BASE_URL` in GitHub Secrets
5. Update `CLAUDE.md` line: `API_BASE_URL=https://your-app.up.railway.app`

### Option B: Render
1. Go to [render.com](https://render.com) → New Web Service → Connect GitHub repo
2. Root directory: `backend/`
3. Build command: `pip install -r requirements.txt`
4. Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Add env vars → copy URL → same as above

---

## YOUR DEPLOY FLOW (After Setup)

```
You push to main
       ↓
GitHub Actions triggers
       ↓
Flutter web builds (release mode)
       ↓
Deployed to Vercel production URL
       ↓
Backend linted + tests run
```

**Your live URL:** `https://presales-pro.vercel.app` (or custom domain)

---

## ADD THIS TO CLAUDE.md (paste at the bottom)

```markdown
## 🚀 DEPLOYMENT

- Flutter Web → Vercel (auto-deploy via GitHub Actions on push to main)
- Backend → TBD (Railway or Render)
- Repo: https://github.com/YOUR_USERNAME/presales-pro

### Git workflow
- Always commit to feature branches: `git checkout -b feature/dashboard`
- Merge to main only when feature is complete and tested
- Never commit .env files (they are in .gitignore)
- Run `flutter analyze` before every commit

### Environment variables
Flutter: passed at build time via `--dart-define=KEY=VALUE`
Backend: loaded from `.env` file (never committed)
CI: stored as GitHub Secrets
```
