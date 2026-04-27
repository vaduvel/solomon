# SOLOMON v1 — MASTER SPECIFICATION

**Versiune:** 1.0 Final
**Data:** 25 aprilie 2026
**Autor:** Daniel (fondator) + sinteza conversațiilor strategice
**Scop:** Document de referință pentru implementare. Tot ce e mai jos e validat empiric sau decis explicit.

---

## 1. CE ESTE SOLOMON

**Definiție într-o frază:**
Solomon este un copilot financiar românesc, 100% local pe iPhone, care folosește AI pentru a-i ajuta pe români să nu rămână fără bani până la salariu, să-și înțeleagă obligațiile, să-și protejeze banii de scurgeri și scheme, și să atingă obiective realiste — fără să le ceară să învețe nimic.

**Numele și brand-ul:**
"Solomon" combină wordplay-ul **SOLO + MONEY** (banii tăi gestionați solo, fără bancă, fără broker) cu referința biblică la regele Solomon, simbolul universal al **înțelepciunii și bogăției**. Numele rezonează cultural pentru români (creștin-ortodox), e brandable internațional, și sugerează exact poziționarea: înțelepciune financiară personală.

**Promisiune emoțională:**
"Solomon știe ce ai, ce vine, ce poți. Și e cu tine zi de zi."

**Tagline principal:**
"Solomon — Înțelepciune pentru banii tăi."

**Tagline secundar (marketing):**
"Solo + Money = Solomon."

**Diferențiere clară vs concurență:**
- vs MiM (Iancu Guda): Solomon e privat, conversațional, învață contextual. MiM e dashboard cu sponsori corporate.
- vs Asoltanie cărți/cursuri: Solomon aplică principiile la viața ta zilnic. Asoltanie te învață teoretic.
- vs Revolut AIR: Solomon e construit pentru România (BNPL, IFN, ANAF context, RON nativ). AIR e generic global.
- vs Banca Transilvania Chat BT: Solomon e advisor independent, nu customer service pentru produse BT.
- vs Excel/Money Manager apps: Solomon analizează automat și avertizează proactiv. Excel cere muncă manuală.

---

## 2. STRATEGIE DE PIAȚĂ

### 2.1 Target primar (faza 1, exclusivist temporar)

**Hardware compatibil:**
- iPhone 15 Pro / 15 Pro Max
- iPhone 16, 16 Plus, 16 Pro, 16 Pro Max
- iPhone 17, 17 Pro, 17 Pro Max
- iPad Pro M-series
- Mac M-series (eventual companion app)

**Demografic primar:**
- 25-45 ani
- Urban (București, Cluj, Timișoara, Iași, Constanța)
- Venit 4.500-15.000 RON net
- Auto-conștient financiar (caută activ soluții)
- Comfortabil cu tehnologie

**Cota de piață estimată:**
- ~1.5 milioane device-uri compatibile în RO
- Target Y1: 5.000-15.000 plătitori activi (0.3-1% conversion)
- Target Y2: 50.000-100.000 plătitori (după lansare Android + hardware democratizat)

### 2.2 De ce strategia "exclusivist temporar"

- Hardware-ul actual nu permite Gemma 4 E4B local pe device-uri sub iPhone 15 Pro
- Acumulare dataset RO finance pentru fine-tuning model propriu în Y2
- Time-to-market 4-5 luni vs 8-10 luni pentru tiered
- Premium pricing (39 RON/lună) sustenabil pentru segmentul ăsta
- Hardware se democratizează natural: iPhone 18 toamnă 2026, iPhone 19 toamnă 2027

### 2.3 Pricing

- **Trial:** 14 zile complet, fără card
- **Plus:** 39 RON/lună (toate features v1)
- **Pro:** 49 RON/lună (v2 — adaugă export, multi-account, prioritate support)
- **Family:** discutat în v2-v3

---

## 3. STACK TEHNIC

### 3.1 Decizii fixate

**Platform v1:**
- iOS 18+ exclusiv
- Swift + SwiftUI
- iPad: funcționează default, nu e optimizat (v2)
- Mac M-series: companion app v2

**LLM:**
- **Primary:** Gemma 4 E4B Q4 (3.6GB) prin MLX Swift
- **Inferență:** 100% on-device, GPU/Neural Engine via Metal
- **Auto-download:** la prima rulare prin WiFi
- **Validat empiric:** răspunde fidel la prompts cu fapte structurate (15/15 fapte corecte în testul Wow Moment, 33 sec generation)

**Web search:**
- **Primary:** DuckDuckGo Instant Answer API (gratuit)
- **Backup:** scraping pe whitelist domains pentru queries financiare specifice
- **Cache agresiv:** 6h pentru curs valutar, 24h pentru dobânzi, 1h pentru scam alerts
- **Volume estimat:** ~5.000 queries/lună la 10k useri (cost neglijabil)

**Storage:**
- **Local (Core Data + Keychain criptat):** toate datele financiare ale user-ului, conversații, model
- **Cloud (Supabase free tier):** doar metadata cont, plan plătit, analytics agregate opt-in
- **Niciodată în cloud:** sume, tranzacții, conversații Solomon

**Email parsing:**
- Gmail OAuth read-only scope
- Filtrare prin sender whitelist (~80 domenii financiare)
- Parsing local Swift (regex + sender mapping)
- Email-ul original NU se stochează

### 3.2 Cost operațional estimat

La 10.000 useri activi:
- Servere: Supabase free tier (~0 EUR)
- LLM inferență: 0 EUR (on-device)
- Web search: ~30 EUR/lună (DDG + ocazional Brave API pentru complex queries)
- Push notifications: 0 EUR (APN gratuit)
- **Total: <50 EUR/lună**

Per user: ~0.005 EUR/lună
Margin la 39 RON: >99%

---

## 4. CE COLECTEAZĂ SOLOMON

### 4.1 Date declarate de user (onboarding)

**Identitate:**
- Nume sau pseudonim
- Pronume (tu/dumneavoastră)
- Vârstă (interval: <25, 25-35, 35-45, 45+)

**Profil financiar:**
- Salariu net (interval: <3k, 3-5k, 5-8k, 8-15k, >15k RON)
- Frecvență salariu (lunar X data / variabil / chenzină)
- Venit secundar (există/nu, tip)
- Bancă principală

**Obligații cunoscute:**
- Chirie (sumă + data)
- Rate active (descriere + sumă + data)
- Abonamente cunoscute
- BNPL active

**Obiectiv:**
- Text liber + chips suggested
- Goal mare opțional (tip + sumă + timeline)

**Consimțăminte:**
- Email access (Gmail OAuth)
- Notificări push
- Dataset training (opt-in clar, default OFF)

### 4.2 Date colectate automat

**Din email:**
- Confirmări tranzacții (Glovo, Wolt, eMAG, etc.)
- Facturi (Enel, Digi, RCS-RDS, etc.)
- Confirmări abonamente (Netflix, Spotify, etc.)
- Notificări bancare (extras BT, BCR, ING)
- Confirmări BNPL (Mokka, TBI, PayPo)
- Notificări IFN (Credius, Provident, IUTE)
- Confirmări travel (Booking, Airbnb)
- Bilete events (Eventim, iaBilet)

**Din calendar (opțional):**
- Evenimente cu cuvinte cheie: nuntă, botez, vacanță

