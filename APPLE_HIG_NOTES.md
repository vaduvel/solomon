# Apple HIG — Note pentru Solomon UI

Sinteză aplicabilă pentru refactor-ul UI Solomon (Faza 27). Păstrăm Penny DS v1.0 colors (mint #00FF87, cyan #00D4FF, dark #0A0E1A, etc.) — adaptăm restul (typography/spacing/buttons/lists/sheets) la Apple HIG nativ.

---

## 1. Layout & Spacing (8pt grid)

| Item | Value |
|---|---|
| Grid base | **8pt** |
| Standard horizontal margin | **16pt** (small screens) / **20pt** (large) |
| Vertical between elements | **8pt** sau **16pt** |
| Section gap | **24pt** sau **32pt** |
| Tap target minimum | **44 × 44 pt** |
| Safe area top | 44pt status + 50pt nav |
| Safe area bottom | 34pt home indicator |
| Card padding | **16pt** standard / **20pt** comfortable / **24pt** hero |

---

## 2. Typography (SF Pro stack)

| Style | Size | Weight | Use |
|---|---|---|---|
| Large Title | 34 | Bold | Top-level navigation titles (`.navigationBarTitleDisplayMode(.large)`) |
| Title | 28 | Regular/Bold | Screen title (rarely used inline) |
| Title 2 | 22 | Regular | Section title |
| Title 3 | 20 | Regular | Sub-section |
| Headline | 17 | Semibold | Important row labels |
| Body | 17 | Regular | Default body text |
| Callout | 16 | Regular | Slightly emphasized text |
| Subheadline | 15 | Regular | Secondary text |
| Footnote | 13 | Regular | Captions, metadata |
| Caption 1 | 12 | Regular | Labels mici |
| Caption 2 | 11 | Regular | Tiniest labels |

**SwiftUI:**
```swift
Text("Hello").font(.largeTitle)
Text("Hello").font(.title2)
Text("Hello").font(.headline)
Text("Hello").font(.body)
Text("Hello").font(.footnote)
Text("Hello").font(.caption)
```

**Dynamic Type**: toate font styles HIG scalează automat cu setarea Accessibility a userului. Folosim `.font(.body)` nu `.font(.system(size: 17))`.

---

## 3. Buttons

| Style | Use | SwiftUI |
|---|---|---|
| Filled (prominent) | Primary CTA — single per screen | `.buttonStyle(.borderedProminent)` |
| Bordered | Secondary | `.buttonStyle(.bordered)` |
| Plain | Tertiary, ghost | `.buttonStyle(.plain)` (default) |

**Specs:**
- Min height: **44pt** (touch target)
- Corner radius: **12pt** standard / capsule pentru pills
- Spacing intre butoane: **8pt** minimum
- Disabled state: opacity 0.4-0.5

**Custom button — păstrând Penny gradient:**
- `borderedProminent` cu `.tint(Color.solPrimary)` adoptă culoarea iOS native
- Pentru hero CTA (CanIAfford), păstrăm gradient mint→cyan

---

## 4. Lists & Tables

| Style | Use |
|---|---|
| `insetGrouped` | Settings, structured data (rows în card-uri rotunde grupate) |
| `plain` | Feed-uri, time-ordered content |
| `sidebar` | Navigation iPad |

**Pattern Settings nativ (insetGrouped):**
```swift
List {
    Section("Profil") {
        LabeledContent("Nume", value: profile.name)
        LabeledContent("Bancă", value: profile.bank)
    }
    Section("Conectări") {
        Toggle("Notificări", isOn: $enabled)
    }
}
.listStyle(.insetGrouped)
```

**Section header**: footnote weight, `tracking` ușor, color `.secondary`. NU caps mari, NU bold tare.

---

## 5. Sheets

```swift
.sheet(isPresented: $show) {
    DetailView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
}
```

| Detent | Size |
|---|---|
| `.medium` | ~50% screen |
| `.large` | full screen |
| `.fraction(0.7)` | custom |
| `.height(300)` | fixed |

**Drag indicator**: `.visible` pentru toate sheet-urile non-modal. `.hidden` doar pentru modal blocant cu butoane explicite Cancel/Done.

---

## 6. Loading States

| Duration | UX |
|---|---|
| < 1s | Nimic / spinner subtil |
| 1-3s | `ProgressView()` în context |
| 3-10s | Linear progress bar cu percentage |
| 10s+ | Progress + estimated time + cancel option |

**Skeleton loaders** pentru content loading (cards/rows shimmer).

---

## 7. Empty / Error States

**Empty state — pattern:**
```
[Icon mare 64pt]
[Title 22pt Semibold]
[Subtitle 15pt Regular secondary]
[CTA primary]
```
Centered vertical, padding generos.

**Error inline** (sub câmp): footnote red.
**Error toast**: 3-4s, dismissible, ne-blocant.
**Error alert**: doar pentru blocking errors care cer decizie.

---

## 8. Haptics

| Tip | Use |
|---|---|
| `.success` notification | Save complete, action confirmed |
| `.warning` notification | Validation issue |
| `.error` notification | Operation failed |
| `.light` impact | Toggle, picker change |
| `.medium` impact | Button tap, sheet open |
| `.heavy` impact | Confirmation, important action |
| `.selectionChanged` | Picker scroll, segment switch |

**SwiftUI iOS 17+:**
```swift
.sensoryFeedback(.success, trigger: didSave)
.sensoryFeedback(.impact(.medium), trigger: tapCount)
.sensoryFeedback(.selection, trigger: selection)
```

---

## 9. Materials (iOS 15+)

| Material | Vibrancy | Use |
|---|---|---|
| `.regularMaterial` | Default | Sheets, navigation, tab bar |
| `.thinMaterial` | Subtle | Floating overlays |
| `.ultraThinMaterial` | Minimal | Hints, supplementary info |
| `.thickMaterial` | Strong | Focused surfaces |

**Penny glassmorphism hero**: `.ultraThinMaterial` + tint `Color.solCard.opacity(0.5)` + `blur(40)` echivalent.

---

## 10. Color (semantic + Penny tokens)

**Apple semantic** (auto adaptive light/dark):
- `.primary` — text principal
- `.secondary` — text secundar
- `.tertiary` — text de-emphasized

**Penny tokens** (păstrăm):
- `.solCanvas` (#0A0E1A) — background
- `.solCard` (#1C2230) — surface
- `.solPrimary` (#00FF87) — CTA, success
- `.solCyan` (#00D4FF) — accent secondary
- `.solWarning` (#FFB800)
- `.solDestructive` (#FF3B6D)

**Solomon e dark-only** (forced via `.preferredColorScheme(.dark)`), deci semantic Apple light palette nu se aplică direct. Folosim Penny tokens pentru toate culorile.

---

## 11. SF Symbols

- Folosim system icons, nu custom (consistency + accessibility)
- Variable color, hierarchical, palette rendering
- Weight match cu text weight (`.symbolWeight(.medium)`)
- Size scaled (`Image(systemName: "x").font(.body)` → scalează cu text)

**Modificări iOS:**
```swift
Image(systemName: "checkmark.circle.fill")
    .symbolRenderingMode(.hierarchical)
    .foregroundStyle(.tint)
```

---

## 12. Animations

| Curve | Use |
|---|---|
| `.snappy` (iOS 17+) | Quick UI responses (toggle, pick) |
| `.smooth` | Natural transitions (sheet, navigation) |
| `.bouncy` | Playful (success states) |
| `.easeInOut(duration: 0.3)` | Default fallback |
| `.spring(response: 0.4, dampingFraction: 0.8)` | Custom |

**Stagger pentru lists**: 0.05s per item delay.

---

## 13. Onboarding pattern Apple-recomandat

1. Minim ecrane (3-5)
2. Skip option mereu disponibil
3. Permission requests **contextual** — nu pe ecran 1
4. Show value first
5. Progress indication (1 of 9)
6. One task per screen
7. Concise copy

---

## 14. Forma și organizarea screen-urilor

**Standard layout iOS:**
1. Navigation bar (large title sau inline title)
2. Scrollable content (List sau ScrollView)
3. Optional bottom safeAreaInset cu CTA persistent
4. Tab bar (când în main flow)

**Sheet layout:**
1. Drag indicator (sus, vizibil)
2. Title sau navigation
3. Content
4. Bottom action(s)

---

## Aplicare la Solomon

Refactor-ul Faza 27 va:
1. **Înlocui** `solDisplay` cu `.largeTitle` (34pt) — folosit doar pentru hero number
2. **Înlocui** `solH1/H2/H3` custom cu `.title2/title3/.headline` native
3. **Înlocui** `solBody/solCaption` cu `.body/.footnote/.caption` native (păstrăm aliasuri pentru gradual migration)
4. **Refactor** SolomonButton să folosească `.borderedProminent`/`.bordered` cu Penny tint
5. **Convert** SettingsView de la List custom la `.listStyle(.insetGrouped)` real
6. **Aplicare** `.presentationDetents` + `.presentationDragIndicator(.visible)` peste toate sheet-urile
7. **Build** EmptyState/LoadingState/ErrorState reutilizabile
8. **Adăuga** `.sensoryFeedback` la toate butoanele și toggle-urile
9. **Refactor** ProcessingView animație cu `.symbolEffect(.pulse)` (iOS 17+)
10. **Asigura** tap targets ≥ 44pt peste tot

Păstrăm:
- Toate Penny DS colors
- `solGlassCard` (glassmorphism hero pentru Safe-to-Spend)
- `solAIInsightCard` (border accent neon green)
- LinearGradient.solPrimaryCTA (doar pentru hero CTA-uri specifice — nu peste tot)
