# docs-working-model: incubation ↔ terminology lifecycle 정정 — Work Packet

> round-scoped 작업노트(line-level 분류 · 삽입 초안 · edge-case). 승인 대상 아님, live 문서 아님, Spec 대체 아님. 실행 명령/리뷰 결과는 여기 금지(→ `log/**`). closeout 시 흡수 후 삭제(보존=git history). 이 문서는 어떤 승인도 아니다(1회 진술).

## 편집 대상 절 분류 (`docs-working-model.md`)

| 편집 ID | 대상 절(현행) | Design 항목 | 편집 종류 |
|---|---|---|---|
| E-1 | `Incubation tier` > **Mandatory terminology registration** bullet | (A)(B)(E)(F) | rewrite |
| E-2 | `Incubation tier` > **신규** "Glossary registration is independent of incubation" 한 문장 (E-1 앞) | (A) decouple | insert |
| E-3 | `Incubation tier` > **신규** "Incubation applicability (default strict)" bullet (`Form early, authority late` 인접) | (C) | insert |
| E-4 | `Cross-domain semantics restriction` 절 | (D) contrast 허용선 | append bullet |
| E-5 | `Candidate lifecycle` bullet 의 promote/discard 시 "finalize" 표현 | (B) 정합 | reword(포인터화) |
| E-6 | `Spec identity` 절 | (B) 정합 | 무변경 확인(또는 1줄 cross-ref) |

## 삽입 초안 (구현이 다듬을 출발 텍스트)

**E-2 (decouple, E-1 앞 한 문장).**
> **Glossary registration is independent of incubation.** Terminology changes in `rules/terminology-glossary.md` have their own cycle and many sources (existing-feature/rule change, operating-concept change, a rejected-term addition, an accepted-term owner-boundary adjustment, naming cleanup); a candidate's incubation is only *one* such source. "Glossary change ⟸ incubation" is a false coupling — the proportionality rule (meaning-preserving = direct; normative = lifecycle) governs glossary edits as it does any doc.

**E-1 (Mandatory→Conditional terminology registration; rewrite).** 핵심 변경점:
- "mandatory at anchoring, every meaning-bearing term" → **conditional**: 후보 밖 tracked surface 노출 또는 충돌가능(accepted/pending/rejected 와 동일·혼동 / identity 이름이 broad bucket 오해가능 / 2+ candidate 가 다른 의미)일 때만 thin reservation **required**; 내부 label·임시 phase·nickname 은 미등록; 애매하면 thin 예약하되 의미정의 금지; 분류 = 작성자 self-classify → integration reviewer challenge → **glossary rule owner = 최종 중재**.
- pending reservation 형식 = **owner-identity**(`owner` / `facet` / `not-this` / `promotion-target` / 고정형식 `collision-note`) — **`_incubation.md` 경로 durable pointer 금지(E2)**; 의미정의 0. accepted = glossary 가 의미 single home(+절차 owner pointer) *불변*.
- finalization(B): "promotion 시 확정" 삭제. 확정(accepted/rejected/owner-boundary) = **owner surface final state → glossary 반영 → corrected-state review → 승인 → commit**. 종류별: domain=Spec/impl closeout changeset 내 / rule=terminal rule landing changeset 내(+exposed pending term 처리; terminal rule=owner surface) / 비-candidate=그 변경 corrected-state review 내. "아무 때나 decouple" → 위 기본값으로 tighten(단 term≠candidate fate 는 유지).
- owner-boundary(F): status(accepted/pending/rejected) 아닌 **별도 분류/closeout 조건**으로 표기.
- transition(E): 기존 문장 유지·일반화 — "in-flight 후보는 정리 방향 적용, 과거 미등록/비정합을 결함으로 보지 않음"(consultation/blind 에 더해 orchestration 포함).