**Generate de analytics local:**
- Categorizare automată cheltuieli
- Pattern temporal
- Detectare recurențe
- Detectare spike-uri
- Detectare BNPL/IFN
- Categorii top per lună

### 4.3 Date pe care Solomon NU le colectează

**Niciodată:**
- CNP, serie buletin, IBAN complet
- Parole, credențiale bancare
- Conținut email personal (doar sender/subject pentru filtrare)
- SMS (nu cere permisiune)
- Locație GPS
- Contacte
- Date despre alți useri

---

## 5. CELE 8 MOMENTE SOLOMON

### 5.1 Lista momentelor

1. **Wow Moment** (onboarding, primul raport) — generat 1 dată
2. **Pot? Query** (oricând user întreabă) — cea mai folosită
3. **Payday Magic** (în ziua salariului) — automat
4. **Pre-Factură Warning** (3-5 zile înainte) — automat
5. **Pattern Alert** (când detectează spike/pattern) — proactiv
6. **Subscription Auditor** (lunar) — automat
7. **Spiral Alert** (rare, important) — critic
8. **Weekly Summary** (duminica seara) — automat

### 5.2 Apărare automată (cross-cutting)

**Trigger-uri active permanent:**
- IFN incoming detection → alertă imediată cu DAE real + alternative
- BNPL stacking (2+ active) → alertă spirală
- Suspicious transactions → soft ping
- Scam detection → web search ASF/ANPC + ferm reply
- CSALB Bridge (severitate critică) → trimitere către csalb.ro

---

## 6. JSON SCHEMAS PENTRU LLM

### 6.1 Convenții generale

**Toate momentele:**
- Sume în RON ca integer
- Date format ISO 8601 (`2026-04-25`)
- String-uri în română lowercase pentru categorii
- LLM primește JSON + prompt template
- LLM returnează doar text, nu JSON

**Categorii standard:**
```
food_grocery       -> Lidl, Kaufland, Carrefour, Mega
food_delivery      -> Glovo, Wolt, Tazz, Bolt Food
food_dining        -> restaurante, cafenele, fast-food
transport          -> benzină, taxi, transport public
utilities          -> Enel, Digi, Apa Nova, gaze
rent_mortgage      -> chirie, rate ipotecă
subscriptions      -> Netflix, Spotify, sală
shopping_online    -> eMAG, Amazon, Sephora
shopping_offline   -> magazine fizice
entertainment      -> bilete, evenimente
health             -> farmacie, medic
loans_ifn          -> Credius, Provident, IFN-uri
loans_bank         -> credite bancare, carduri credit
bnpl               -> Mokka, TBI, PayPo
travel             -> Booking, Airbnb, bilete avion
savings            -> transferuri către cont economii
unknown            -> necategorizate
```

### 6.2 MOMENT 1 — WOW MOMENT

**Trigger:** Onboarding finalizat, după parsing email.

**JSON Schema:**
```json
{
  "moment_type": "wow_moment",
  "user": {
    "name": "Daniel",
    "addressing": "tu",
    "age_range": "25-35"
  },
  "analysis_period_days": 180,
  "income": {
    "monthly_avg": 4500,
    "stability": "stable",
    "lowest_month": {"amount": 4200, "month": "februarie"},
    "extra_income_detected": true,
    "extra_income_avg": 600
  },
  "spending": {
    "monthly_avg": 4218,
    "income_consumption_ratio": 0.94,
    "monthly_balance_trend": "barely_breakeven",
    "card_credit_used": false,
    "overdraft_used_count_180d": 0
  },
  "outliers": [
    {
      "rank": 1,
      "type": "single_large_purchase",
      "category": "shopping_online",
      "merchant": "eMAG",
      "amount": 1850,
      "date": "2026-03-12",
      "context_phrase": "44% din salariul lunar într-o singură zi",
      "context_comparison": "echivalent cu 5 luni de Netflix anual"
    },
    {
      "rank": 2,
      "type": "category_concentration",
      "category": "food_delivery",
      "merchant": "Glovo",
      "amount_total_180d": 7480,
      "amount_monthly_avg": 1247,
      "context_phrase": "media lunară 1.247 RON, 28% din salariu",
      "context_comparison": "echivalent cu o vacanță de 7 zile la munte"
    }
  ],
  "patterns": [
    {
      "type": "temporal_clustering",
      "category": "food_delivery",
      "description": "67% din comenzi vinerea seara între 19:00-22:00",
      "interpretation": "pattern emotional-eating după săptămâna de muncă"
    },
    {
      "type": "weekend_spike",
      "average_weekend_spend": 480,
      "average_weekday_spend": 210,
      "ratio": 2.3,
      "description": "weekendurile sunt 2.3x mai scumpe ca zilele lucrătoare"
    }
  ],
  "obligations": {
    "monthly_total_fixed": 2235,
    "items": [
      {"name": "Chirie", "amount": 1500, "day_of_month": 1},
      {"name": "Internet Digi", "amount": 65, "day_of_month": 15},
      {"name": "Curent Enel", "amount": 220, "day_of_month": 28},
      {"name": "Netflix", "amount": 40, "day_of_month": 5},
      {"name": "Spotify", "amount": 25, "day_of_month": 12},
      {"name": "Sală fitness", "amount": 150, "day_of_month": 1},
      {"name": "HBO Max", "amount": 35, "day_of_month": 18},
      {"name": "App Calm", "amount": 29, "day_of_month": 3},
      {"name": "Asigurare CASCO", "amount": 171, "day_of_month": 20}
    ],
    "obligations_to_income_ratio": 0.50
  },
  "ghost_subscriptions": {
    "count": 3,
    "monthly_total": 104,
    "annual_total": 1248,
    "items": [
      {"name": "Netflix", "amount": 40, "last_used_days_ago": 47, "confidence": "high"},
      {"name": "App Calm", "amount": 29, "last_used_days_ago": 178, "confidence": "very_high"},
      {"name": "HBO Max", "amount": 35, "last_used_days_ago": 92, "confidence": "high"}
    ]
  },
  "positives": [
    {
      "type": "no_ifn",
      "description": "fără IFN-uri sau credite cu dobândă mare",
      "rarity_context": "doar 1 din 4 români poate spune asta"
    },
    {
      "type": "no_late_payments",
      "duration_months": 6,
      "description": "plătești facturile la timp, fără penalități"
    },
    {
      "type": "rent_to_income_healthy",
      "ratio": 0.33,
      "description": "chiria e 33% din venit, ratio sănătos"
    }
  ],
  "goal": {
    "declared": true,
    "type": "vacation",
    "destination": "Grecia",
    "amount_target": 4500,
    "amount_saved": 800,
    "deadline": "2026-07-15",
    "months_remaining": 3,
    "monthly_required": 1233,
    "feasibility": "challenging_but_possible",
    "current_pace_will_reach": false,
    "shortfall_per_month": 433
  },
  "spiral_risk": {
    "score": 0,
    "severity": "none",
    "factors": []
  },
  "next_action_suggested": {
    "type": "cancel_ghost_subscriptions",
    "rationale": "instant_savings_no_lifestyle_impact",
    "monthly_saving": 104,
    "annual_saving": 1248,
    "vacation_progress_impact": "8% din vacanța Grecia"
  }
}
```

