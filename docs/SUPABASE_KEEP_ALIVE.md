# Supabase PostgreSQL Keep-Alive Guide

To prevent Supabase Free Tier projects from automatically pausing after **7 consecutive days (168 hours)** of inactivity, this repository implements a dual-layer automated keep-alive system.

---

## 1. Cloud-Native GitHub Actions Workflow (Primary Engine)

The workflow file is located at [`.github/workflows/supabase-keep-alive.yml`](../.github/workflows/supabase-keep-alive.yml).

### Features
- **Zero Secrets in Source Code**: Designed for **public repositories**. All credentials are read exclusively from GitHub Secrets.
- **Frequency**: Runs automatically every 12 hours via cron (`0 */12 * * *`) at `00:00 UTC` and `12:00 UTC`.
- **Manual Trigger**: Supports `workflow_dispatch` so you can trigger a run at any time from the GitHub web UI.
- **Minimal Resource Usage**: Executes a single-row `select=id&limit=1` REST API call to `therapists`. Takes ~3 to 5 seconds per run (consuming under 3 runner minutes per month out of GitHub's 2,000 free minutes).

### Setup Instructions (Required on GitHub)

Because your repository is public, you must store your Supabase credentials in **GitHub Repository Secrets**:

1. Open your repository on GitHub.
2. Go to **Settings** > **Secrets and variables** > **Actions**.
3. Under **Repository secrets**, click **New repository secret**:
   - **Secret 1**:
     - **Name**: `SUPABASE_URL`
     - **Secret**: `https://************.supabase.co`
   - **Secret 2**:
     - **Name**: `SUPABASE_ANON_KEY`
     - **Secret**: `***********************`
4. Click **Add secret**.

### Testing the Workflow
1. In your GitHub repository, navigate to the **Actions** tab.
2. Click **Supabase Keep-Alive** in the left sidebar.
3. Click **Run workflow** > select branch `articulicare` > click **Run workflow**.
4. The workflow will run and show a green checkmark `✓ Keep-alive ping successful`.

---

## 2. In-App Heartbeat Service (Secondary Layer)

The Flutter application also includes an automated, non-blocking client-side heartbeat:
- Located in [`lib/core/network/supabase_service.dart`](../lib/core/network/supabase_service.dart) (`pingDatabaseHealthCheck()`).
- Initialized in [`lib/main.dart`](../lib/main.dart) during app boot.
- **Throttling**: Debounced in memory so it fires at most once every 12 hours during active mobile user sessions, ensuring organic usage registers active database traffic without redundant network overhead.

---

## 3. Verification

You can confirm that keep-alive activity is registered in the **Supabase Dashboard**:
- Go to **Project Settings** > **General**
- Under project status, your project will remain continuously **Active**.