**E-3 (Incubation applicability; 신규 bullet).**
> **Incubation applicability (default strict).** An incubating candidate is governed by *default* by every rule here; only the items listed as relaxed are relaxed, and an unlisted rule stays strict (a new relaxation is itself a reviewed rule change). **Strongly applied:** public-safe, durable-pointer prohibition, placement/filename, non-authoritative marking, owner/review-date/discard criteria, E1–E5, confusion-prevention with existing domains/rules. **Not required during incubation:** closeout 1:1 sync, accepted-term do-not-repeat strictness, production polish, final terminology. **Still required (so the candidate stays judgeable at review-date):** the identity, scope, not-this, contrast, and discard evidence needed for the promote/discard decision. (This is an applicability statement, not a loose "exception zone".)

**E-4 (contrast 허용선; Cross-domain semantics restriction 에 append).**
> **Incubating candidates — define-by-contrast, foreign-semantics pointer-only.** An incubating candidate may state its identity by contrast with an existing concept, but must not own the other's semantics. *Allowed:* "X와 달리 이 후보는 Y만 다룬다" / "X의 authoritative 의미는 X를 따른다" / "이 후보는 verdict 를 내지 않는다". *Blocked (these stay reviewer blockers):* restating another domain's full status vocabulary, lifecycle/permission/completion semantics, or normative behavior; a global self-attestation ("this doc does not restate X"); a foreign schema/field/procedure written as a standalone definition without a source pointer. Inter-candidate relations are marked thinly (`depends-on` / `contrasts-with` / `independent-of`) with foreign semantics pointer-only (preserves discard independence). Catching a genuine cross-domain restatement defect remains a blocker; what is forbidden is *requiring more foreign definition* to fix it.

**E-5/E-6.** Candidate lifecycle 의 "finalize at promotion/discard" 문구를 E-1 의 finalization 모델로 포인터화. Spec identity 는 무변경(이미 "closeout 에서 live") — 필요 시 E-1 에서 cross-ref 한 줄.

## Edge / 정합 체크(구현 시 확인)

- "promotion 시 확정"·"glossary becomes single home ... only at promotion" 잔존 0 (E-1 에서 제거/대체).
- accepted-term 모델 불변(over-correction 금지) — E-1 에 명시.
- E5(one-time bootstrap) 진술과 충돌 없음 — applicability/decouple 은 새 candidate 의무를 *늘리지* 않고 *분리/완화*.
- Final hard rule(docs 비-authority)·top-down reference 위반 0.
- glossary 파일 자체는 cs1 에서 미수정(콘텐츠=cs2) — 규칙 텍스트만 변경.

## 재조율 보정 (round-3 적용 — 구현은 이 보정을 우선 적용)

- **E-1 trigger 좁힘.** "충돌가능" = "현재 tracked surface 또는 같은 changeset 내 후보에서 *실제 관찰된* 동일/혼동 사용"으로 한정. "broad bucket 오해" = "accepted/pending/rejected 또는 rule-owned vocabulary 와 혼동될 때"로 제한. reviewer 가 thin reservation 을 요구하려면 *observed surface + collision class* 를 적시한다(막연한 '오해가능' 금지).
- **E-1 필드명.** `promotion-target` → **`eventual-owner-surface`**(= 용어가 최종 안착할 owner surface; *promotion 시 확정* 아님). glossary 의 기존 "promotion target" 표현은 cs2 에서 정렬.
- **E-1 exposed pending term 처리 = 셋 중 하나 명시**: `accept` / `reject` / `keep-pending-with-owner-boundary`.
- **E-1 thin reservation 필드 한정.** 허용 필드 = owner / facet / not-this / eventual-owner-surface / 고정형식 collision-note. **금지 = meaning-definition · example · usage · procedure · schema**(전부 incubation 문서 소유).
- **E-2.** "...governs glossary edits as any doc" 뒤에 **"(subject to glossary single-home constraints)"** 추가.
- **E-3 추가 문장.** "판정가능성 보강은 candidate 자신의 identity/scope/not-this 를 *좁히는* 방식이어야 하며, foreign domain 의 definition/schema/procedure 확장을 요구할 수 없다."
- **E-4 추가 문장.** "contrast 부족 결함은 candidate self-claim 축소 또는 pointer 추가로 고친다(foreign definition 확장이 아님)."
- **transition 종료 조건(E).** 새 glossary/finalization 규칙은 이 rule landing 즉시 발효. in-flight 후보(stashed)는 cs2 에서 재정렬되고 cs2 closeout 부터 완전 적용. **transition 면제는 cs2 까지로 한정(영구 아님).**
- **lifecycle 문서 retire.** Design/Plan/WorkPacket 헤더의 temporary/non-authoritative/retire 명시는 유지하고, **terminal closeout 에서 rule text 만 남기고 이 lifecycle 3문서를 같은 closeout 에서 retire(별도 cleanup 으로 미루지 않음).**