**Prompt Template:**
```
Ești Solomon, asistent financiar român cu ton cald și direct.
Daniel tocmai a terminat onboarding-ul și aștepta primul raport.

REGULI ABSOLUTE:
- Folosește DOAR cifrele și faptele din JSON-ul de mai jos
- NU inventa observații noi, categorii, sau fapte
- Diacritice corecte obligatoriu (ă, â, î, ș, ț)
- Fără cuvinte în engleză
- Maxim 280 cuvinte total
- Ton: prieten care îți pasă, nu profesor

STRUCTURĂ FIXĂ (7 secțiuni cu titluri exacte):

**SALUT** (1 propoziție caldă)

**ÎNGRIJORĂTOR** (folosește outliers[0])
2-3 propoziții despre cea mai mare cheltuială neașteptată.
Folosește exact context_phrase și context_comparison din JSON.

**PATTERN** (folosește patterns)
2-3 propoziții despre pattern-ul cel mai relevant.
Menționează cifrele exact (procent, RON, zile).

**POZITIV** (folosește positives)
2 propoziții. Combină 2 lucruri pozitive cu rarity_context.

**APĂRARE** (folosește ghost_subscriptions)
2-3 propoziții. Cifre exacte: count, monthly_total, annual_total.
Listează numele celor 3 abonamente.

**OBIECTIV** (folosește goal)
3 propoziții. Cifre exacte: amount_saved, monthly_required, months_remaining, shortfall_per_month.

**CONCLUZIE** (1 propoziție motivațională, fără clișee)

JSON cu fapte:
[INSERT JSON HERE]

Răspuns:
```

### 6.3 MOMENT 2 — POT? QUERY

**Trigger:** User întreabă explicit prin input bar.

**JSON Schema:**
```json
{
  "moment_type": "can_i_afford",
  "user": {
    "name": "Marian",
    "addressing": "tu"
  },
  "query": {
    "raw_text": "pot să iau pizza de 80 lei diseară?",
    "amount_requested": 80,
    "category_inferred": "food_dining",
    "merchant_inferred": null,
    "is_recurring": false
  },
  "context": {
    "today": "2026-04-25",
    "days_until_payday": 9,
    "current_balance": 2160,
    "obligations_remaining_this_period": [
      {"name": "Chirie", "amount": 1500, "due_date": "2026-05-01"},
      {"name": "Curent Enel", "amount": 280, "due_date": "2026-04-28"}
    ],
    "obligations_total_remaining": 1780,
    "available_after_obligations": 380,
    "available_per_day_after": 42,
    "available_per_day_after_purchase": 33
  },
  "decision": {
    "verdict": "yes_with_caution",
    "verdict_reason": "tight_but_workable",
    "math_visible": "după pizza, ai 33 RON/zi pentru 9 zile",
    "alternative_to_suggest": "wait_2_days_until_after_enel"
  },
  "user_history_context": {
    "this_category_this_month": 340,
    "this_category_avg_monthly": 425,
    "is_above_average_today": false
  }
}
```

**Prompt Template:**
```
Ești Solomon, asistent financiar român.

Marian întreabă dacă poate cheltui ceva. Răspunde-i scurt și direct.

REGULI ABSOLUTE:
- Maxim 3 propoziții
- Folosește DOAR cifrele din JSON
- Începe cu "DA" sau "NU" sau "DA, dar"
- Diacritice corecte
- Fără engleză
- Ton: prietenos, factual, fără moralizare

STRUCTURĂ:
Propoziție 1: Verdict (DA/NU) + cifra principală relevantă
Propoziție 2: Context cu math_visible din JSON
Propoziție 3 (opțional): O sugestie scurtă dacă există alternative_to_suggest

JSON:
[INSERT JSON HERE]

Răspuns:
```

### 6.4 MOMENT 3 — PAYDAY MAGIC

**Trigger:** Detectare incoming salary în extras.

**JSON Schema:**
```json
{
  "moment_type": "payday",
  "user": {
    "name": "Daniel",
    "addressing": "tu"
  },
  "salary": {
    "amount_received": 4500,
    "received_date": "2026-04-15",
    "source": "Salariu",
    "is_higher_than_average": false,
    "is_lower_than_average": false
  },
  "auto_allocation": {
    "obligations_reserved": [
      {"name": "Chirie", "amount": 1500, "status": "rezervat"},
      {"name": "Curent Enel (estimat)", "amount": 280, "status": "estimat"},
      {"name": "Internet Digi", "amount": 65, "status": "rezervat"},
      {"name": "Sală fitness", "amount": 150, "status": "rezervat"},
      {"name": "Asigurare CASCO", "amount": 171, "status": "rezervat"}
    ],
    "subscriptions_reserved": [
      {"name": "Netflix", "amount": 40},
      {"name": "Spotify", "amount": 25},
      {"name": "HBO Max", "amount": 35},
      {"name": "App Calm", "amount": 29}
    ],
    "obligations_total": 2295,
    "subscriptions_total": 129,
    "savings_auto": {
      "enabled": true,
      "amount": 450,
      "destination": "Fond Grecia"
    },
    "available_to_spend": 1626,
    "days_until_next_payday": 30,
    "available_per_day": 54
  },
  "comparisons": {
    "vs_last_month_available": 1480,
    "vs_last_month_diff": 146,
    "vs_last_month_direction": "better"
  },
  "category_budgets_suggested": [
    {"category": "food_grocery", "amount": 600, "based_on": "average"},
    {"category": "food_delivery", "amount": 400, "based_on": "reduced_target"},
    {"category": "transport", "amount": 250, "based_on": "average"},
    {"category": "entertainment", "amount": 200, "based_on": "average"},
    {"category": "buffer", "amount": 176, "based_on": "10_percent"}
  ],
  "warnings": [
    {
      "type": "upcoming_event",
      "description": "Nuntă pe 8 mai, ai notat ~700 RON",
      "impact": "scoate 700 RON din disponibilul de 1.626"
    }
  ]
}
```

**Prompt Template:**
```
Ești Solomon. Salariul tocmai a intrat pentru Daniel.
Prezintă-i situația scurt și clar.

REGULI:
- Maxim 5 propoziții
- Cifre exacte din JSON
- Ton: optimist dar realist
- Diacritice corecte, fără engleză

STRUCTURĂ:
1. Confirmare salariu primit (suma)
2. Total rezervat pentru obligații + savings (cifră totală)
3. Disponibil liber + per zi
4. Comparație cu luna trecută (dacă e relevant)
5. Warning dacă există în JSON

JSON:
[INSERT JSON HERE]

Răspuns:
```

### 6.5 MOMENT 4 — PRE-FACTURĂ WARNING

**Trigger:** 3-5 zile înainte de obligație recurentă detectată.

**JSON Schema:**
```json
{
  "moment_type": "upcoming_obligation",
  "user": {
    "name": "Marian",
    "addressing": "tu"
  },
  "upcoming": {
    "name": "Curent Enel",
    "amount_estimated": 280,
    "due_date": "2026-04-28",
    "days_until_due": 3,
    "amount_estimation_confidence": "high",
    "based_on_history": "media ultimelor 3 luni"
  },
  "context": {
    "current_balance": 720,
    "after_payment": 440,
    "days_until_next_payday": 6,
    "available_per_day_after": 73
  },
  "assessment": {
    "is_affordable": true,
    "is_tight": false,
    "tone": "reassuring"
  },
  "weekend_warning": {
    "is_weekend_coming": true,
    "weekend_avg_spend": 340,
    "would_create_problem": false
  }
}
```

