# docs-working-model — backlog (future-work queue)

next ID: DWM-B-20

docs-working-model 규칙의 non-authoritative future-work queue — 아직 착수하지 않은 작업을 한 줄 + reopen/start 조건으로 담는다. spec-of-record 는 `rules/docs-working-model/docs-working-model.md`(rule 은 자기 자신이 spec-of-record). 어느 row 도 구현 승인이 아니다 — 각각 별도 scoped Design→Plan + review gate 가 필요하다. 닫힌 row 는 기본 삭제한다(보존 = git history). cs1(개정) 착수 시점의 상세 근거는 retire 된 `_design`/`_plan`/`_work_packet` 의 git history 에 보존된다.

## Open rows

| ID | Row (one line) | Reopen / start condition |
|---|---|---|
| DWM-B-01 | *Durable-pointer prohibition*의 일반 기계화 가능성 재검토 — 현재 glossary를 포함한 산문 경계는 semantic review가 소유 | 서로 다른 canonical surface에서 같은 위반이 반복 관측되고 concrete path와 path class를 안정적으로 가르는 결정 가능한 predicate가 counterexample corpus에서 입증될 때 |
| DWM-B-04 | "candidate 가 새 review-date 없이 review-date 경과" 를 SC/PCG(non-MS) gate 로 추가 | checklist/process gate 로만 landing(wall-clock 비-hermetic → 기계검사 금지, 5F-c2 hermeticity bar) |
| DWM-B-05 | E3 lineage(rename-evasion)를 폴더 간 enforce — promotion-checklist PCG-assertion 또는 machine-readable lineage-field | lineage-field 가 설계되거나 PCG-assertion 이 scoped 될 때(현 check 는 same-folder sibling 만 봄; 5F-R5) |
| DWM-B-07 | universal-core↔project-residue split-check 기계화(5-T 판별축; 5-T 모델 자체는 landed·check 불변) | distribution-tier landing 이 기계적 split gate 를 요할 때 |
| DWM-B-08 | "project layer may strengthen, not weaken" 를 rules-tier 원칙으로 일반화 검토(현 out-of-scope·new-normative·미입증 need; 5T-R5) | 실제 adopter-side override-conflict 사례가 발생할 때 |
| DWM-B-12 | live domain/rule rename·deletion 의 *전체 절차*(whole-surface 4-class reference sweep·backlog-prefix 처분·old-identity tombstone 여부·terminal-rule/spec path 이동·glossary term 재귀속) — G7(DWM-B-13)과 identity-change sweep primitive 공유하되 authority-state 별 별도 조항. 이번 revision 은 `:95` 의 folder-step scope 만 명확화 | 실제 live rename/deletion 또는 candidate promotion이 이 절차를 요구할 때 |
| DWM-B-13 | candidate identity/kind transition — two-candidate merge·rehome(rule↔domain kind-change·id/category 이동)·split·rename-before-promotion 의 lineage(E4 corpus·candidate 정체성) 보존 경로(현 유일 경로 = discard+re-incubate 로 lineage 유실) | 실제 merge/rehome 또는 promotion 전 identity change가 필요할 때. G6(DWM-B-12)과 sweep primitive 공유(authority-state 갈림 → 별도 조항)·DWM-B-05(cross-folder E3 lineage)와 중첩 |
| DWM-B-14 | 배포된 promoted-but-not-live implementation 의 소비자-가시 상태 표시 장치 검토(현행 = 표시 없음, E1 명확화의 수용 리스크) | 실전에서 prelive/live 구분 부재가 소비 측 문제를 실제로 일으킬 때 |
| DWM-B-15 | E1의 rule-kind 적용 충분성 재평가 — rule candidate의 promoted-but-not-live Design/Plan을 terminal-rule authority나 domain runtime-landing 대상으로 오분류하지 않는지 점검 | `subagent-work-orchestration` rule promotion의 Plan을 terminal-rule landing 전에 승인 대상으로 review할 때 |
| DWM-B-17 | 새로 작성하거나 의미를 실질적으로 다시 쓰는 repo 내부 human-facing prose의 한국어 기본 authoring policy를 교체·완화할지 재검토 | 한국어 규범 문면의 해석 분산 사고가 반복 관측되거나, 외부 협업자/타 벤더 agent의 repo 내부 human-facing prose 직접 소비에서 언어 해석 차이로 인한 정정·운용 실패가 실제로 관측될 때 |
| DWM-B-18 | `DOCS-PURITY`의 promoted-entry 한정을 재검토하고, incubation candidate 폴더의 추가 파일·subfolder가 owner split이나 lifecycle 은닉을 만드는지 같은 purity gate에서 판별 | 다음 docs-side candidate의 realign/promotion에서 추가 파일·subfolder가 생기거나, incubation 자유벽과 purity 위반을 구분하는 결정 가능한 predicate·반례 corpus가 준비될 때 |
| DWM-B-19 | `docs/<candidate>/` 폴더 ID와 `<candidate>_incubation.md` filename identity 불일치를 기계 검출할지 검토 — 현재 docs-side candidate discovery는 임의 `*_incubation.md`를 수용 | docs-side candidate를 새로 등록·rename·rehome하거나, folder/file ID mismatch를 재현하는 fixture와 template/concept 이름을 오탐하지 않는 predicate가 준비될 때 |