## 최종 삽입 텍스트 (blind round-4 보정 반영 — 구현은 이것을 docs-working-model.md 에 영어로 반영)

> **⚠ batch-4 supersession.** 아래 [E-1]/[E-2] 는 batch-1 의 source draft 다. batch-4 가 이 terminology-registration 모델을 개정했다 — `owner-pending`(가등록) 상태 도입(finalization-owner 가 이미 live authority 인데 finalization deferred) + `owner-surface close` → `finalization-owner close` rename + carry-forward `pending`→`owner-pending`. **현 live 모델 = live rule + 아래 ## batch-4 작업노트**; 이 batch-1 draft 의 pending-only / 단일 close 표현은 historical 이다.
>
> blind 9 concern 반영: 단일 필드목록(1) · "애매하면"을 observed-exposure 한정(2) · "확정" 의미·순서 명확화(3) · glossary(한 줄 의미)↔owner surface(full semantics) 분리(4) · "rule-owned vocabulary" 삭제하고 "glossary-registered term"으로 단일화(5) · transition 종료를 후보별 realigning changeset closeout 으로(6) · name reservation↔meaning finalization 구분(7) · non-authoritative marker↔cross-domain self-attestation 구분(9). concern 8(public-safe/durable-pointer 판정기준)은 host rule 에 이미 정의 — cold-read artifact, in-context 비결함.

**[E-2] Glossary registration is independent of incubation.**
Terminology changes in the glossary have their own cycle and several sources — an existing-feature/rule change, an operating-concept change, recording a do-not-revive (rejected) entry, an accepted-term owner-boundary adjustment, or naming cleanup; a candidate's incubation is only one such source. The proportionality rule governs a glossary edit as it governs any doc edit, within the glossary's single-home constraint. **Meaning-home division:** the glossary is the single home of a term's *one-line meaning + classification*; the term's *full semantics / procedure* live on its owner surface (a spec or rule). An *finalization-owner close* is that owner surface (not the glossary) reaching its target state at closeout; **when a term is finalized at such a close (see [E-1]), the glossary records its one-line meaning + classification at that point** — a term not yet finalized stays a thin `pending` reservation.