**Prompt Template:**
```
Ești Solomon. Vine o factură peste câteva zile pentru Marian.
Anunță-l calm, nu alarmist.

REGULI:
- Maxim 3 propoziții
- Cifre exacte
- Ton: informativ, calm
- Fără "ATENȚIE" sau alarme exagerate

STRUCTURĂ:
1. Ce vine, cât, când
2. După plată îți rămân X pentru Y zile
3. Atenționare scurtă despre weekend dacă e cazul

JSON:
[INSERT JSON HERE]

Răspuns:
```

### 6.6 MOMENT 5 — PATTERN ALERT

**Trigger:** Swift detectează spike sau pattern recurent.

**JSON Schema:**
```json
{
  "moment_type": "pattern_alert",
  "user": {
    "name": "Daniel",
    "addressing": "tu"
  },
  "pattern_detected": {
    "category": "food_delivery",
    "merchant_dominant": "Glovo",
    "type": "frequency_spike",
    "description": "4 comenzi în 7 zile",
    "amount_period": 287,
    "amount_projected_monthly": 1230,
    "vs_budget": 920,
    "vs_budget_pct": 134,
    "temporal_concentration": {
      "is_temporal": true,
      "pattern": "miercuri-vineri seara",
      "interpretation": "post-work emotional eating"
    }
  },
  "scenarios": [
    {
      "scenario_id": "continue",
      "description": "continui ritmul actual",
      "month_end_outcome": "depășire 310 RON peste buget",
      "goal_impact": "vacanța întârzie cu o săptămână"
    },
    {
      "scenario_id": "reduce_2_per_week",
      "description": "rămâi la 2 comenzi/săptămână",
      "month_end_outcome": "respecți bugetul",
      "goal_impact": "vacanța rămâne pe drum"
    },
    {
      "scenario_id": "skip_one_week",
      "description": "skip complet săptămâna asta",
      "month_end_outcome": "economisești 380 RON",
      "goal_impact": "+1 zi vacanță în plus"
    }
  ],
  "tone_calibration": "warm_no_judgment"
}
```

**Prompt Template:**
```
Ești Solomon. Ai observat un pattern la Daniel. Spune-i fără să-l moralizezi.

REGULI:
- Maxim 5 propoziții
- Ton cald, factual
- Prezintă 2-3 scenarii cu cifre exacte
- "Tu alegi" la final, nu impune
- Fără "ar trebui", "trebuie"

STRUCTURĂ:
1. Constatare observabilă (cifre)
2. Proiecție lunară dacă continui
3. Scenariu A cu cifre
4. Scenariu B cu cifre
5. "Tu alegi" cald

JSON:
[INSERT JSON HERE]

Răspuns:
```

### 6.7 MOMENT 6 — SUBSCRIPTION AUDITOR

**Trigger:** Lunar, în jurul zilei 25.

**JSON Schema:**
```json
{
  "moment_type": "subscription_audit",
  "user": {
    "name": "Marian",
    "addressing": "tu"
  },
  "audit_period_days": 30,
  "ghost_subscriptions": [
    {
      "name": "Netflix",
      "amount_monthly": 40,
      "amount_annual": 480,
      "last_used_days_ago": 47,
      "cancellation_difficulty": "easy",
      "cancellation_url": "netflix.com/cancelplan",
      "alternative_suggestion": "HBO Max sau Prime Video"
    },
    {
      "name": "Calm",
      "amount_monthly": 29,
      "amount_annual": 348,
      "last_used_days_ago": 178,
      "cancellation_difficulty": "medium",
      "cancellation_url": null,
      "cancellation_steps_summary": "din App Store, Subscriptions"
    },
    {
      "name": "Adobe Creative Cloud",
      "amount_monthly": 250,
      "amount_annual": 3000,
      "last_used_days_ago": 89,
      "cancellation_difficulty": "hard",
      "cancellation_warning": "are penalty pentru anulare anticipată"
    }
  ],
  "totals": {
    "monthly_recoverable": 319,
    "annual_recoverable": 3828,
    "context_comparison": "echivalent cu vacanța Grecia + buffer"
  },
  "active_subscriptions_kept": {
    "count": 4,
    "monthly_total": 285,
    "examples": ["Spotify", "HBO Max", "Sală", "Asigurare casco"]
  }
}
```

**Prompt Template:**
```
Ești Solomon. Ai găsit abonamente nefolosite pentru Marian.
Spune-i clar, fără presiune.

REGULI:
- Maxim 6 propoziții
- Numele exacte din JSON
- Cifre exacte
- Pentru fiecare ghost: nume + cost lunar + când a folosit ultima dată
- Final: total recuperabil + comparație concretă

STRUCTURĂ:
1. Introducere scurtă (am găsit X abonamente)
2-4. Per ghost: nume, cost, ultima utilizare
5. Total recuperabil cu comparație
6. CTA opțional: vrei să vedem cum le anulezi?

JSON:
[INSERT JSON HERE]

Răspuns:
```

### 6.8 MOMENT 7 — SPIRAL ALERT

**Trigger:** Spiral Detection score 2+. Critic la score 3.

**JSON Schema:**
```json
{
  "moment_type": "spiral_alert",
  "user": {
    "name": "Daniel",
    "addressing": "tu"
  },
  "spiral_score": 3,
  "severity": "critical",
  "factors_detected": [
    {
      "factor": "balance_declining",
      "evidence": "balance final de lună a scăzut 4 luni la rând",
      "values": [820, 540, 230, -120]
    },
    {
      "factor": "card_credit_increasing",
      "evidence": "datorie pe card credit a crescut de la 0 la 1.840 RON",
      "monthly_increase_avg": 460
    },
    {
      "factor": "ifn_active",
      "evidence": "Credius incoming detected pe 18 aprilie",
      "amount": 2500,
      "estimated_total_repayment": 3250
    },
    {
      "factor": "obligations_exceed_income",
      "evidence": "obligații + cheltuieli medii > venit cu 380 RON/lună",
      "monthly_gap": 380
    }
  ],
  "narrative_summary": "spiral activ, IFN nou, obligații peste venit",
  "intervention_needed": true,
  "csalb_relevant": true,
  "recovery_plan": {
    "step_1": {
      "action": "anulare ghost subscriptions",
      "monthly_saving": 104,
      "complexity": "easy"
    },
    "step_2": {
      "action": "negociere refinanțare credit + IFN",
      "potential_saving": "200-400 RON/lună",
      "complexity": "medium",
      "tool": "CSALB"
    },
    "step_3": {
      "action": "reducere food_delivery cu 50%",
      "monthly_saving": 600,
      "complexity": "behavioral"
    }
  }
}
```

