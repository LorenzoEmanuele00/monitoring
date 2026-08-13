# Credential setup — mise_pwa walking skeleton

Provisioning guide for the three credentials `infrastructure-001-walking-skeleton` needs, per
ADR-0012's credential model. Target repo/project: `github.com/LorenzoEmanuele00/mise_pwa`.

**Sequencing note:** the app's real Keychain storage (ADR-0007, `MCSecrets`, shared access group)
only exists once `MissionControl.app` is built and signed — that's what the walking-skeleton
spike does, and it hasn't started yet. So these credentials are provisioned now and held in
**macOS Keychain Access.app** (your login keychain, not the app's future data-protection
keychain) as an interim, safe-at-rest holding spot. Delete each item there once you've pasted it
into the real app's "Connect integration" sheet during the spike.

Never: paste any of these into an Obsidian note, a `.env` file, or anywhere inside this git repo.

---

## 1. GitHub — fine-grained PAT

1. github.com → your avatar → **Settings** → **Developer settings** → **Personal access tokens**
   → **Fine-grained tokens** → **Generate new token**.
   (Direct link: `github.com/settings/personal-access-tokens/new`)
2. **Token name:** `mission-control-mise_pwa`
3. **Resource owner:** your account (`LorenzoEmanuele00`)
4. **Expiration:** GitHub caps fine-grained PATs at 1 year — pick the max. ADR-0012 already
   accounts for manual rotation (the app raises "credential expired" on 401/403 once it exists,
   but there's no reminder mechanism until then — worth a calendar note near expiry).
5. **Repository access:** "Only select repositories" → `mise_pwa`
6. **Permissions** (Repository permissions tab), read-only per ADR-0012:
   - Contents: Read-only
   - Metadata: Read-only (mandatory, auto-selected)
   - Pull requests: Read-only
   - Actions: Read-only (write deferred until a "re-run workflow" Quick Action ships)
7. **Generate token** → copy it immediately, it's shown once.
8. Save it in Keychain Access (see step 4 below)

## 2. Firebase Hosting — service-account JSON key

Firebase service accounts are Google Cloud IAM service accounts under the hood.

1. console.cloud.google.com → select the GCP project backing mise_pwa's Firebase project (top
   project switcher).
2. **IAM & Admin** → **Service Accounts** → **Create Service Account**.
3. Name: `mission-control-readonly` (or similar).
4. **Grant this service account access to project** → role: **Firebase Hosting Viewer**
   (`roles/firebasehosting.viewer`) — nothing broader, per ADR-0012/ADR-0002.
5. Click the new service account → **Keys** tab → **Add Key** → **Create new key** → **JSON**.
   A `.json` file downloads — this _is_ the credential (a JWT-bearer key, not a bearer token).
6. Import the JSON's contents into Keychain Access as a Secure Note (see step 4), then **delete
   the downloaded file** from Downloads/disk — don't leave a plaintext copy sitting around.

## 3. Supabase — Management API personal access token

1. supabase.com/dashboard/account/tokens (Account → Access Tokens).
2. **Generate new token** → name it `mission-control`.
3. Copy immediately — shown once.
4. **Heads up:** Supabase Management API tokens are account-wide, not project-scoped, as far as
   I'm aware — double check this in the dashboard when you get there. If that's still true, this
   token technically has more reach than "just mise_pwa," which is a real gap against ADR-0002's
   minimal-privilege intent worth being aware of (not a blocker — the ADR already excludes the
   much more dangerous `service_role` key).

## 4. Interim storage — Keychain Access.app

For each of the three credentials above:

1. Open **Keychain Access** (Spotlight → "Keychain Access").
2. Make sure **login** keychain is selected (left sidebar).
3. **File → New Password Item** (for the GitHub PAT and Supabase PAT) or **File → New Secure
   Note Item** (for the Firebase JSON key, since it's multi-line).
4. Name it clearly, e.g. `mission-control-github-pat`, `mission-control-firebase-key`,
   `mission-control-supabase-pat`.
5. Paste the value, save.
6. When the walking-skeleton spike reaches "attach mise_pwa's integrations," open each item here,
   copy the value into the app's Connect Integration sheet, then delete the Keychain Access item
   — the app's own `MCSecrets` store becomes the single source of truth from then on.

## Status

- [x] GitHub fine-grained PAT created and stored
- [x] Firebase service-account JSON key created and stored
- [x] Supabase Management API PAT created and stored
