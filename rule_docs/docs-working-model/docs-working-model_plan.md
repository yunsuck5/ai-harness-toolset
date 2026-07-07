# docs-working-model Plan — G1 governing-version + G2 rule↔package 1:1 sync + G6 `:95` clarification

## Header

이 문서는 위 Design 의 **approval-target 결정 Plan** 이다 — G1(self-revision governing-version)·G2(rule↔package-implementation 1:1 sync)·G6(`:95` scope 명확화)를 한 changeset 으로 landing 하는 결정.
이 체인이 끝나면 terminal rule + package(check/tests/closeout-checklist) + backlog 가 세 sub-change 를 담고, 이 Plan·Design·WP 는 retire(삭제).
이 문서가 아닌 것: 조사 로그·surface-mapping·edit 분류(→ WP)·실행 순서/기록(→ operator report `log/**`)·normative rule wording(→ terminal rule)이 아니며, mutation/commit/push 승인이 아니다(1회 진술).

## Batch 순서와 의존

- **단일 changeset(one revision), 3 approval-target sub-change**: (SC-G1) governing-version · (SC-G2) rule↔package 1:1 sync · (SC-`:95`) `:95` scope 명확화.
- **분리 안 함(결정)**: 셋 다 rule 자기-거버넌스로 cohesive; invariant-I seam(cheap check 가 이 changeset 에서 실행됨)은 *해소됨* — cheap check 는 pre-amendment 구조 fact(`:69/:67`, 불변식 II 상수)를 검사하므로 pre-amendment 텍스트가 지배(self-applied 신규 머신 아님) — 이라 G1 을 별도 선행 changeset 으로 쪼갤 이득이 closeout 중복 비용을 넘지 않는다.
- **의존**: SC-G1 이 meta-frame(이 changeset 전체를 pre-amendment 텍스트가 지배 — invariant I); SC-G2·SC-`:95` 는 그 아래 landing. SC 간 상호 hard 의존 없음(각 독립 approval-target).
- **지배 버전(불변)**: 이 changeset 전체(자기 closeout 포함)는 pre-amendment 규칙 텍스트가 지배; 새 조항은 이 changeset *이후 시작* revision 부터(seriality = `:176`).

## Batch 정의

### SC-G1 — governing-version
- **목적**: 규칙 자기-개정의 지배 버전을 일반 조항으로 명문화(현 E5·backlog 특정 carve-out 만; 일반 원칙은 세션-외에만).
- **scope(다루는 것)**: 신규 조항(genus "transitional applicability of a newly-introduced governance mechanism" + governing-version 인스턴스) + E5 `:112`·backlog `:128` 에 meaning-preserving 인스턴스-pointer + backlog "mirrors E5" re-point + `:106` 를 supporting isomorphic 인스턴스로 see-also. **(다루지 않는 것)**: E5/backlog 실질 재작성·`:106` re-point·기계검사.
- **hard boundary(불가침)**: E5/backlog mechanism-specific 실질 + "not a precedent"(`:112/:128`) 문면; closeout gate 구조.
- **validation expectation**: 조항이 governing unit=changeset 전체(자기 closeout 포함) 명시; `:106-107` 즉시-binding 축과 교차 안 함(R6); E5/backlog 실질 보존(diff 로 pointer-only 확인).
- **review focus**: self-reference hole · 과병합 · `:112/:128` 보존.

### SC-G2 — rule↔package-implementation 1:1 sync
- **목적**: rule 본문 form-bound 진술 변경 시 package implementation surface 1:1 정합을 closeout 게이트로 강제(현 미강제·실측 2회 재발·매번 최비용 canonical 만 포착).
- **scope(다루는 것)**: closeout Level-2 listed-surface 집합 확장(구조 불변) + conformance-gate 역방향 문장 + cheap 구조검사 1블록(spec-template 8-heading+3-marker·template-path 한정·즉시-binding) + tests + SCOPE INFO/PASS-FAIL 태그. **(다루지 않는 것)**: full semantic 등가 검사기·Direction-2 기계화·gate 구조 변경.
- **form-bound 닫힌 목록(결정·R2)**: { Spec-identity 8-section 열거(`:69`) / lifecycle-marker 셋(`:67`) / rule-output-forms 열거(nested·flat·snippet) / 각 artifact content-boundary "must not contain" 조항 / checklist-tested 의무 / backlog 구조 불변식(next-ID·row-deletion) / rule_docs purity·naming / E1–E3·EN-2 구조요건 }. 이 중 하나를 건드리는 rule 변경 = 대응 package surface(template/checklist/check/test) 를 같은 changeset 에서 정합할 의무. (각 항목의 surface-mapping = WP.)
- **hard boundary**: `:20/:210`(active surface owns behavior — rule 이 surface authority 주장 금지) · `:207`(checklist=meaning) · `:209`("forms"=templates/checklists 용어 고정) · EN-2 territory(produced spec) · `:132`(prose-mirror 금지).
- **validation expectation**: G2 문구가 embodiment(sync 대상) vs behavior-ownership 구분 명시; cheap check 는 template-path 한정·EN-2 비촉발·mechanical-green(full Pester 전량 green); 신설출력↔기존 negative-assertion 전수 대조; Direction-2(orphan form-element)는 closeout process 의무로 커버.
- **review focus**: `:20/:210` authority 경계 · EN-2 충돌 · 자초-회귀(신설출력↔단언).