**Prompt Template:**
```
Ești Solomon. Ai detectat o situație serioasă pentru Daniel.
Vorbește-i direct, cu respect, fără panică.

REGULI:
- Maxim 8 propoziții
- Numește situația cu cifre, nu eufemisme
- Oferă PLAN concret, nu doar diagnostic
- Menționează CSALB ca opțiune reală
- Ton: prieten serios, nu doctor de urgență

STRUCTURĂ:
1. Deschide direct: "Vreau să vorbim 2 minute"
2-3. Ce vezi (cifre concrete din factors_detected)
4. De ce contează (impact pe viitor)
5. Pasul 1 din recovery_plan (cel mai ușor, instant win)
6. Pasul 2: CSALB (cum funcționează, gratuit, ajutor real)
7. Pasul 3 din recovery_plan
8. Închidere: "Asta e fixabil. Mergem împreună."

JSON:
[INSERT JSON HERE]

Răspuns:
```

### 6.9 MOMENT 8 — WEEKLY SUMMARY

**Trigger:** Duminica seara, 20:00.

**JSON Schema:**
```json
{
  "moment_type": "weekly_summary",
  "user": {
    "name": "Daniel",
    "addressing": "tu"
  },
  "week": {
    "start": "2026-04-19",
    "end": "2026-04-25",
    "week_number": 17
  },
  "spending": {
    "total": 612,
    "vs_weekly_avg": 580,
    "diff_pct": 5,
    "direction": "slightly_above"
  },
  "highlights": [
    {
      "type": "biggest_expense",
      "category": "food_delivery",
      "amount": 187,
      "context": "3 comenzi Glovo, mai mult ca media"
    },
    {
      "type": "budget_kept",
      "category": "transport",
      "amount": 67,
      "context": "sub buget cu 30 RON"
    },
    {
      "type": "no_ifn_no_bnpl_temptation",
      "context": "săptămână curată, fără datorii noi"
    }
  ],
  "next_week_preview": {
    "obligations_due": [
      {"name": "Curent Enel", "amount": 280, "day": "marți"}
    ],
    "events_in_calendar": [
      {"name": "Nuntă Andrei", "estimated_cost": 700, "date": "sâmbătă"}
    ]
  },
  "small_win": {
    "exists": true,
    "description": "ai redus delivery de la 4 la 3 comenzi/săpt"
  }
}
```

**Prompt Template:**
```
Ești Solomon. Duminică seara, sumar săptămânal pentru Daniel.

REGULI:
- Maxim 4 propoziții
- Cifre exacte
- Ton conversațional, casual
- Fără structură rigidă cu titluri

STRUCTURĂ:
1. Cum a fost săptămâna (cheltuit total, comparație)
2. 1-2 highlights din JSON
3. Ce vine săptămâna următoare
4. Small win dacă există

JSON:
[INSERT JSON HERE]

Răspuns:
```

---

## 7. ANALYTICS ENGINE (SWIFT)

### 7.1 Principiu fundamental

**Codul Swift face TOATĂ matematica și analiza. LLM-ul doar îmbracă rezultate în text natural.**

Validat empiric: Gemma 4 E4B la testare:
- Math multi-step → eșuează
- Pattern recognition complex → eșuează  
- Inventează observații → DA, dacă i se permite
- Text generation peste fapte structurate → 95%+ fidelitate

### 7.2 Module analytics necesare

**Modul 1: CashFlowAnalyzer**
```swift
Input: tranzacții (90+ zile), obligații, venit
Output: 
- monthlyIncome (avg, lowest, highest)
- monthlySpending (avg, by category)
- balanceTrend (positive/negative pe 30/60/90 zile)
- velocityRON (RON/zi cheltuiți)
- breakEvenStatus (above/below/exactly)
```

**Modul 2: ObligationMapper**
```swift
Input: tranzacții recurente, input manual, email parsing
Output:
- monthlyObligations (toate fixed costs)
- obligationsCalendar (când vine fiecare în lună)
- detectedSilent (obligații găsite dar nedeclarate)
- obligationsToIncomeRatio
```

**Modul 3: SafeToSpendCalculator**
```swift
Input: balance, obligations remaining, days to payday
Output:
- availableAfterObligations (RON)
- availablePerDay (RON/zi)
- bufferRecommended (10% safety)
- daysUntilCritical (când ajungi la 0)
```

**Modul 4: PatternDetector**
```swift
Input: tranzacții 90 zile
Output:
- topCategories (top 5)
- temporalPatterns (zile/ore concentrare)
- outliers (cheltuieli anormale)
- recurringPatterns (Glovo vinerea, etc.)
- spikeDays (concentrări dense)
```

**Modul 5: SpiralDetector** (CRITIC)
```swift
Input: 60 zile tranzacții + obligații
Output:
- balanceDeclining (boolean + values array)
- creditCardUsageIncreasing (boolean + amounts)
- bnplStacking (count active)
- ifnIncoming (detection in last 30d)
- spiralScore (0-3)
- factorsDetected (array)
```

**Modul 6: GoalProgress**
```swift
Input: declared goals, savings detected
Output:
- progressPercentage
- estimatedTimeAtCurrentRate
- whatIfScenarios (3 alternative paths)
- shortfallIfAny (RON)
```

**Modul 7: SubscriptionAuditor**
```swift
Input: subscriptions detected, email open rates / app launches
Output:
- ghostSubscriptions (>30 zile fără utilizare)
- monthlyRecoverable (RON)
- annualRecoverable (RON)
- cancellationGuides (per service)
```

### 7.3 Validare output LLM

**După ce LLM răspunde, codul Swift verifică:**

```swift
// Pseudocod validare
func validateLLMOutput(_ output: String, expectedJSON: SolomonContext) -> ValidationResult {
    var errors: [String] = []
    
    // 1. Verifică cifre cheie
    let criticalNumbers = expectedJSON.extractCriticalNumbers()
    for number in criticalNumbers {
        if !output.contains(formatRON(number)) {
            errors.append("Missing critical number: \(number)")
        }
    }
    
    // 2. Detectare cuvinte engleză
    let englishWords = ["budget", "savings", "expense", "income", "monthly"]
    for word in englishWords {
        if output.lowercased().contains(word) {
            errors.append("English word found: \(word)")
        }
    }
    
    // 3. Verificare lungime
    let wordCount = output.split(separator: " ").count
    if wordCount > expectedJSON.maxWords {
        errors.append("Output too long: \(wordCount) > \(expectedJSON.maxWords)")
    }
    
    // 4. Diacritice prezent
    let romanianDiacritics: Set<Character> = ["ă", "â", "î", "ș", "ț", "Ă", "Â", "Î", "Ș", "Ț"]
    let hasNoDiacritics = !output.contains(where: { romanianDiacritics.contains($0) })
    if hasNoDiacritics && wordCount > 30 {
        errors.append("No diacritics in long output")
    }
    
    return ValidationResult(passed: errors.isEmpty, errors: errors)
}
```

**Strategie retry:**
- Dacă validation eșuează: max 2 retry cu prompt mai strict
- După 3 încercări: fallback la template static cu cifrele din JSON

---

## 8. EMAIL PARSING — LISTA DE SENDERS

### 8.1 Bănci RO

