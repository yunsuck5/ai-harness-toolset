# docs-working-model — backlog (future-work queue)

next ID: DWM-B-15

docs-working-model 규칙의 non-authoritative future-work queue — 아직 착수하지 않은 작업을 한 줄 + reopen/start 조건으로 담는다. spec-of-record 는 `rules/docs-working-model/docs-working-model.md`(rule 은 자기 자신이 spec-of-record). 어느 row 도 구현 승인이 아니다 — 각각 별도 scoped Design→Plan + review gate 가 필요하다. 닫힌 row 는 기본 삭제한다(보존 = git history). cs1(개정) 착수 시점의 상세 근거는 retire 된 `_design`/`_plan`/`_work_packet` 의 git history 에 보존된다.

## Open rows

| ID | Row (one line) | Reopen / start condition |
|---|---|---|
| DWM-B-01 | `_incubation`-only E2 durable-reference scan 을 일반 *Durable-pointer prohibition* scan(`log/**`·`polishing/**`·`repo_snapshot/**`)으로 확장 — 공유 path-vs-concept discriminator 재사용 | 공유 discriminator 가 `log/`-빈번 산문에서 FP-robust 로 입증될 때(check helper 가 이미 "reusable by any future durable-pointer scan" 표시) |
| DWM-B-02 | transition-aware terminology-registration check(pending↔owner-pending 전이·field-schema·monotonicity) 구현 | 5-G 로 unblocked; 각 candidate 의 realigning changeset(cs2)에서 transition-aware 로 착수(rule 의 "future terminology-registration check" 조항) |
| DWM-B-03 | `Rejected terms` heading token 이 그 glossary 섹션 밖에서 accepted-looking 으로 재등장하지 못하게 하는 check/SC-gate 추가 | accepted-looking-vs-prose discriminator 가 기계검사로 trivial 하거나 SC checklist item 으로 흡수 가능해질 때 |
| DWM-B-04 | "candidate 가 새 review-date 없이 review-date 경과" 를 SC/PCG(non-MS) gate 로 추가 | checklist/process gate 로만 landing(wall-clock 비-hermetic → 기계검사 금지, 5F-c2 hermeticity bar) |
| DWM-B-05 | E3 lineage(rename-evasion)를 폴더 간 enforce — promotion-checklist PCG-assertion 또는 machine-readable lineage-field | lineage-field 가 설계되거나 PCG-assertion 이 scoped 될 때(현 check 는 same-folder sibling 만 봄; 5F-R5) |
| DWM-B-06 | 차기 enforcement 인벤토리 기계화 검토 — single-home-dup · lifecycle-altitude · 1:1-sync · cross-domain-semantics · domain-local-closure · state-migration · no-mirror · authoring-language · proportionality-abuse-guard · incubation-admission-completeness · 5-X sibling-reference form | 5-F 이후 별도 enforcement-hardening pass(대부분 SC/NSE) |
| DWM-B-07 | universal-core↔project-residue split-check 기계화(5-T 판별축; 5-T 모델 자체는 landed·check 불변) | distribution-tier landing 이 기계적 split gate 를 요할 때(DWM-B-06 과 overlap) |
| DWM-B-08 | "project layer may strengthen, not weaken" 를 rules-tier 원칙으로 일반화 검토(현 out-of-scope·new-normative·미입증 need; 5T-R5) | 실제 adopter-side override-conflict 사례가 발생할 때 |
| DWM-B-09 | 세 candidate 를 **consultation → blind-advisory → subagent-work-orchestration** 순으로 promote(순서 + 근거 carry; O 가 구조적으로 마지막 — distribution-tier self-containment·open-Q 성숙·5-T 선행) | Phase-2 per-candidate readiness; 순서 재결정은 recorded Plan-level trigger 에서만(O 의 open-Q 해소 / consultation·blind-advisory 중 discard / user 명시 재결정 — 5X-R4) |
| DWM-B-11 | 현행 minimal-guardrail incubation-applicability 또는 incremental glossary pending/owner-pending 모델이 실사용에서 불충분으로 판명되면 cs1 이 scope-creep 으로 deferred 한 *완전 apply/relax matrix 정식화* 및 *glossary lifecycle 전면 first-class 재구조화* 재검토(근거 = cs1 `_design` non-goals, git history) | minimal 모델이 실사용에서 불충분함이 실증될 때 |
| DWM-B-12 | live domain/rule rename·deletion 의 *전체 절차*(whole-surface 4-class reference sweep·backlog-prefix 처분·old-identity tombstone 여부·terminal-rule/spec path 이동·glossary term 재귀속) — G7(DWM-B-13)과 identity-change sweep primitive 공유하되 authority-state 별 별도 조항. 이번 revision 은 `:95` 의 folder-step scope 만 명확화 | 실제 live rename/deletion 이 필요해질 때(현재 미밟힘) 또는 DWM-B-09 promotion 임박 시 |
| DWM-B-13 | candidate identity/kind transition — two-candidate merge·rehome(rule↔domain kind-change·id/category 이동)·split·rename-before-promotion 의 lineage(E4 corpus·candidate 정체성) 보존 경로(현 유일 경로 = discard+re-incubate 로 lineage 유실) | 실제 merge/rehome 이 필요해질 때(현재 미밟힘·near-miss = consultation/blind-advisory collision-note 분리유지) 또는 DWM-B-09 promotion 임박 시. G6(DWM-B-12)과 sweep primitive 공유(authority-state 갈림 → 별도 조항)·DWM-B-05(cross-folder E3 lineage)와 중첩 |
| DWM-B-14 | 배포된 promoted-but-not-live implementation 의 소비자-가시 상태 표시 장치 검토(현행 = 표시 없음, E1 명확화의 수용 리스크) | 실전에서 prelive/live 구분 부재가 소비 측 문제를 실제로 일으킬 때 |
