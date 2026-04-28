# Solomon — Implementation Status

**Updated:** 2026-04-28 (Faza 29 commit)
**Spec ref:** `SOLOMON-V1-MASTER-SPEC.md` (1.0 Final, 25 aprilie 2026)

---

## Conform spec §13.5 (planul 12 săptămâni)

- [x] **Săpt 1-2** — Setup Xcode + Core Data schema (MLX scaffold) → Faze 1-2
- [x] **Săpt 3-4** — Email parser + sender registry (~100 senderi) → Faza 6
- [x] **Săpt 5-6** — Analytics: CashFlow, Pattern, Subscription, Spiral, Goal, SafeToSpend, Suspicious → Faze 4 + 16
- [x] **Săpt 7-8** — Wow Moment + Pot? Query → Faze 7-8
- [x] **Săpt 9** — Restul celor 8 momente → Faza 8
- [x] **Săpt 10** — Apărare: IFN, BNPL, Scam, CSALB Bridge → Faze 21 + 25B
- [ ] **Săpt 11** — Onboarding flow + UI polish → Faza 13 done, **UI rough — Faza 27 NEXT**
- [ ] **Săpt 12** — Testing intern + TestFlight beta — pending UI complete

---

## Faze proprii (cronologic)

| Faza | Status | Conținut |
|---|---|---|
| 1-5 | ✅ | Domain models + Storage + Analytics fundamental |
| 6 | ✅ | SolomonEmail (parser + 100 senderi) |
| 7 | ✅ | SolomonWeb (DDG + cache + scam) |
| 8 | ✅ | SolomonMoments (8 builderi + orchestrator) |
| 9 | ✅ | OllamaLLMProvider fix (`think:false`) |
| 10 | ✅ | iOS App Shell + DS v0 inițial |
| 11 | ✅ | BankNotificationParser + iOS Shortcuts URL scheme |
| 12 | ✅ | UI integration (Settings sheet, Toast, ManualTransaction) |
| 13 | ✅ | Onboarding 9 ecrane + DS v1.0 (din mockup-uri Penny) |
| 14-15 | ✅ | DemoDataGenerator + LLMOutputValidator |
| 16 | ✅ | SuspiciousTransactionDetector |
| 17 | ✅ | Wire all tabs to CoreData (Today/Wallet/Analysis) |
| 18-23 | ✅ | DS polish + ProfileEdit + GoalEdit + CSALB + merchants x2 |
| 24 | ✅ | GoalsList + SubscriptionAudit + Suspicious + WalletView drilldowns |
| 25 | ✅ | Wire all orphans (TemplateLLM + MomentEngine + UserConsent + GoalProgress + etc.) |
| 26A | ✅ | MLX scaffold (provider + downloader + UI) |
| 26B | ✅ | **Gemma 2B REAL on-device via MLXLLM (shareup/mlx-swift-lm)** |
| 27 | ✅ | DS + UI Apple HIG iOS 26 Liquid Glass (Faza 28 în cod) |
| 28 | ✅ | Faza iOS 26 native DS — semantic colors, full HIG |
| **29** | ✅ | **5 gap-uri funcționale: MomentEngine 8 momente, BGTaskScheduler, UNUserNotificationCenter, Gemma 3 (4B), TodayView fix** |
| 30 | ⏸ | App Icon + Launch Screen + Privacy Manifest |
| 31 | ⏸ | Privacy Policy / TOS / ASF disclaimer (legal) |
| 32 | ⏸ | TestFlight beta (50 useri) |

---

## Ce e SĂRIT explicit din spec (§13.x → revin)

### §13.1 Specificații tehnice de detaliu
- [ ] Schema Core Data complet documentată în MD (avem cod, nu doc separată)
- [x] Pattern Swift pentru MLX (Faza 26B)
- [x] Cod email parsing (Faza 6)
- [x] Cod generation pipeline (MomentEngine)
- [x] Spiral Detector + Pattern Detector

### §13.2 Design și UX
- [x] Design system v1.0 (Penny tokens — culori/typography/spacing/radius)
- [ ] **Wireframes pentru fiecare moment (8 momente)** — Faza 27
- [x] Tone & voice (în system prompts builderi)
- [ ] Iconografie completă curată (folosim SF Symbols default — Faza 27)
- [ ] **States: empty / loading / error pentru fiecare ecran** — Faza 27