```
notificare@bt.ro              -> Banca Transilvania (NeoBT)
no-reply@bcr.ro               -> BCR (George)
notificari@ing.ro             -> ING Bank
e-banking@raiffeisen.ro       -> Raiffeisen Smart Mobile
no-reply@revolut.com          -> Revolut
no-reply@cec.ro               -> CEC Bank
e-banking@unicredit.ro        -> UniCredit Bank
notify@patriabank.ro          -> Patria Bank
e-banking@procreditbank.ro    -> ProCredit
notify@libra.ro               -> Libra Internet Bank
no-reply@garantibbva.ro       -> Garanti BBVA
e-banking@firstbank.ro        -> First Bank
no-reply@alphabank.ro         -> Alpha Bank
e-banking@otpbank.ro          -> OTP Bank
no-reply@idea-bank.ro         -> Idea Bank
```

### 8.2 Food delivery

```
no-reply@glovoapp.com         -> Glovo
help@wolt.com                 -> Wolt
no-reply@tazz.ro              -> Tazz
no-reply@boltfood.com         -> Bolt Food
no-reply@foodpanda.com        -> Foodpanda
```

### 8.3 Streaming și abonamente digitale

```
info@account.netflix.com      -> Netflix
no-reply@email.hbomax.com     -> HBO Max
no-reply@spotify.com          -> Spotify
no-reply@apple.com            -> Apple Services (Apple Music, iCloud, App Store)
no-reply@youtube.com          -> YouTube Premium
billing@disneyplus.com        -> Disney+
no-reply@github.com           -> GitHub
mail@adobe.com                -> Adobe Creative Cloud
no-reply@dropbox.com          -> Dropbox
billing@1password.com         -> 1Password
no-reply@figma.com            -> Figma
no-reply@notion.so            -> Notion
no-reply@calm.com             -> Calm
no-reply@headspace.com        -> Headspace
no-reply@duolingo.com         -> Duolingo
```

### 8.4 Utilități RO

```
contact@enel.ro               -> Enel
office@digi.ro                -> Digi
clientservice@rcs-rds.ro      -> RCS-RDS
help@orange.ro                -> Orange
contact@vodafone.ro           -> Vodafone
servicii@telekom.ro           -> Telekom
clienti@engie.ro              -> Engie
contact@e-on.ro               -> E.ON
clienti@apanovabucuresti.ro   -> Apa Nova București
clienti@distributiegazenaturale.ro -> Distrigaz
```

### 8.5 Shopping online

```
no-reply@emag.ro              -> eMAG
no-reply@altex.ro             -> Altex
no-reply@flanco.ro            -> Flanco
no-reply@elefant.ro           -> Elefant
no-reply@bookuriste.ro        -> Bookurile
no-reply@sephora.ro           -> Sephora
no-reply@douglas.ro           -> Douglas
no-reply@h-and-m.com          -> H&M
no-reply@zalando.com          -> Zalando
no-reply@aboutyou.ro          -> About You
no-reply@fashiondays.ro       -> Fashion Days
no-reply@decathlon.ro         -> Decathlon
no-reply@dedeman.ro           -> Dedeman
no-reply@ikea.ro              -> IKEA
no-reply@auchan.ro            -> Auchan online
no-reply@kaufland.ro          -> Kaufland online
no-reply@carrefour.ro         -> Carrefour online
```

### 8.6 BNPL și IFN (CRITIC pentru apărare)

```
hello@mokka.ro                -> Mokka
no-reply@tbi.ro               -> TBI Bank
support@paypo.ro              -> PayPo
support@klarna.com            -> Klarna
hello@felice.ro               -> Felice
no-reply@credius.ro           -> Credius
office@providentromania.ro    -> Provident
no-reply@iutecredit.ro        -> IUTE Credit
contact@vivacredit.ro         -> Viva Credit
contact@horacredit.ro         -> Hora Credit
suport@maimaicredit.ro        -> MaiMai Credit
contact@acredit.ro            -> Acredit
support@ferratum.ro           -> Ferratum
support@cetelem.ro            -> Cetelem
```

### 8.7 Travel

```
no-reply@booking.com          -> Booking.com
automated@airbnb.com          -> Airbnb
no-reply@esky.ro              -> eSky
no-reply@vola.ro              -> Vola.ro
flightcenter@kiwi.com         -> Kiwi.com
no-reply@tarom.ro             -> TAROM
booking@blueair.aero          -> Blue Air
no-reply@wizzair.com          -> Wizz Air
no-reply@ryanair.com          -> Ryanair
contact@christiantour.ro      -> Christian Tour
contact@paraleladu.ro         -> Paralela 45
```

### 8.8 Entertainment

```
no-reply@eventim.ro           -> Eventim
contact@iabilet.ro            -> iaBilet
hello@bilet.ro                -> Bilet.ro
support@untold.com            -> UNTOLD
hello@electriccastle.ro       -> Electric Castle
```

### 8.9 Transport

```
no-reply@bolt.eu              -> Bolt (taxi)
no-reply@uber.com             -> Uber
no-reply@yango.com            -> Yango
contact@stb.ro                -> STB (București)
no-reply@cfr-calatori.ro      -> CFR Călători
contact@blablacar.com         -> BlaBlaCar
hello@taxify.eu               -> Taxify
```

### 8.10 Asigurări

```
contact@allianz.ro            -> Allianz
contact@asirom.ro             -> Asirom
clienti@groupama.ro           -> Groupama
contact@nn.ro                 -> NN Asigurări
clienti@omniasig.ro           -> Omniasig
contact@uniqa.ro              -> Uniqa
```

### 8.11 Reguli filtrare

**Codul Swift filtrează emailurile prin:**
1. Sender domain match (whitelist de mai sus)
2. Subject keywords (în RO și EN): "factura", "plată", "comandă", "tranzacție", "abonament", "extras", "rambursare"
3. Body conține pattern de sumă (regex `[\d.,]+\s?(RON|lei|EUR|€)`)

**Confidence scoring:**
- Sender match exact: high confidence
- Sender match prin domeniu părinte: medium
- Doar keywords match: low (necesită confirmare manuală user)

---

## 9. WEB SEARCH — WHITELIST DOMENII

### 9.1 Surse oficiale (high trust)

```
bnr.ro                  -> curs valutar, dobânzi referință
anaf.gov.ro             -> impozite, deduceri, e-factura
asf.ro                  -> avertismente investiții, autorizări
anpc.ro                 -> scam alerts, drepturi consumator
ms.ro                   -> deduceri sănătate
ec.europa.eu/eures      -> info muncă în UE
csalb.ro                -> mediere bancară
```

### 9.2 Comparații financiare

```
conso.ro                -> depozite, credite, carduri
finzoom.ro              -> comparator credite
creditede.ro            -> calculator credit
cumparcasa.ro           -> calculator imobiliar
ratemyrate.ro           -> rate la depozite
```

### 9.3 Știri financiare RO

```
zf.ro                   -> Ziarul Financiar
profit.ro               -> Profit.ro
economica.net           -> Economica.net
bursa.ro                -> Bursa
hotnews.ro/economie     -> HotNews secțiune economie
```

### 9.4 Educație financiară

```
iancuguda.ro            -> Iancu Guda
moneymag.ro             -> Money.ro
finantepersonale.ro     -> Finanțe Personale
educatiefinanciara.ro   -> Educație Financiară
```

### 9.5 Reguli scraping

- Întâi DuckDuckGo Instant Answer pentru queries simple (curs, dobânda azi)
- Pentru queries complexe: scraping doar pe domeniile whitelist
- Cache rezultate: 6h curs valutar, 24h dobânzi, 1h scam alerts, 7 zile știri
- Niciodată scraping pe domenii outside whitelist
- User agent identificat clar ca Solomon app (nu mascam)