### SC-`:95` — scope clarification
- **목적**: `:95` dangling assertion 오독("폴더만 바꾸면 됨") 방지.
- **scope(다루는 것)**: `:95` rename·deletion 두 half 대칭 scope-pointer(folder-step-only·전체 절차 future-work) + 개념 future-work pointer(item-ID 없이 `:71`). **(다루지 않는 것)**: G6-full 절차·insufficiency-boundary 신설·folder/no-orphan 의무 약화.
- **hard boundary**: RULE_DOCS-ORPHAN(`:280-282`)이 강제하는 folder/no-orphan 의무 binding 유지 · `:71`.
- **validation expectation**: 명확화가 folder 의무 미약화(RULE_DOCS-ORPHAN 와 desync 0); backlog pointer item-ID 미복사; 두 half 대칭.
- **review focus**: meaning-preserving 성립 · sibling-desync.

### 공용 Work Packet 선언 (3요소)
- **목적**: 이 revision 의 회차성 분석 home — Track-3 gap landscape 요약 · form-bound surface-mapping(어느 rule 진술 ↔ 어느 check/template/checklist) · edit-target reference 분류(touch 되는 rule 라인 · sibling-sweep) · edge-case 노트(seam · `:176` · EN-2 · cheap-check 경계).
- **흡수 대상**: 회차성 분석이라 canonical 흡수 대상 없음(결정은 Plan/rule 이 소유); closeout 시 삭제.
- **retire 조건**: promoted-lifecycle closeout 에서 삭제(git history 보존).

## Open decision 의 close 지점

- **R1**(배치·genus label·`:106` see-also) — **이 Plan 이 닫음**(SC-G1: 신규 전용 절 `## 규칙 자기개정 — transitional applicability + governing version`, `## State migration` 인접[seriality 근접]; genus = 3 인스턴스 governing-version·E5·backlog + supporting `:106`; 각 인스턴스 "자기 고유 carve-out 필요·동형이지 precedent 아님").
- **R2**(form-bound 닫힌 목록) — **이 Plan 이 닫음**(SC-G2 목록; surface-mapping=WP).
- **R3**(cheap 검사 hermeticity·negative-assertion·SCOPE INFO) — Stage-2 구현 + mechanical-green.
- **R4**(G6-full·G7·sweep-primitive) — 이 revision 밖 backlog 행(reopen trigger = 실제 rename/merge·rehome 필요 or DWM-B-09 promotion 임박; G7↔DWM-B-05 중첩 명기).
- **R5**(검증 비례) — Stage-2 게이트: dual-blind + canonical dual; `:95` proportionality-level.
- **R6**(G1 축 ↔ `:106-107` timing) — **이 Plan 이 닫음**: 두 축 분리 명문(governing-version=지배 *버전* / `:106-107`=구조검사 *즉시-binding*); rule text 에서 교차 표현 금지.
- **R7**(DWM-B-10 close) — closeout: `:128` 편집이 그 literal 문면-gap("later revision 이 도입 revision 자기 closeout 을 덮나") 해소 확인 시 close(추상 pointer 만으로 부분-close 금지).

## Stage rewind 조건

- 이 Plan 이 Design end-state/경계/결정 위반 → stop · Design 재설계 · Plan 재시작.
- 하위 rule text(Stage 2)가 이 Plan 위반(예: form-bound 목록 초과 · gate 구조 변경 · listed-surface 아닌 structure 변경) → stop · 재-plan.
- 구현이 rule boundary 초과(예: G6-full 로 scope 확장 · `:210` authority 주장 · E5 실질 재작성) → stop · 사용자 확인(scope 무단 확장 금지).