### §13.3 Conținut
- [ ] **40 micro-lessons** — content de scris (Faza 30+)
- [x] IFN database (10 records în `IFNDatabase.swift`)
- [x] Scam patterns (10 patterns în `ScamPatterns.swift`)
- [x] Web search whitelist (21 domenii)
- [x] **Subscription cancellation guides (30 servicii)** — Faza 25B

### §13.4 Legal și compliance
- [ ] **Privacy Policy GDPR** — blocant App Store
- [ ] **Terms of Service**
- [ ] **Disclaimer ASF** ("nu e consultanță financiară autorizată")
- [ ] **Consimțământ training opt-in formular** — avem toggle dar fără text legal
- [ ] **DPA Supabase** — Supabase nu e integrat, decizie ulterioară

### §13.5 Plan implementare
✅ La zi conform tracker-ului de mai sus.

### §13.6 Distribuție
- [ ] Landing page solomon.ro
- [ ] 21 grupuri FB strategie
- [ ] TestFlight beta (50 useri)
- [ ] App Store submission
- [ ] Pricing setup
- [ ] Marketing materials (screenshots, video demo)

---

## Riscuri tehnice cunoscute

| Risk | Severitate | Mitigare |
|---|---|---|
| MLX prin fork shareup/mlx-swift-lm 0.0.14 | 🟡 | Upgrade la 0.0.15+ când rezolvă Sendable issues sub Swift 6 |
| Swift 5 mode pe SolomonLLM | 🟡 | Temporar, revine la 6 după upgrade mlx-swift-lm |
| App Icon = Xcode default | 🟠 | Faza 29 |
| Launch Screen = default | 🟠 | Faza 29 |
| `PrivacyInfo.xcprivacy` lipsește | 🔴 | Required iOS 17+ pentru App Store — Faza 29 |
| SolomonWeb orfan în production | 🟡 | Wire-uiesc la CanIAfford / scam check live (Faza 28+) |
| `RecentMoments` în TodayView empty | 🟡 | Persist last N moments (Faza 27+) |
| Calendar EventKit lipsește | 🟢 | Spec opțional v1 |
| Gmail OAuth lipsește | 🟡 | Avem EmailParserSheet manual + Shortcuts strategy |

---

## Module SPM — health check

| Modul | Public API | Tests | Wired în UI | Status |
|---|---|---|---|---|
| SolomonCore | ✅ | 200+ | ✅ | Healthy |
| SolomonStorage | ✅ | 50+ | ✅ | Healthy |
| SolomonAnalytics | ✅ | 60+ | ✅ | Healthy |
| SolomonLLM | ✅ | 27 | ✅ | Healthy (MLX real, Template fallback) |
| SolomonEmail | ✅ | 85+ | ✅ EmailParserSheet | Healthy |
| SolomonWeb | ✅ | 95+ | 🟡 doar testată | Wire la CanIAfford research/scam check live |
| SolomonMoments | ✅ | 60+ | ✅ MomentEngine | Healthy |
| **Total tests** | | **534** | | **534/534 ✅** |

---

## Status iOS Build

- iOS 18 deployment target
- Swift 6.0 tools-version (SolomonLLM target la Swift 5 mode temporar)
- Metal Toolchain instalat
- Dependencies: 7 SPM packages (mlx-swift-lm, swift-huggingface, swift-transformers, mlx-swift, swift-syntax, etc.)
- Last build: ✅ SUCCEEDED (commit `03edd0c`)

---

## Următoarea fază — Faza 27: UI Apple HIG

**Plan:**
1. Cercetare Apple Human Interface Guidelines (web fetch + best practices)
2. Audit UI curent contra HIG
3. Refactor sistematic per ecran
4. Empty/loading/error states peste tot
5. App icon design (S gradient mint→cyan)
6. Launch screen
7. Animation polish
8. Haptic feedback
9. Build verify + commit

**Scope:** TOATE ecranele Solomon (onboarding 9 + 4 tabs + 8 sheets/views) refactor cu Apple HIG patterns native, păstrând Penny DS v1.0 colors.
