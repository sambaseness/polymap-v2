# PolyMap — Project Management Philosophy

> **Project**: PolyMap v2 — Multi-tenant SaaS campus navigation
> **Team**: Built by Pape B. Thiombane (single contributor)
> **Stack**: React 19 + TypeScript + Vite + Tailwind 4 + Supabase + Vercel Serverless
> **Flutter Version**: 3.27.0+

---

## 1. Development Philosophy

### 1.1 Phased Workflow (Non-Negotiable)

Every feature follows this sequence. **Never skip phases.**

```
AUDIT → ARCHITECTURE → FOUNDATION → CORE → BUSINESS WORKSPACE → STOREFRONT → BILLING → AUTOMATIONS → TESTS → VALIDATION → MAIN
```

| Phase | Purpose | Gate |
|-------|---------|------|
| **AUDIT** | Understand the problem, existing code, and constraints | Document findings in `DOCS/` |
| **ARCHITECTURE** | Design the solution, choose libraries, define interfaces | Architecture decision in `DOCS/` |
| **FOUNDATION** | Set up dependencies, create data models, wire up state | `flutter pub get` succeeds, `flutter analyze` clean |
| **CORE** | Build the core feature (e.g., map widget, routing) | Feature works end-to-end |
| **BUSINESS WORKSPACE** | Add business logic, organizations, activities | Full feature with data |
| **STOREFRONT** | UI/UX polish, branding, mobile-first | Visual review |
| **BILLING** | Payment integration | Test mode only |
| **AUTOMATIONS** | Cron jobs, notifications, background tasks | Tested and documented |
| **TESTS** | Unit, widget, integration tests | All tests passing |
| **VALIDATION** | Final verification, edge cases, performance | Sign-off checklist |
| **MAIN** | Merge to main with CI/CD green | Branch protection enforced |

### 1.2 Core Principles

1. **Don't code without audit** — Always document the problem first
2. **Validate against real code, not assumptions** — Test on actual devices
3. **Document everything** — Every decision, every dependency, every workaround
4. **Use compatibility layers + feature flags** — Never break existing systems
5. **Never assume all users are merchants** — Vocabulary: User/Organization/Business/Activity/Business Type/Business Workspace/Team/Storefront/Platform Admin

---

## 2. Repository Structure

```
polymap-v2/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # GitHub Actions CI/CD pipeline
├── lib/
│   ├── data/                   # Data layer (repositories, models)
│   │   ├── map_repository.dart
│   │   └── models.dart
│   ├── services/               # Business logic services
│   │   ├── location_service.dart
│   │   └── route_service.dart
│   ├── widgets/                # Reusable widgets
│   │   └── poly_map_view.dart
│   ├── screens/                # Full-screen views
│   │   ├── map_screen.dart
│   │   ├── home_screen.dart
│   │   ├── route_screen.dart
│   │   └── nav2d_screen.dart
│   ├── state/                  # Provider state management
│   │   └── app_state.dart
│   ├── theme/                  # Design tokens
│   │   ├── pm_colors.dart
│   │   ├── pm_layout.dart
│   │   ├── pm_text.dart
│   │   └── pm_tokens.dart
│   ├── navigation.dart         # Router configuration
│   └── main.dart               # Entry point
├── DOCS/                       # Research & documentation
│   └── MAP_FEATURE_REPORT.md
├── pubspec.yaml
├── AGENTS.md                   # This file
└── README.md
```

---

## 3. Branch Strategy

### Branch Protection Rules

| Branch | Protection |
|--------|-----------|
| `main` | **Protected** — no force push, require PR review, require CI checks |
| `develop` | Protected — require CI checks before merge |

### Workflow

```
feature/* → develop → main
```

- All features start on a feature branch off `develop`
- Merge to `develop` after `flutter analyze` passes and tests pass
- Merge to `main` only through PR with CI/CD green
- **Never force push to `main`** (protected by GitHub branch rules)

---

## 4. CI/CD Pipeline

### What runs automatically

| Trigger | Jobs |
|---------|------|
| Push to `main` or `develop` | Analyze → Test → Build Web → Deploy |
| PR to `main` | Analyze → Test → Build Web |
| Push to `develop` | Deploy staging to Vercel |
| Push to `main` | Deploy production to Vercel |

### Deployment targets

- **Staging**: `develop` branch → Vercel preview deployment
- **Production**: `main` branch → Vercel production deployment

---

## 5. Code Standards

- `flutter analyze --no-fatal-infos` must pass before every commit
- Use meaningful commit messages with conventional format
- All new dependencies must be documented in `DOCS/`
- API keys must never be committed — use GitHub Secrets
- Vocabulary: **User/Organization/Business/Activity** (NOT "merchant")

---

## 6. Known Issues & Constraints

- `open_route_service` requires API key (stored in GitHub Secrets: `OPENROUTESERVICE_API_KEY`)
- Vercel requires `VERCEL_TOKEN` in GitHub Secrets
- `flutter_map_location_marker` needs platform-specific permissions
- Old `campus_map.dart` and `real_campus_map.dart` are dead code (not yet deleted)

---

## 7. Quick Commands

```bash
# Development
flutter pub get
flutter analyze
flutter run -d chrome

# Testing
flutter test

# Build
flutter build web --wasm

# CI/CD
gh repo view polymap-v2
gh secret set OPENROUTESERVICE_API_KEY --repo=sambaseness/polymap-v2
```