---

## 10. APĂRARE — TRIGGERS ȘI ACȚIUNI

### 10.1 IFN Incoming Detection

**Trigger:** Detect deposit cu sender match IFN whitelist (vezi 8.6).

**Acțiune imediată:**
1. Push notificare: "Văd transferul de la [IFN]. Vrei să vorbim despre cost real?"
2. La deschidere app:
   - Calcul DAE real al IFN-ului (din baza de date IFN)
   - Cost total estimat la rambursare
   - Comparație cu overdraft bancar (DAE ~20%)
   - Comparație cu credit nevoi personale (DAE ~14%)
   - Întrebare pentru user: "Pentru ce ai nevoie de banii ăștia?"

**Database IFN cu DAE typical:**
```
Credius           -> DAE 280-2334%
Provident         -> DAE 100-650%
IUTE Credit       -> DAE 250-1800%
Viva Credit       -> DAE 200-1500%
Hora Credit       -> DAE 150-1200%
MaiMai Credit     -> DAE 200-2490%
Acredit           -> DAE 280-2334%
Ferratum          -> DAE 200-1500%
```

### 10.2 BNPL Stacking Alert

**Trigger:** 2+ BNPL active simultan (din whitelist 8.6).

**Acțiune:**
- Notificare: "Ai 3 BNPL active: Mokka 240, TBI 180, PayPo 95. Total 515 RON/lună. Ai grijă, e ușor să pierzi controlul."
- Listă BNPL active cu sume și termene
- Avertizare risc snowball
- Sugestie: consolidare prin credit bancar dacă sumele sunt mari

### 10.3 Suspicious Transactions

**Trigger:** 
- Tranzacție > 5x media zilnică
- 5+ tranzacții în <1h
- Tranzacție la merchant nou de noapte (00:00-05:00)

**Acțiune:**
- Soft ping: "Văd ceva neobișnuit. Tu ești?"
- Dacă user confirmă: salvează ca pattern recunoscut
- Dacă user neagă: alertează despre fraudă potențială + sugestie blocare card

### 10.4 Scam Detection

**Trigger:** User întreabă în chat despre o ofertă, link, sau mesaj suspect.

**Acțiune:**
1. Web search pe asf.ro și anpc.ro pentru avertismente recente
2. Pattern matching cu lista cunoscută de scam patterns:
   - Promisiuni randament >2%/lună
   - "Investește 500€, primești 5000€ în 30 zile"
   - Crypto cu garanții
   - Forex cu nume nereaușite în RO
3. Răspuns ferm cu evidențe: "ASF a emis 3 avertismente în martie 2026 despre platforme similare"

### 10.5 CSALB Bridge (severitate critică)

**Trigger:** Spiral score 3 + IFN multiple + obligații > venit.

**Acțiune:**
- Solomon explică ce e CSALB:
  - Centrul de Soluționare Alternativă a Litigiilor Bancare
  - Gratuit pentru consumatori
  - Mediere oficială cu băncile/IFN-urile
  - Poate negocia refinanțări legal
- Link direct: csalb.ro
- "Nu e aplicabil să faci asta singur. CSALB e ajutor real, gratuit, oficial."
- Tracking: ai contactat CSALB? (boolean opțional)

---

## 11. ONBOARDING FLOW EXACT

### Ecran 1 — Welcome (15 sec)

**Conținut:**
- Logo Solomon
- Tagline: "Înțelepciune pentru banii tăi"
- 3 chips: "🧠 Învăț din comportamentul tău" / "🎯 Îți arăt ce să faci" / "💙 Fără judecăți"
- Subtitle: "100% pe telefonul tău. Datele nu pleacă nicăieri."
- CTA: [Hai să ne cunoaștem →]
- Mic text: "Durează 3 minute"

### Ecran 2 — Identitate (30 sec)

- Input: "Cum te cheamă?"
- Toggle: "Cum vrei să-ți zic? [Pe nume / Formal]"
- CTA: [Continuă →]

### Ecran 3 — Venit (30 sec)

- Întrebare: "Cât câștigi lunar, aproximativ?"
- Chips: <3.000 / 3-5.000 / 5-8.000 / 8-15.000 / >15.000 RON
- Subtitle: "Net, în mână"
- Următoare: "Pe ce dată intră salariul?"
- Calendar mic (1-31)
- Toggle: "Ai venituri extra? [Da / Nu]"
- Dacă Da: input opțional sumă aproximativă

### Ecran 4 — Bancă principală (15 sec)

- Întrebare: "La ce bancă ai contul principal?"
- Chips: BT / BCR / ING / Raiffeisen / Revolut / [Altă]
- Pentru altă: dropdown cu toată lista din 8.1

### Ecran 5 — Obligații cunoscute (60 sec)

- Titlu: "Ce plăți știi că ai lunar?"
- Subtitle: "Solomon le va găsi automat din email. Adaugă acum doar ce-ți amintești."
- Buton "+": adăugare rapidă (nume, sumă, data)
- Buton: "Sări peste, le găsește Solomon"

### Ecran 6 — Obiectiv (20 sec)

- Întrebare: "Ce vrei să rezolvi cu Solomon?"
- Chips multi-select: 
  - "Să nu mai fiu pe zero pe 22"
  - "Să strâng pentru vacanță"
  - "Să scap de datorii"
  - "Să economisesc lunar"
  - "Să înțeleg unde se duc banii"
- Câmp opțional: "Ai un obiectiv mare? (vacanță, mașină, casă)"

### Ecran 7 — Permisiuni (30 sec)

**Permission 1 — Email:**
- "Pentru a-ți arăta unde se duc banii, am nevoie să citesc emailurile cu facturi și abonamente."
- "Datele rămân pe telefonul tău. Nu citesc emailurile personale, doar pe cele financiare."
- Buton: [Conectează Gmail] (OAuth flow)
- Buton secundar: [Mai târziu] (cu warning: features limitate)

**Permission 2 — Notificări:**
- "Vrei alerte importante? Doar lucruri care contează: factura mare, IFN suspect, săptămâna ta."
- Buton: [Da, alertează-mă] / [Mai târziu]

**Permission 3 — Dataset (opt-in):**
- "Vrei să ajuți Solomon să devină mai bună pentru români?"
- "Conversațiile tale, anonimizate, ne ajută să antrenăm un model românesc mai bun."
- Default: OFF (consimțământ explicit cerut)
- Buton: [Da, ajut] / [Nu, mulțumesc]

### Ecran 8 — Procesare (1-3 minute)

**Dacă Gmail conectat:**
- Animație: "Mă uit la ultimele 6 luni..."
- Progress bar cu sub-tasks vizibile:
  - "Citesc emailurile financiare..."
  - "Identific tranzacții și abonamente..."
  - "Caut pattern-uri..."
  - "Pregătesc primul raport..."

**Dacă Gmail neconectat:**
- "Am nevoie de date pentru a-ți arăta valoarea reală."
- Alternative oferite:
  - Conectare Gmail acum
  - Import CSV extras bancar
  - Manual entry (cu warning: experiență limitată)

### Ecran 9 — Wow Moment

