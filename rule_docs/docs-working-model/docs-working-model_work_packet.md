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

## Phase-1 작업노트 — 5-D: Design content/altitude 경계 + detail-flow 원칙

> 5-D Plan 의 승인대상 결정을 line-level 편집 + 삽입 초안으로 옮긴 round-scoped 노트. *이 노트가 정확 문구를 드는 것 = 5-D 원칙(detail 은 WP altitude)을 5-D 자신에 dogfood.*
> **★ 구현됨(implementation landed) + full-scope orchestration 정정.** 아래 [D-1]/[D-2]/[D-3] 는 *구현 출발 초안*이고, **final wording 의 single-home = live rule** `docs-working-model.md`(여기 중복 안 함). 구현 시 full-scope blind+relay-B(Codex 가 규칙 *전문* read; diff 아님)가 초안의 **over-absolute invariant** 를 잡아 모델 정정: ① invariant 를 *Design→Plan→Spec/terminal-rule lifecycle* 로 **scope** ② `_incubation`(multi-grade dossier)·*State migration*(carried-over) **special-paths carve-out** ③ 나머지 artifact class(`log/**`·backlog·glossary·active-surface wording)는 *자기 절이 소유* 명시(재라우팅 안 함) ④ Design 경계에 **decision-critical identifier·결정인 closed enum 허용 / exhaustive inventory·final normative wording 제외** nuance ⑤ axis note 를 *lifecycle 발동 여부*로 한정(WP/incubation/backlog 는 자기 trigger). re-blind = no-concerns. 아래 초안은 이 정정 *전* 텍스트이므로 final 은 rule 을 본다.

### 편집 대상 절 (`docs-working-model.md`)
| 편집 | 대상 절 | 종류 |
|---|---|---|
| D-2 | *Design / Plan / Spec lifecycle* 절 > **최상단** 신규 "Lifecycle invariant — detail flows downward" 항목 | insert(독립 top-level 절 아님 — single-home; 단 절 *맨 앞*에 둬 안 묻히게; 모든 artifact 에 거는 invariant) |
| D-1 | 같은 절 > **Design** bullet | reword(content/altitude 경계 — *detail-grade 별* 제외, decision-grade 유지) |
| D-3 | *Proportionality rule* 절 끝 | append(축-구분 cross-ref 한 줄; 본문 미변경) |
| D-4 | *Spec identity* 의 "must not contain" | 무변경 *확인*(Design 경계가 이와 동형인지 대조) |

### 삽입 초안 (출발 텍스트 — 영어 반영; blind+relay-B 정렬 반영)

**[D-2] Lifecycle invariant — lifecycle 절 *최상단*에 신규(모든 artifact 에 거는 invariant).** *(routing 은 re-blind 정렬로 [W]/[S]와 완결 대조: implementation notes·evidence proposals=WP / execution records=log / semantic target=Design vs durable specification=Spec.)*
> **Lifecycle invariant — detail flows downward (altitude per artifact).** Every lifecycle artifact holds only its own altitude, and detail flows to the artifact that owns it **by kind**, never bucketed upward: **direction rationale / conceptual model / chosen trade-offs / ownership boundary / non-goal scope / the semantic target (what the change must come to mean) → Design**; **approval-target decisions → Plan**; **round-scoped investigation / alternatives / line-level analysis / implementation notes / evidence proposals → Work Packet**; **the durable target-state *specification* / normative rule text → the live Spec, or for a `rule_docs` item the terminal rule file (no separate Spec)**; **execution records / outcomes → operator reports under `log/**`**; **final exact wording → the Spec / terminal rule (never the Design)**. Front-loading a lower-altitude detail into a higher artifact is a defect (it over-commits before the deciding artifact); pushing an approval-target decision *down* into a Work Packet is the inverse defect (it escapes the approval gate). **Omitting an artifact (per the proportionality rule) does not promote its content to another home — create the owning artifact, or drop / externalize the detail; never smuggle it upward.** This invariant binds every lifecycle artifact, including any added later.

**[D-1] Design bullet — content/altitude 경계(detail-grade 별 제외, decision-grade 유지).**
> **Design** — why / what / owner-surface model / chosen trade-offs / non-goals / which live Spec or implementation it modifies; a **decision-grade direction** artifact, **not permanently live.** A Design carries the *semantic target* (what the change must come to mean) and the decision-grade content needed to align direction — conceptual model, ownership boundary, the deciding target-state invariant, and **representative / boundary examples** (not exhaustive enumerations). It does **not** carry lower-grade detail: round-scoped / line-level analysis, execution sequences / staging / mechanics, exhaustive enumerations, precise marker / field / token names, or **final exact wording** — those flow to their own homes per the lifecycle invariant above (Work Packet, `log/**`, the Spec / terminal rule). This is the Design's content boundary, parallel to the Plan's *not-a-work-memo* and the Spec's *must-not-contain* boundaries. (Distinguish the *semantic target* / deciding invariant — a Design carries it, at direction grade — from the **durable target-state specification and exact wording**, owned by the Spec / terminal rule.)