**[E-1] Terminology registration is conditional, not mandatory-at-anchoring.**
A meaning-bearing term a candidate introduces is registered in the glossary as a thin `pending` reservation **only when it is exposed or collision-prone**:
- *exposed* — the term appears on a tracked surface **other than the candidate's own incubation document** (e.g. another doc's filename/heading/anchor, a reference from another document, or a rule/spec/operating doc); the candidate's own filename, headings, anchors, and internal references are not exposure.
- *collision-prone* — an **observed** identical/confusable use of the name, either against a glossary-registered term (accepted / pending / rejected) or against another candidate's term introduced in the same changeset (even if neither is registered yet). The *collision class* is the matched target's category (which glossary state, or a same-changeset candidate).
Terms used only inside the incubation document (internal labels, one-off phase names, explanatory nicknames) are not registered — **unless the name is collision-prone per the definition above** (a collision against a glossary-registered term *or* a same-changeset candidate is itself a registration trigger, even for an otherwise-internal term). **Who registers/requires:** the candidate author may proactively register a thin reservation whenever exposure is observed (when an exposure's collision class is still uncertain, treat it as an exposure-only reservation — reserve thin, no collision-note, define no meaning). A *reviewer* may require a reservation on either basis: for exposure, citing the observed external surface; for collision, citing the observed surface plus the collision class. A bare "could be confused" is insufficient. Classification disputes are arbitrated by the glossary rule owner.
- **Reservation fields (use only these, no others):** `candidate` (= the candidate that introduced the term) / `facet` (which sub-aspect, a few words) / `not-this` (a few-word exclusion marker) / `eventual-owner-surface` (the current expected owner surface where the term will ultimately live — optional if not yet known; naming the destination is not a finalize-at-promotion); **plus `collision-note` only for a collision-prone reservation** (fixed form "Potential collision with X; defines no semantics; see this reservation's candidate"). An exposure-only reservation omits `collision-note`. **"Define no meaning"** = no positive one-line definition, example, usage, procedure, or schema; `facet`/`not-this` are short identity-scoping markers (a few words each), and if either grows into a positive definition/example/procedure it violates "define no meaning". No durable path pointer to the `_incubation` document — owner identity only (an owner/surface name, never a file-path pointer; E2). The full domain-local definition stays in the incubation document.
- **Name reservation vs meaning finalization.** Registering a thin `pending` reservation (a *name-level* act) is distinct from *finalizing a term's meaning*. The glossary finalization outcomes are exactly `accepted` / `accepted-with-owner-boundary` / `rejected`. During incubation only the conditional name reservation may be required; **final terminology is never required during incubation.** **Each finalization-owner close forces a per-term decision** for every meaning-bearing term that surface **owns** (i.e., is the owner surface for — not terms it merely references), whether already registered `pending` or first going public at this close: either finalize it (to one of the three outcomes) **or** explicitly carry it forward as `pending` with a stated reason (finalization is decoupled — a term may legitimately need more incubation than one finalization-owner close). The close is a decision point, not a mandatory-finalize point. When a term *is* finalized in a changeset, its glossary finalization is applied **before that change's corrected-state review** (so the review validates the final terms; applying it after would make the review stale). The finalization-owner close is: domain candidate → its Spec/implementation closeout changeset; rule candidate → its terminal rule-file landing changeset; a non-candidate terminology cleanup → that change's own corrected-state review.
- **Transition.** This model takes effect at this rule's landing. A candidate already in-flight then is not retroactively in default. A *realigning changeset* = the next changeset that edits that candidate's content; such a changeset must conform the candidate to this model (a changeset may not edit the candidate's content while leaving it non-conforming). An unrelated change (one not touching the candidate's content) does not end the exemption. The candidate's terms become fully bound at that realigning changeset's closeout, where the per-candidate exemption ends (it is not permanent). The mechanical check for this model is enabled in that same realigning changeset (transition-aware), not at this rule's landing.

**[E-3] Incubation applicability (default strict).**
An incubating candidate is governed by default by every rule in this document; only items listed here as relaxed are relaxed (an unlisted rule stays strict; adding a relaxation is itself a reviewed rule change). This is an applicability statement, not a loose exception zone.
- *Strongly applied:* public-safe, the durable-pointer prohibition, placement / filename, the non-authoritative marking, owner / review-date / discard criteria, E1–E5, confusion-prevention with existing domains/rules.
- *Not required during incubation:* closeout 1:1 sync, accepted-term do-not-repeat strictness, production polish, final terminology.
- *Still required (so the candidate stays judgeable at its review-date):* the identity, scope, not-this, contrast, and discard evidence the promote/discard decision needs. Strengthening judgeability must narrow the candidate's **own** identity/scope/not-this — it may not require expanding any foreign domain's definition / schema / procedure.

**[E-4] Define-by-contrast, foreign-semantics pointer-only.**
An incubating candidate may state its identity by contrast with an existing concept but must not own the other's semantics.
- *Allowed:* "unlike X, this candidate covers only Y"; "X's authoritative meaning follows X"; "this candidate issues no verdict".
- *Blocked (these remain reviewer blockers):* restating another domain's full status vocabulary, its lifecycle / permission / completion semantics, or its normative behavior; a foreign schema / field / procedure written as a standalone definition with no source pointer.
- The required non-authoritative marker (a candidate declaring its **own** authority status) is allowed. What is banned is a *global self-exempting* meta-claim about the doc's own cross-domain behavior (e.g. "this document does not restate any other domain" / "depends on no other domain") — unverifiable boilerplate, often self-contradicted by the doc's own contrast statements. The specific, local contrasts in the *Allowed* list above are fine.
- A genuine cross-domain restatement defect stays a blocker; what is forbidden is *requiring more foreign definition* to fix it — fix it by narrowing the candidate's own claim or adding an owner/surface identity pointer (an owner/surface name, never a file-path pointer).
- Inter-candidate relations are marked thinly (`depends-on` / `contrasts-with` / `independent-of`) on the candidate surface (the incubation document), not as glossary reservation fields, with foreign semantics pointer-only (preserves discard independence).

## batch-2 작업노트 — rule_docs 모델 일반화 (편집 대상)

| 편집 | 대상 | 종류 |
|---|---|---|
| R-1 | `docs-working-model.md` "Incubation document" bullet(rule_docs 위치 문구) | reword(candidate-only → planning workspace 참조) |
| R-2 | `docs-working-model.md` "`rule_docs/` — the in-repo rule add/revise planning workspace" bullet(신설; 3-state·persistent·purity·orphan) | rewrite(구 "rule_docs purity" 대체) |
| R-3 | `docs-working-model.md` "Candidate lifecycle" bullet 의 promote/discard 폴더 fate | reword(promote=폴더 persist / discard=폴더 삭제; R-2 와 정합) |
| R-4 | `scripts/docs-working-model-check.ps1` rule_docs 로직 | rewrite(3-state: idle=.gitkeep[기존 rule 필수]/candidate=incubation/active=design·plan·work_packet; orphan·allowed-file·subfolder 검사) |
| R-5 | `tests/docs-working-model-check.Tests.ps1` | rule_docs 3-state·orphan·disallowed-file·loose-file 케이스 |
| R-6 | `docs/README.md` rule_docs 설명 | candidate-only → 일반화 모델로 정정 |

**canonical pass-01 정정 반영:** ① R-2 의 "promote 시 폴더 persist" ↔ R-3 의 "promote 시 폴더 삭제" 모순 해소(intra-doc sibling-sweep 누락이었음 — R-3 를 R-2 와 정합). ② active-state 의 `_incubation`+`_design/_plan` 공존 claim 제거(promote 시 `_incubation` 흡수·삭제 후 design/plan → 비공존 → E3 무결). ③ idle backing 위치를 `rules/<id>/<id>.md` *또는* `snippets/rules/<id>.md` 로(rule/check/tests 일치). ④ 이 lifecycle docs(Plan/Design/WP)가 batch-2 를 cs1 scope·승인대상으로 명시.

## batch-3 작업노트 — promotion incubation 처분 정합 (E4-centered)

> orchestration(relay-A→relay-B→blind→재조율→re-blind→relay-B[Plan]) 검증 방향. 아래는 *구현이 다듬을 출발 텍스트*(영어로 `docs-working-model.md` 반영). 강도 = Plan hard boundary 준수. **rule 미편집 — 이건 초안 노트.**

### 편집 대상 절 (`docs-working-model.md`)
| 편집 | 대상 절 | 종류 |
|---|---|---|
| B3-1 | *Document artifact classes* item 2 (`_incubation` "until closeout") | reword(closeout = *candidate-lifecycle* closeout 명시) |
| B3-2 | *Incubation tier* > Candidate lifecycle (promote) | reword(흡수 = E4 형식·removal precondition; 손실=E4 under-application) |
| B3-3 | *Incubation tier* > 3-state (active/promotion) | reword(제거 = candidate-lifecycle closeout; no committed coexistence 유지; E4 precondition) |
| B3-4 | *Closeout — reduced two-level gate* / *Lifecycle closeout — absorption and retire* | add(3 closeout 명명 + 체크리스트 `_incubation` 누락 이유 + local-중의성 단서) |
| B3-5 | 신설 절 *State migration (same role-slot)* (위치 = Lifecycle closeout / Stage rewind 인접) | new |

### 삽입 초안 (출발 텍스트 — 영어 반영)
- **B3-1**: "… the **`_incubation` document** (candidate-lifecycle-scoped, not round-scoped; disposed at its **candidate-lifecycle closeout** — the candidate's promotion or discard — which precedes any promoted-lifecycle closeout; see *Incubation tier*)."
- **B3-2**: "… the incubation document's current-bearing content is absorbed into the promoted artifacts **per E4 (every current-bearing item represented in E4 form — adopted conclusion / rejected alternatives / judgment-changing evidence type / scope / failure criteria / negative evidence — not raw-carried). This E4 absorption is complete as a precondition of removal, within the atomic promotion transition;** then the `_incubation.md` is removed. **A promoted artifact smaller than the `_incubation` is not a licence to lose reference — incomplete absorption is an E4 violation, not a reason to preserve the raw document.**"
- **B3-3**: "… at promotion the `_incubation.md` is **removed as the candidate-lifecycle closeout** (E4 absorption complete as its precondition), so it never coexists with `_design`/`_plan`/`_spec` in committed state — E3 stays intact."
- **B3-4** (Lifecycle closeout 에 추가): "This is the **promoted-lifecycle closeout** — Design / Plan / Work Packet are disposed here. `_incubation.md` is **not** listed because it was already disposed at the earlier **candidate-lifecycle closeout** (its promotion or discard). The closeout events are distinct and **locally disambiguated** (this does not redefine *closeout* elsewhere): *candidate-lifecycle closeout* (promotion or discard — disposes `_incubation.md`) · *promoted-lifecycle closeout* (this section) · *candidate-discard closeout* = the discard variant of the candidate-lifecycle closeout. Each temporary artifact is disposed at **its own** closeout."
- **B3-5** (신설): "**State migration (same role-slot).** Beginning a new revision of a rule/domain whose *prior* revision's planning docs (`_design`/`_plan`/`_work_packet`, or a candidate `_incubation`) remain un-retired in the **same role-slot** requires their disposition first — the applicable closeout, or an explicit decision to continue them as this revision's docs. A stashed or pre-revision artifact is **non-authoritative until judged** (reuse / re-verify / discard). This binds only the same role-slot — it does not block parallel per-domain / per-rule revisions, and creates no archive / subfolder (per *Stable filename rule* / `rule_docs/` purity)."

### Edge / 정합 체크 (구현 시 = lightweight local clause-map)
- "closeout" 전 사용처가 어느 lifecycle 를 가리키나 전수(candidate / promoted / discard) — *global 재정의 0* 확인.
- B3-2 의 E4-precondition 문구가 기존 "absorbed (E4)" 와 모순 0.
- B3-5 가 *Stable filename rule*(role 재사용)·`rule_docs/` purity(no archive/subfolder)·per-domain batch 모델과 비충돌.
- `docs-working-model-check.ps1` 영향 = file/material 재해석 없으니 구조 discriminator 불변(확인만; 변경 시 별도).
- **retire 조건**: closeout 시 이 batch-3 노트도 batch-1/2 와 함께 삭제(rule 텍스트에 흡수된 뒤).

## batch-4 작업노트 — terminology 등록 lifecycle: owner-pending(가등록) 도입

> docs-working-model revision 의 continuation(batch-1 이 이미 incubation↔terminology scope). orchestration: relay-A ×2 → relay-B ×4(수렴) → 설계 blind ×4 → 구현 → diff-blind ×3(self-introduced 6→4→0) → canonical dual(LC yes-with-risk / SC yes). rule 이 자기 용어를 거버닝하는 self-referential 변경.

**결함 (batch-1~3 산 cs1 모델).** 용어 등록 타임라인이 두 점만 규정 — incubation thin `pending` / finalization-owner close finalize. 그 사이 "finalization-owner 가 이미 live authority 인데 closeout 미완"(=가등록) 구간 부재 → live-but-deferred 용어(closeout 2건)가 incubation 칸 `pending` 에 오배치.

### 편집 대상 절
| 편집 | 대상 | 종류 |
|---|---|---|
| B4-1 | glossary Status vocabulary `pending / owner-pending` | split(finalization-owner-live 축) |
| B4-2 | glossary How-to-use / `## Pending / owner-pending terms` intro + 두 subsection(`### Pending` / `### Owner-pending`) | restructure |
| B4-3 | glossary closeout 2건 → owner-pending subsection(필드 변환: candidate owner/promotion-target 제거 → finalization-owner+close-condition) + 신규 `finalization-owner` 항목 | move + add |
| B4-4 | glossary Term-ownership / Do-not-repeat 형제 | reword |
| B4-5 | rule *Glossary registration* Meaning-home division | reword(finalization-owner / pending↔owner-pending) |
| B4-6 | rule *Terminology registration* 신규 "Owner-pending registration" bullet | new |
| B4-7 | rule carry-forward(`pending`→`owner-pending`) / finalization-owner close enumeration(+existing-rule revision) / rejected sweep / line~155 disambiguation 용어 통일 | reword |

### 확정 모델 (canonical 통과)
- status `pending`(finalization-owner 아직 live 아님) / `owner-pending`(이미 live, finalization deferred; one-line meaning + classification 보유). 축 = finalization-owner-live (thin-vs-fuller 아님 — 별도 pre-existing residual, 미터치).
- owner-pending trigger = finalization-owner live-authority landing(기존-rule revision rule landing / deployed implementation / 기존 live domain sync-required Spec update; 신규 domain Spec 제외; trigger ≠ commit/push 승인 행위).
- owner-pending 필드 = one-line meaning + `finalization-owner`(owner id / tracked path; E2) + `facet` + `close-condition` + `not-this` (+ close 후 carry 시만 `carry-forward reason`).
- monotonic(owner-pending→pending 금지; 단 go-live 오판 정정 시 pending 형식 축소). finalization-owner retire-before-close → per-term 결정 강제(orphan 0). rejected 전이(pending/owner-pending 공통) → 4-class cross-surface sweep 후 corrected-state review.
- `finalization-owner` ≠ active-behavior `owner surface`(live Spec 이 finalization-owner 여도 active 격상 아님). `finalization-owner` 자체를 glossary owner-pending 항목으로 등록(자기참조 dogfood).
- 이동 = closeout 2건만(finalization-owner=`rules/docs-working-model/docs-working-model.md`, close-condition=deferred 미래 closeout); 나머지 candidate 는 pending 유지.

### Edge / 정합 (확인)
- pending 항목 thin-vs-fuller 내용규칙 = 별개 pre-existing residual, batch-4 미터치(Path 1).
- pre-existing out-of-scope 2건(candidate `close=on promotion`; glossary rejected `rule_docs` 의 3-state desync)은 batch-4 산 아님(별도 correction-target).
- 위 "최종 삽입 텍스트"(batch-1 source draft)는 batch-4 가 모델 개정함 — supersession 마커 + `owner-surface close`→`finalization-owner close` rename 으로 동기화.
- retire 조건: closeout 시 이 batch-4 노트도 batch-1/2/3 와 함께 삭제.