- Generare LLM cu JSON schema "wow_moment" (vezi secțiunea 6.2)
- Prezentare structurată în 7 secțiuni
- CTA principal: [Anulează abonamentele fantomă (recuperezi X RON/lună)]
- CTA secundar: [Continuă cu Solomon]

---

## 12. CE NU FACE SOLOMON V1 (EXPLICIT)

**NU face în v1:**

- Investiții, recomandări stocuri/ETF specifice
- Negociere automată cu IFN/bănci (doar trimitere către CSALB)
- Conectare directă PSD2 bank (email parsing e suficient)
- Family sharing / multi-user
- Apple Watch app (v2)
- iPad UI optimizat (v2 — funcționează default)
- Android (v2-v3)
- Voice input (v2)
- Trading sau crypto integration
- ANAF SPV / e-Factura (decis explicit: nu e relevant pentru target)
- Buget zero-based detailed (Solomon e mai relaxat — Safe to Spend over budget)
- Predicții de piață (Solomon e personal, nu speculativ)
- Negotiation Agent automat
- Future Self / Retirement visualization (anxiety-inducing pentru target)
- Gamification, streaks, badges, achievements

---

## 13. CE TREBUIE SCRIS ÎNCĂ ÎN URMĂTOAREA RUNDĂ

Următorii pași concreți pentru documentație + implementare:

### 13.1 Specificații tehnice de detaliu

- [ ] Schema Core Data completă (entities + relationships)
- [ ] Pattern Swift pentru MLX integration cu Gemma 4 E4B
- [ ] Cod exemplu pentru email parsing (Gmail API + extract data)
- [ ] Cod exemplu pentru generation pipeline (JSON build → LLM call → validate → display)
- [ ] Cod exemplu pentru Spiral Detector (algoritm complet)
- [ ] Cod exemplu pentru Pattern Detector

### 13.2 Design și UX

- [ ] Wireframe pentru fiecare moment (8 momente)
- [ ] Design system: colors, typography, spacing
- [ ] Tone & voice guide complet pentru Solomon
- [ ] Iconografie completă (Phosphor sau Lucide)
- [ ] States: empty, loading, error pentru fiecare ecran

### 13.3 Conținut

- [ ] Listă completă scenarii educaționale contextuale (~40 micro-lessons)
- [ ] Database IFN cu DAE typical (extins din 10.1)
- [ ] Database scam patterns RO active (10+ patterns cunoscute)
- [ ] Whitelist scraping domains (extins din 9)
- [ ] Lista completă subscription cancellation guides (top 30 services)

### 13.4 Legal și compliance

- [ ] Privacy Policy (GDPR-compliant)
- [ ] Terms of Service
- [ ] Disclaimer pentru "nu e consultanță financiară autorizată ASF"
- [ ] Consimțământ dataset training (formulare exactă)
- [ ] DPA cu Supabase pentru metadata

### 13.5 Plan implementare 12 săptămâni

- [ ] Săptămâna 1-2: Setup Xcode, MLX integration, Core Data schema
- [ ] Săptămâna 3-4: Email parser (Gmail OAuth + 5 senders top)
- [ ] Săptămâna 5-6: Analytics engine (modulele 1-4)
- [ ] Săptămâna 7-8: Wow Moment + Pot? Query (primele 2 momente)
- [ ] Săptămâna 9: Restul momentelor (Payday, Pre-factură, Pattern, Subscription, Spiral, Weekly)
- [ ] Săptămâna 10: Apărare layer (IFN, BNPL, Scam, CSALB)
- [ ] Săptămâna 11: Onboarding flow complet + UI polish
- [ ] Săptămâna 12: Testing intern + TestFlight beta închis

### 13.6 Distribuție

- [ ] Landing page solomon.ro
- [ ] Strategie distribuție prin 21 grupuri FB
- [ ] Beta TestFlight (50 useri)
- [ ] App Store submission preparation
- [ ] Pricing setup în App Store Connect
- [ ] Materiale marketing (screenshots, video demo)

---

## 14. CONTEXT CONVERSAȚIONAL VALIDAT

**Decizii confirmate prin testare empirică:**

✅ Gemma 4 E4B Q4 funcționează pe Mac M1 16GB la calitate production
✅ Generation time: 8-33 secunde acceptable pentru momentele Solomon
✅ 15/15 fapte folosite corect când prompt-ul oferă structură strictă
✅ Zero halucinații când LLM-ul e folosit doar pentru text generation
✅ Diacritice corecte 95%+ pe input bogat
✅ Nu inventează observații dacă instrucțiunile sunt clare

**Decizii confirmate strategic:**

✅ Cocoșul de buzunar exclusivist temporar (iPhone 15 Pro+ first)
✅ 100% local pe device pentru date personale
✅ DuckDuckGo pentru queries impersonale despre lume
✅ Solomon e ghid + display + advisor, NU broker
✅ Acumulare dataset RO pentru fine-tuning în Y2
✅ Pricing 39 RON/lună premium tier
✅ Nu ANAF, nu e-Factura, nu investiții directe
✅ Email parsing > PSD2 pentru v1
✅ Apărare layer cu CSALB Bridge ca diferențiator

**Decizii rămase de validat:**

⚠️ Conformitate ASF pentru "advisory" vs "educație financiară" — necesită consult avocat
⚠️ Volum exact email senders relevanți (lista din 8 e draft, validat ~80%)
⚠️ Pricing exact 39 RON sau testare 29/49 — A/B test landing page
⚠️ Stabilitate Gemma 4 E4B pe iPhone 15 Pro real (testat doar pe iMac M1)

---

## 15. METRICE SUCCESS V1

**Onboarding:**
- Completion rate (8 ecrane): >65%
- Email permission grant rate: >55%
- Notification permission grant rate: >70%
- Dataset opt-in rate: >25%

**Activation (primele 7 zile):**
- Wow Moment văzut: >85% din onboarded
- Cel puțin 1 acțiune luată din Wow Moment (anulat sub, etc.): >40%
- Trial-to-paid conversion: >15%

**Retention:**
- D7 retention: >55%
- D30 retention: >35%
- D90 retention: >25%
- Daily Active Users / Monthly Active Users: >35%

**Engagement:**
- Pot? Query/user/lună: >12
- Răspunsuri la pattern alerts: >40% engagement
- Subscriptions canceled prin Solomon: >2/user/an

**Business:**
- ARR la luna 6: 200.000 RON
- ARR la luna 12: 1.000.000 RON
- Churn lunar: <8%
- NPS: >50

---

## 16. NOTE FINALE

**Acest document e snapshot la 25 aprilie 2026.**

Reflectă conversațiile strategice cumulative + testarea empirică a Gemma 4 E4B + research de piață. E suficient ca specification pentru ca Claude Code să înceapă implementarea în Xcode.

**Ordine recomandată pentru următorul document:**
1. Schema Core Data + cod Swift de bază pentru data layer
2. MLX Swift integration cu Gemma 4 E4B (download model, inference setup)
3. Wow Moment end-to-end implementation (cel mai complex moment)
4. Restul momentelor pe baza pattern-ului din Wow Moment

**Scope discipline absolut:** Dacă apare în implementare un feature care nu e în acest document, oprește implementarea și discută. Nu adăuga features pe parcurs.

---

**Sfârșit document master Solomon v1.**