**[D-3] Proportionality rule — 축-구분 cross-ref 한 줄 append.**
> (Axis note: the proportionality test decides *which artifacts are created at all* — a normative-meaning change invokes the lifecycle, a meaning-preserving edit does not. The **detail-flow lifecycle invariant** decides *what each created artifact holds*. They are different axes; do not conflate them. Their interaction is governed by that invariant's clause: **omitting an artifact under proportionality does not license moving its content into another artifact.**)

### Edge / 정합 체크 (구현 시 = lightweight 대조)
- **동형 + grade**: D-1 의 Design 경계가 Plan "not a work memo"·Spec "must not contain" 과 *동형*이며, *detail-grade 별* 제외 + *decision-grade 유지*라 over-restrict(decision-grade 막음) 0 & under(detail 샘) 0.
- **single-home + prominence**: D-2 가 *Design / Plan / Spec lifecycle* 절 *최상단* invariant 로(독립 top-level 절 0 = single-home, 단 묻히지 않게); 모든 artifact 에 거는 invariant(후속 artifact 상속).
- **home-routing 종류별**: D-2 의 라우팅이 종류별로 누수 0 — 특히 **execution-grade → `log/**`**(Spec/rule 에 실행순서 lock 0; blind C1), round-scoped → WP(Plan 으로 안 샘; blind C2). "Plan+WP 버킷" 표현 잔존 0.
- **Proportionality 본문 불변 + 예외**: D-3 는 cross-ref 한 줄 append 만(판정 로직 미변경) + "artifact 생략 ≠ content 승격" 예외 명시(single-home 은 D-2 invariant; D-3 는 참조).
- **rule_docs 확정지점 정합**: "terminal rule 파일" 이 기존 "rule = 자기 spec-of-record"(Incubation tier·E3·Stable filename rule)와 충돌 0.
- **candidate-agnostic**: 어느 후보(consultation/blind/orchestration)와도 무관 — 일반 lifecycle 작성 규율만.
- **Final hard rule**: docs 비-authority·active-surface=authority(P0-3) 위반 0(이 변경은 rule 본문 = active surface).
- **retire 조건**: closeout 시 이 5-D 노트도 batch-1~4 노트와 함께 삭제.

## Phase-1 작업노트 — 5-K: promotion 전이 (entry artifact swap; transition-aware E3)

> 5-K Plan 결정을 line-level 편집 + 삽입 초안으로(5-D landed 규칙 위에서). final wording single-home = live rule.
> **★ 구현됨 + full-scope orchestration 정정.** 아래는 출발 초안이고 final = live rule. full-scope blind+relay-B(규칙 전문 read, diff 아님)가 잡아 정정: ① blind — 내가 *안 건드린* 두 곳(line 86 "writes terminal rule file directly", line 95 "absorbed into rules/ rule file")이 5-K entry=`_design` 와 이중진술 → rule-candidate entry 일관화(entry=`_design`, terminal rule=eventual output) ② relay-B — Proportionality-collapse hedge 제거(promotion=normative→min `_design`) · E4 흡수 by-kind 명시(decision-grade→`_design`·never WP / round-scoped→active-lifecycle WP / `_incubation` raw 0) · filename↔live-authority 분리 ③ re-blind — 내 by-kind fix 가 "never WP"+"into WP" 문장내 모순 → 별개 절 분리. 수렴(re-blind no-concerns). 전체 discovery/state-machine·rename-lineage = **5-B defer**.

### 편집 대상 절 (`docs-working-model.md`, *Incubation tier*)
| 편집 | 대상 | 종류 |
|---|---|---|
| K-1 | *Candidate lifecycle* promote 문단(E4 흡수 대상 "the promoted Design / Plan / Spec, or the terminal rule file") | reword(→ entry promoted artifact `_design`; swap 명확화) |
| K-2 | 3-state *active lifecycle work* 문단("within the one promotion transition (a single changeset that writes the promoted artifacts and removes the `_incubation.md` together)") | reword(swap=`_incubation`→`_design`; atomicity=E3-intact 보장; transient fallback) |
| K-3 | *E3* 문단("no canonical-looking sibling … created during incubation") | reword(transition-aware: binding window=`_incubation` 존재 기간) |

### 삽입 초안 (영어 — 구현이 확정)
**[K-1] Candidate lifecycle promote — E4 흡수 대상 정밀화.**
> …the incubation document's current-bearing content is absorbed (E4 — every current-bearing item in E4-required form, not raw-carried) into **the entry promoted artifact: the `_design.md` that the promotion transition writes** (a domain candidate then continues Design → Plan → Spec, a rule candidate Design → Plan → terminal rule — the proportional shape of that lifecycle is governed by the *Proportionality rule*), **never the Work Packet**, as a **precondition of removal** within the promotion transition (the atomic `_incubation.md` → `_design.md` swap); then the `_incubation.md` is removed (the candidate-lifecycle closeout). The remaining current-bearing content is carried forward by that normal lifecycle (the promoted-lifecycle closeout reconciles the eventual Spec / terminal rule 1:1) — not re-absorbed and not lost; a promoted Design smaller than the `_incubation` is still an E4 violation, not a licence to keep the raw document.

**[K-2] 3-state active — swap + atomicity 한정.**
> …at promotion the `_incubation.md` is removed as the candidate-lifecycle closeout — its E4 absorption into **the entry promoted artifact (the `_design.md`)** completed as a precondition of removal — within **the promotion transition: the one atomic changeset that removes `_incubation.md` and writes `_design.md` together (the `_incubation.md` → `_design.md` swap)**, so `_incubation.md` never coexists in committed state with `_design.md` / `_plan.md` / `_spec.md` — E3 stays intact. (That atomicity guarantees only the non-coexistence; *what state* the promoted artifact is then in — promoted but not yet live — follows the *Spec identity* time-phasing until a lifecycle-state marker is defined for it.)

**[K-3] E3 transition-aware.**
> **E3** — before promotion a candidate artifact is not a default or input of any canonical surface …; no canonical-looking sibling (`_design` / `_plan` / `_spec`) is created **while the `_incubation.md` exists (the incubation period)**. The promotion transition is the boundary that atomically removes `_incubation.md` and writes `_design.md`, so a sibling appears only *after* incubation ends, never *during* it (the binding window is the incubation period, not the whole promoted lifecycle).

### Edge / 정합 체크 (구현 시 lightweight 대조)
- **batch-3 정합**: swap("`_incubation`→`_design`")이 batch-3 "atomic promotion transition · E4=removal precondition"의 *정밀화*(그 "single changeset"이 무엇↔무엇 교체인지 고정) — 번복 아님.
- **lifecycle 정합**: entry artifact=`_design` 이 현 규칙 "Design→Plan→Spec"/"Design→Plan→rule" 진입과 일치.
- **E4-precondition 보존**: swap 시 entry artifact 로 *완전* 흡수, 나머지=정규 lifecycle carry(손실/raw 둘 다 아님).
- **atomicity 과적재 0**: 상태(promoted-but-not-live)는 5-B marker 소관; 5-K 는 Spec-identity time-phasing fallback 한 줄만.
- **5-D 정합**: K-1~K-3 가 5-D 의 Lifecycle invariant `_incubation` carve-out(*Incubation tier* governs `_incubation`)·Design decision-grade(E4 rejected-alternatives→Design)와 충돌 0.
- **retire**: closeout 시 이 5-K 노트도 함께 삭제.

## Phase-1 작업노트 — 5-B: promote-but-not-live 상태머신

> 5-B Plan 결정의 편집 대상 + 초안 방향(5-K/5-D landed 위에서). 정확 문구 = 구현 시 각 절 읽고 확정(5-D 원칙). final single-home = live rule.
> **★ 구현됨 + full-scope orchestration 정정.** 아래는 출발 방향이고 final = live rule. full-scope blind(5 라운드 수렴)가 잡은 정정: **rule/domain 비대칭 명시**(prelive=domain-Spec 전용; rule=`_design`/`_plan` active-lifecycle-work, terminal landing 까지 discoverable rule 아님) · de-promotion 이 prelive Spec 도 처분(E1 잔존 방지) · open-Q domain(backlog defer)/rule(pre-landing resolve) 분리 + neither-resolved-nor-deferred 만 block · prelive Spec 작성 시점 명확(전이=`_design`, Spec=이후 단계). **relay-B(judgment) → 5-E inputs(설계-robustness, 5-B 모델 밖 enforcement)**: ① rule 에 명시 lifecycle-state header field(현재 3-state 추론) ② withdrawal lineage 의무 field + re-promote gate ③ prelive Spec same-path 소비자 mechanical check ④ rule open-Q 를 rule 본문 non-goal/unsupported-boundary 로 닫는 옵션 ⑤ 통일 lifecycle header. (5-B=상태 모델 / 5-E=명시 marker·기계화.)

### 편집 대상 절 (`docs-working-model.md`)
| 편집 | 대상 절 | 종류 |
|---|---|---|
| B-1 | *Spec identity* lifecycle-state (현 live/sync-required) | add `prelive`(promoted-but-not-live) marker — 'blueprint' 형용사와 구분 |
| B-2 | *Incubation tier* E1 (discovery by promoted canonical artifact) | add 2층 — governance-discoverable(prelive 포함) vs implementation-authoritative(live only) |
| B-3 | *State migration* | add de-promotion = 기록된 `promotion-withdrawal`(incubation 재개 허용+marker; 무기록 rollback 금지; live 후 금지) |
| B-4 | *Incubation applicability* §Open / *Future-work queue* | open-Q routing: promotion 시 미해결 → backlog(있으면)/entry-artifact `Deferred Questions`(없으면); 미해결=live 차단 |
| B-5 | *E3* (transition-aware, 5-K 가 손댐) | rename-lineage 확장 — candidate/successor-id/rename-target; promotion changeset=source disposal+target creation 동일 changeset |
| B-6 | *Live-Spec update* (sync-required) | 정합 확인/1줄 — prelive(신규 domain 첫 Spec, closeout 전) ≠ sync-required(기존 live domain 갱신) |

### 초안 방향 (구현이 정확 문구 확정)
- **B-1**: Spec lifecycle-state marker 3종 = `prelive`(promoted, closeout 전, not-live — 신규 domain 첫 Spec) / `sync-required`(기존 live Spec in-place 갱신 후) / `live`(closeout 1:1). prelive 는 *Spec identity* 의 "writing-completion = blueprint of target state" 시점 상태에 이름을 준 것(형용사 'blueprint'는 그대로, 상태명은 prelive).
- **B-2**: E1 discovery 를 2층으로 — 모든 promoted canonical artifact(prelive 포함)는 *governance* 발견 대상(리뷰·lifecycle 추적)이나, *implementation authority*(behavior 의 1:1 근거)는 live/sync-required 만. 단순 발견이 live authority 로 오독되는 것 차단(5-K 의 filename↔authority 분리를 discovery 축으로 확장).
- **B-3**: de-promotion — promoted-but-not-live 를 되돌릴 때 = `promotion-withdrawal` changeset(기록). incubation 재개 *허용*(marker "restored from withdrawn promotion" 동반; candidate id 재사용 가능, history 보존). 무기록 silent rollback 금지. **live(closeout/terminal landing) 후엔 de-promotion 금지** — repeal/supersede(정상 lifecycle)만. (identity-monotonic 아님; 5-D 에서 retract 한 "candidate 부활 불가" 모델 계승.)
- **B-4**: promotion(swap) 시 미해결 incubation open-question → 도메인 `<domain>_backlog.md`(있으면, one-line+reopen condition 형식) / 없으면 entry-artifact(`_design`)의 `Deferred Questions` 절에 두고 Plan 때 backlog/tasks 로 흡수. **미해결 open-Q 존재 시 live 전환 차단**.
- **B-5**: E3 를 sibling-금지에서 lineage-금지로 — `_incubation` 존재 중 그 candidate·그 successor-id·rename-target *어디에도* `_design`/`_plan`/`_spec` 생성 금지; promotion transition 은 source `_incubation` disposal(또는 final-name rename)과 target `_design` creation 을 *같은 changeset*에 포함(rename 우회 차단; 5-K atomic-swap 보강).
- **B-6**: *Live-Spec update* 의 sync-required 가 *기존 live* domain 의 in-place 갱신 상태임을 유지하고, 신규 domain 첫 Spec 의 prelive 와 구분(별 칸) 1줄 명시.

### Edge / 정합 체크
- prelive ≠ 'blueprint' 형용사(Spec identity)·≠ sync-required(다른 칸).
- 2층 discovery 가 E1·*Final hard rule*(active-surface=authority)·5-K filename↔authority 와 정합.
- de-promotion=history-preservation 이 5-D retract·*State migration*(carried-over)·rule_docs purity(no archive)와 정합.
- open-Q routing 이 *Future-work queue* 형식(one-line+condition)·*Incubation applicability* §Open 소유권 이동과 정합.
- E3 lineage 가 5-K atomic-swap·*Stable filename rule*(rename) 과 정합.
- rule/domain 비대칭: rule 은 Spec 없어 marker 본체 = 3-state active(이미 존재); domain 만 Spec lifecycle-state marker 추가.
- single-home: 다른 절 재소유 0(각 면은 자기 절 — Spec identity/E1/State migration/Future-work queue).
- retire: closeout 시 이 5-B 노트도 함께 삭제.

## Phase-1 작업노트 — 5-E: enforcement (settled 모델 강제/게이트)

> 5-E Plan(batch-8) 승인결정을 line-level 편집 + 초안 + test 케이스로. round-scoped(승인 아님·Spec 대체 아님·실행기록 금지→log/). **rule/스크립트 미편집 — 구현이 이 초안을 다듬어 반영.** final single-home = live 산출물(check/checklists/template/rule). closeout 시 삭제.

### 편집 대상 (파일/절/라인 → 편집)
| ID | 대상 | tier | 편집 |
|---|---|---|---|
| EN-1 | `scripts/docs-working-model-check.ps1` `$canonicalFiles`(L164-171) + SCOPE INFO(L282) | MS | E2 scan 집합에 `snippets/rules/*.md` 추가 + SCOPE INFO 문구 갱신 |
| EN-2 | 같은 스크립트 — 신규 검사 블록 | MS | promoted domain `_spec.md` 의 Lifecycle-state marker *validity*(허용 token 정확히 하나) |
| EN-3 | `tests/docs-working-model-check.Tests.ps1` | MS | EN-1/EN-2 케이스 + 후보 newly-fail 0 회귀 |
| EN-4 | `checklists/docs-working-model_design_checklist.md` | SC | altitude/detail-flow 게이트 항목 |
| EN-5 | `checklists/docs-working-model_spec_checklist.md` | SC | Lifecycle-state 절 존재+marker validity 항목 |
| EN-6 | `checklists/docs-working-model_promotion_checklist.md`(신규) | SC | promotion-boundary/promoted-but-not-live 게이트 |
| EN-7 | `templates/docs-working-model_spec_template.md` | form | Lifecycle-state field = 'exactly one of prelive/sync-required/live' 명시(이미 3종 명명 — SC 검사가능하게) |
| EN-8 | `docs-working-model.md` Closeout Level 2 | PCG/R1 | terminal-rule Level-2 매핑 한 줄 |
| EN-9 | `docs-working-model.md` line 104 | rule-text/L104 | parenthetical disambiguation |
| EN-10 | `_design.md` Phase-1 roadmap 절 | (Plan-close) | deferred-enforcement 목록을 5-G/5-X/5-T 옆 follow-on 으로 추가(아래) |

### 초안 (구현이 다듬을 출발 — final = live 산출물)
- **EN-1 (E2 scope):** `$canonicalFiles` 에 `snippets/rules/` 의 `*.md` recursive 추가. `snippets/rules/README.md`(index)도 대상 적합(`rules/README` 동급). SCOPE INFO 의 "snippets/ … NOT mechanically scanned" → "snippets/rules/ 포함"으로 정정. **over-reach 금지**: 실제 durable `*_incubation.md` ref 만(기존 E2 discriminator·`$incTails` 매칭 그대로; snippets 파일도 같은 regex/tail 검사).
- **EN-2 (lifecycle-state marker validity) — ★ 회귀 확인 완료(scope 추가 불요):** 대상 = promoted domain Spec = `docs/<domain>/<domain>_spec.md`(incubation 후보 `docs/<cand>/` 는 `_spec.md` 없음 → 자동 제외 = **후보 conform-pass**). **현 repo 3개 live spec(review/install-update/brief) 전부 동일 marker-line 관례 사용 확인**: `## Lifecycle state` 절 + `- spec ↔ implementation: **live**`(marker 는 **bolded**), 그리고 같은 줄 plain prose 에 "sync-required 전이" 언급. → **검사 설계 = bolded marker token(`**prelive**`/`**sync-required**`/`**live**`) *정확히 하나*** (또는 `spec ↔ implementation: **X**` assertion line 파싱) — **plain-prose 언급은 marker 아님**(naive token-count 였으면 live+sync-required 2개로 오판했을 것). 위반 = 절 부재 / bolded marker 0 / 2+ / 비허용. **결과: 기존 3 spec 이미 conform(X=live), 수정 불요, newly-fail 0**(EN-7 template 이 이 marker-line 관례를 codify → 미래 spec 도 검사가능). **NSE 한계**: same-path 오소비는 *못 막음*(marker 존재·유효까지만).
- **EN-8 (R1, 한 문장 — 초과 시 split):** Closeout *Level 2* 에 추가: "For a `rule_docs` / terminal-rule change, the Level-2 surface is the **terminal rule file itself** (`rules/<id>/<id>.md` or `snippets/rules/<id>.md`), reconciled 1:1; a rule has no `<domain>_spec.md` / `<domain>_backlog.md`, so its open questions are resolved before the terminal rule lands (no backlog deferral)."
- **EN-9 (L104 disambiguation, meaning-preserving):** "The mechanical check for this model (`scripts/docs-working-model-check.ps1`)…" → "The mechanical check **for this conditional terminology-registration model** (the future terminology-registration check added to `scripts/docs-working-model-check.ps1`; the script's current structural E1/E2/E3 checks are 'rule requirements now' per *Form early, authority late* and are not transition-deferred)…". (dialectic 이 확인한 기존 의미 *명시화*; 새 의미 0.)
- **EN-4/5/6 (checklist 초안 방향, 의미 기준):**
  - EN-4 Design: "[ ] detail 이 Design altitude 를 넘지 않는가 — round/line-level 분석·execution mechanics·exhaustive enumeration·정확 marker/token·final normative wording 0(각자 WP/Spec/log); decision-grade(semantic target·trade-off·ownership·대표예시)만 — 충족/미충족+evidence"
  - EN-5 Spec: "[ ] Lifecycle state 절 존재 + marker 가 prelive/sync-required/live 중 *정확히 하나* — 충족/미충족+evidence"
  - EN-6 promotion(신규; promotion·discard·de-promotion/withdrawal event): "[ ] prelive Spec 을 live authority 로 소비 안 함(governance-discoverable≠implementation-authority) [ ] E4 흡수 완전(adopted/rejected-alts/evidence-type/scope/failure/negative → `_design`, never WP) [ ] 미해결 open-Q routed(domain backlog / rule pre-landing); neither→live 차단 [ ] de-promotion 시 promotion-withdrawal 기록(모든 promoted artifact 처분+marker; live 후 금지)"
- **EN-7 (template):** 이미 prelive/sync-required/live 명명(5-B corrective). 추가 = Lifecycle state 절 안내를 "exactly one of"로 명확(EN-5 가 검사).

### deferred-enforcement durable home — Plan-close (조사 결과)
후보: **(a)** rule 내 thin pointer → *3번째 rule-text 터치* = Plan "2건"·narrow-scope 와 충돌(scope-creep) → 기각. **(b)** closeout report = log/(gitignored) → durable 아님 → 기각(단독). **(c)** 새 rule-backlog mechanism → 과통합 → 기각.
→ **Plan-close = roadmap-listing**: deferred-enforcement 목록을 `_design.md` Phase-1 roadmap 의 5-G/5-X/5-T *옆* follow-on item 으로 둔다(EN-10). silent-drop 아님(roadmap 에 명시). durable 이전은 *cs1-closeout 의 roadmap-migration*(5-G/5-X/5-T 도 같은 운명 — 5-E 고유 부담 아닌 *기존 cs1 의무*). → **5-E 는 rule-text 2건 유지**(R1+L104). deferred 목록(요약) = durable-pointer 일반 scan · docs/ 도메인 purity/stable-filename · terminology state-machine(pending↔owner-pending·field-schema) · rejected-term cross-surface sweep · review-date staleness · WP-content checklist · **E3 cross-folder rename-lineage(known hard residual)** · E4/E5 semantic.

### Edge / 정합 (구현 시 확인)
- EN-2 가 *기존 live domain spec* newly-fail 0(위 회귀) — 후보 3종은 `_spec` 없어 자명, 기존 domain 은 확인 필수.
- EN-1 snippets scan 이 over-reach 0(실제 `_incubation` ref 만; snippets/rules 의 4파일엔 candidate ref 없음 → 현 repo PASS 유지).
- EN-8 R1 = 한 문장(초과 시 split — WP review 기준).
- EN-9 L104 = meaning-preserving(governs 대상 불변, 명시만).
- verify-ps1(BOM+CRLF) + full Pester + `docs-working-model-check` 현-repo PASS.
- **EN-6-wiring (canonical SC pass-01 corrective)**: 신규 promotion checklist 는 파일만 추가하면 죽은 deliverable — rule package 의 *manifest*(Package note `docs-working-model.md:5` 열거 + conformance gate forms-list `:202`) + *application trigger*(conformance gate `:200` 에 "promotion-boundary event 가 promotion checklist 통과")에 배선해야 EN-6 완성. descriptive routing(normative 신규 아님). rules/README.md 은 operative home 으로 라우팅만 하고 열거 안 함 → 미수정.
- retire: closeout 시 이 5-E 노트 삭제.

## batch-9 — 5-F Work Packet (enforcement-hardening; round-scoped)

> 5-F Plan(batch-9) settle 후. round-scoped 작업문서 — 편집대상 분류 + check 로직 *초안* + test 케이스 + WP-checklist 문구·배선 + GUARDED feasibility. **흡수 = 구현 / retire = closeout(이 5-F 노트 삭제).** 정확 final 코드는 구현 산출(이 WP 는 출발 초안). `.ps1` UTF-8 BOM+CRLF + verify-ps1 + full Pester.

### 독립 gap 인벤토리 (codex relay-A landscape + Claude 독립 lens 병합; Plan 이 WP 로 이연)
항목별 {rule locus · current check coverage · file:line}. (출처 = 이 세션 relay-A landscape 서브에이전트 + 내 독립 reading; 전수 대조됨.)
- **E2 precision**: rule `docs-working-model.md:107`(E2). check `docs-working-model-check.ps1:223`(`$incRefPattern`)·`:233`(`<`/`>` skip = angle-bracket FN)·`:181-187`(`$incTails`)·`:239-242`(tail EndsWith). regex 가 repo-relative 지향(drive-letter `C:/` 미매칭). tests `tests/docs-working-model-check.Tests.ps1`: normal-link/bare-token/dangling/same-leaf-other-folder 커버, **angle-link·drive-letter·base-tail 테스트 부재**.
- **docs/ purity**: rule `:175-176`(*Stable filename rule* — `<topic>_*.md`·`docs/<domain>/work/` 금지; auxiliary는 deferred=Design/Plan 승인 필요 — check는 승인 비-구조적(NSE)이라 role-name accept). check: rule_docs purity 로직 `:64-160`(docs/ 로 포팅 대상), docs/ 는 명시 looser `:85-86`. **discriminator = *promotion-entry*(`<domain>_{design,plan,spec}.md` 중 하나라도 존재)** — folder 순회는 EN-2 promoted-spec presence 패턴 `:303-308` 재사용하되, 검사대상은 spec-only 아닌 promotion-entry(mid-promotion 포함; spec-only는 under-enforce — 구현 relay-B/canonical SC 보정).
- **next-ID**: rule `:119-121`(one line `next ID: <PREFIX>-NN`, monotonic·삭제후 재사용 금지). 실 backlog: `docs/install-update/install-update_backlog.md:3`(multi-prefix `IU-B-14 · IU-D-12`)·rows `:11-30`(IU-B-*/IU-D- 분리). review/brief = single-prefix.
- **EN-2 fence**: check `:336-360`(fence char+length 추적, CommonMark-correct). tests `:592-633`(fenced-only/real+fenced/inner-delim) — **same-char *짧은* close-fence(긴 opener 미닫힘) edge 부재**.
- **durable-pointer**: rule `:45`(*Durable-pointer prohibition* — log/**·polishing/**·repo_snapshot/** 등 *전 committed doc*). check: E2 가 `_incubation` ref 만; 일반 durable scan 부재. discriminator 재사용 = E2 `:223/:233`.
- **rejected-term**: rule `:102`(rejected finalize 전 4-class all-surface sweep). glossary `terminology-glossary.md` *Rejected terms* section. check 부재.
- **WP-content**: rule `:76`(WP forbidden content). conformance gate `:198-202`(WP 미열거). checklist 부재(design/plan/spec/closeout/promotion).

### 편집대상 (FN-1~FN-9; surface · tier · sketch)
| id | surface | tier | sketch |
|---|---|---|---|
| **FN-1** | `docs-working-model-check.ps1` E2 | MS(rule-text 0) | angle-bracket link `[x](<path>)`: `:233` 의 무조건 `<`/`>` skip 을 *autolink/pointy-bracket destination* 만 벗겨 내부 path 를 incTails 대조(`<` 자체가 template placeholder `<candidate>` 와 구분 — placeholder 는 segment 내 `<...>`, link 는 `(<` … `>)` 형태). absolute/drive-letter: regex 에 `[A-Za-z]:[/\\]` 선두 허용 추가(단 incTails 는 여전히 tail-match). |
| **FN-2** | `docs-working-model-check.Tests.ps1` EN-2 | MS-test(rule-text 0) | 회귀: (a) ````~~~~```` 4-tilde opener 를 ```~~~``` 3-tilde 가 *안 닫음*, (b) ````` ```` ````` 4-backtick opener 를 ``` ``` ``` 3-backtick 미닫힘 — marker count 정확성 확인. |
| **FN-3** | `docs-working-model-check.ps1` 신규 docs-purity 절 | MS(rule-text 0) | rule_docs purity(`:64-160`) 형제 함수를 docs/ 로: **discriminator = *promotion-entry*(`<dir>/<dir>_{design,plan,spec}.md` 중 하나라도 존재; mid-promotion 포함 — spec-only는 mid-promotion `work/`-우회 under-enforce[구현 relay-B/canonical SC 보정])인 promoted 도메인만 binding**; 금지 = `<dir>/work/` subfolder · `<topic>_*.md`(domain-prefix 아닌 topic-named) · 비-role `<dir>_*.md`. **auxiliary role(`_policy/_contract/_state/_status/_guide`)은 *accept*** — 규칙 :176 상 deferred(Design/Plan 승인)이나 승인 여부는 비-구조적(NSE)이라 check 가 over-strict 금지 대신 accept(승인=manual/SC residual). in-flight 후보(`_incubation.md`만, planning 파일 없음)·legacy(planning 파일 없음) = 자동 conform-pass. allowed = README·`<dir>_{spec,backlog,design,plan,work_packet,incubation}.md`·auxiliary `<dir>_{policy,contract,state,status,guide}.md`. |
| **FN-4** | `checklists/docs-working-model_work_packet_checklist.md`(신규) | SC | *WP 파일 자체*만 게이트(5E-c2): "[ ] 실행 command sequence·staging·review/validation 결과·readiness 판정 0(→ log/**) [ ] line-level 분석·구현노트·evidence proposal·reviewer-Q prep 만 [ ] approval-target/normative-wording 0(→ Plan/Spec)". 의미게이트(presence 아님). |
| **FN-5** | `docs-working-model.md` Package note `:5` + conformance gate `:200/:202` | **bounded normative(1)** | (i) Package note `checklists/` 열거에 `_work_packet_checklist.md` 추가(descriptive) (ii) conformance gate `:200` 에 "a produced **Work Packet** must pass the work-packet checklist" 1문장(=RULE:137 validation-expectation 신설 → **bounded normative completion**; RULE:76 기존 boundary 의 기계화) (iii) forms-list `:202` 에 추가. **WP review 기준 = 이 1문장+열거 초과 시 split.** |
| **FN-6** | `docs-working-model-check.ps1` 신규 durable 절 | MS(GUARDED) | durable-pointer canonical-subset scan: canonical surfaces(E2 set) 에서 `log/`·`polishing/`·`repo_snapshot/` 등 gitignored-root 로의 durable path/link. **discriminator = E2 path-vs-concept 재사용(single-home)** — concrete-dir-segment 있는 실경로만, 개념언급(`log/**` in prose) 제외. **feasibility: prototype 가 FP 확인 — log/ 는 _incubation 보다 prose 빈도↑라 FP 위험; 미통과 시 SC 강등/defer.** |
| **FN-7** | `docs-working-model-check.ps1` 신규 next-ID 절 | MS(GUARDED) | floor check: backlog 헤더 `next ID:` 라인 파싱(`·` split → per-prefix `<PREFIX>-NN`), rows 에서 prefix 별 max id, **per-prefix next-ID > max present row id** 검증. **multi-prefix = per-prefix intent 일반화(RULE:121 단수 문구는 simplification — rule-text 무touch 우선; ack 필요 판정 시 hard boundary ① 의 2번째 bounded touch).** **feasibility: install-update multi-prefix 파싱 + review/brief single-prefix 둘 다 PASS 확인.** |
| **FN-8** | `docs-working-model-check.ps1` 또는 checklist | SC/MS(secondary-GUARDED) | rejected-term section-confinement: glossary *Rejected terms* heading token 이 그 section *밖*에서 heading/bolded(accepted-looking)로 재등장 금지. **feasibility: prose 언급(예 "X 를 rejected")과 accepted-looking 구분 FP 가 trivial 아니면 → SC checklist 로(MS 아님) 또는 defer.** |
| **FN-9** | `docs-working-model-check.Tests.ps1` | MS-test | FN-1(angle-link·drive-letter·base-tail fixtures)·FN-3(docs purity: promoted 위반/in-flight conform-pass/legacy conform-pass)·FN-6(durable FP/FN)·FN-7(multi+single prefix) 케이스 + 후보 newly-fail 0 회귀. |

### GUARDED feasibility — 구현-prototype 확정 (provisional)
- **FN-6 durable**: *조건부 IN* — E2 discriminator robust 재사용 가능하면 IN; prototype 가 canonical surfaces 에서 FP>0(prose 의 `log/` 등 오탐) 내면 → SC 강등 또는 defer. (relay-B: "canonical-subset"=의도적 부분, RULE:45 전체는 residual.)
- **FN-7 next-ID**: *IN 유력* — multi-prefix 파싱 단순(`·` split). rule-text 무touch(per-prefix intent) 우선; prototype 가 install-update+review+brief 셋 다 PASS 확인. RULE:121 ack 필요시에만 2번째 bounded touch(그 경우 WP review 재판정).
- **FN-8 rejected-term**: *DEFER 유력* — accepted-looking vs prose-mention 구분이 semantic 이라 MS FP 위험; SC checklist 항목(promotion/closeout 인접)으로 흡수하거나 차기 인벤토리로 defer. prototype 불요(설계 판단).

### Edge / 정합 (구현 시 확인)
- **newly-fail 0(전수)**: FN-3 docs purity 가 현 docs/ 도메인(brief/install-update/review = spec 보유 → binding; 셋 다 `<domain>_{role}` 관례 conform)·후보 2종(blind-advisory/consultation = spec 없음 → conform-pass)에 newly-fail 0. FN-1 over-reach 0(실제 candidate ref 만). FN-7 실 backlog 3종 PASS.
- **FN-5 bounded touch 격리**: rule-text 편집은 FN-5 의 1문장+열거뿐 — diff 가 초과 시 split(hard boundary ①). canonical 이 이 normative touch 집중 검토.
- **single-home(P0-2)**: FN-1 ↔ FN-6 discriminator 공유 → 한 helper(예 `Test-DurableCandidateRef`)로 single-home; FN-6 defer 시 FN-1 helper 를 재사용 가능 형태로.
- **5E-c2**: FN-4 WP-checklist 가 Plan checklist(WP 선언)·closeout(WP 흡수/삭제)·promotion(E4-not-WP)과 *다른 명제*(WP 파일 content) — 중복 owner-tier 0 확인.
- verify-ps1(BOM+CRLF) + full Pester(신규 케이스) + `docs-working-model-check` 현-repo PASS.
- retire: closeout 시 이 5-F 노트 삭제.
