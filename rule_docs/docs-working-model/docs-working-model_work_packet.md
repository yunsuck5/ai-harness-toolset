# docs-working-model Work Packet — G1+G2+G6-`:95` revision (회차성 분석)

> 회차성 작업 문서(non-authoritative·non-live·Spec 대체 아님). 승인 대상 결정은 Plan, normative wording 은 terminal rule 소관. closeout 시 삭제(git history 보존). (승인 경계 1회 진술.)

## 1. Track-3 gap landscape 요약 (조사 노트)

5-lens gap 조사(G1/G2/G6/G7)의 회차성 결론 — 이 revision 이 다루는 셋 + defer 둘:

- **G1**(다룸): 자기참조 governing-version 일반 조항 부재. 현존 = E5(`:112`)·backlog-bootstrap(`:128`) 특정 carve-out 2개; 일반 원칙은 세션-외에만. foundational(모든 self-revision 지배). DWM-B-10 은 하위 사례(bootstrap 문면-gap).
- **G2**(다룸): rule 본문 ↔ package implementation surface sync 미강제. 실측 재발 2건 — prelive marker(template-menu 누락)·rule-output-forms(check-script 로직). leaf-recurring; cheap 게이트 구조적 사각(cross-FILE).
- **G6 `:95`**(부분 다룸): live rename 절차 부재. `:95` = dangling assertion(folder-mechanic 만). full 절차는 defer.
- **G7**(defer): candidate merge/rehome 부재. not-yet-hit(near-miss=consultation·blind-advisory collision-note 분리유지). G6↔G7 = identity-change sweep primitive 공유(단 authority-state 갈림 → 별도 조항).
- **G6-full·G7 defer 근거**: 미밟힌 edge; 공유 primitive 추출은 실제 설계 시 판단(과통합 방지).

## 2. form-bound surface-mapping (evidence 제안 — Plan R2 목록의 surface 대응)

각 form-bound 진술 클래스 ↔ 그것을 embody/enforce 하는 package surface(어느 것이 없으면 규칙 의미 미구현):

| form-bound 진술 클래스 | embody surface(form) | enforce surface(validation) |
|---|---|---|
| Spec-identity 8-section 열거(`:69`) | spec template headings | cheap check(신설·template-menu) |
| lifecycle-marker 셋(`:67`) | spec template markers | EN-2(produced spec·정확히 1) + cheap check(template·all-3) |
| rule-output-forms(nested/flat/snippet) | — | check.ps1 `:234-238`(3형태 감지) + closeout checklist rule-output 항목 |
| artifact content-boundary "must not contain" | Design/Plan/Spec/WP checklists | (checklist meaning-test) |
| checklist-tested 의무 | 각 checklist item | (conformance gate `:205-210`) |
| backlog 구조 불변식(next-ID·row-deletion) | — | BACKLOG-NEXTID check |
| rule_docs purity·naming | — | RULE_DOCS-PURITY/ORPHAN/CANDIDATE-BACKLOG |
| E1–E3·EN-2 구조요건 | — | check.ps1 E1/E2/E3/EN-2 블록 |

- 관찰: 일부 클래스는 embody-form 이 없고 enforce-check 만 있다(rule-output·backlog·purity·E1-E3) — G2 의 "package implementation surfaces" 상위어가 forms+validation 둘 다 포함해야 하는 이유(Plan hard boundary `:209`).
- Direction-2(orphan form-element→normative sentence) 는 위 표의 역방향 — 기계화 아닌 closeout process 의무(Plan validation).

## 3. edit-target reference 분류 (line-level·sibling-sweep)

touch 예상 rule/파일 라인(Stage-2 저작 시 대조용):
- **SC-G1**: 신규 절(`## State migration` `:174-178` 인접) + `:112`(E5 인스턴스-pointer) + `:128`(backlog 인스턴스-pointer + "mirrors E5" `:128` 내부 re-point) + `:106`(see-also·무편집). sibling-sweep: E5·backlog 의 "not a precedent" 문면 보존 확인; `:128` "mirrors E5" 는 유일 교차참조(grep 확인 필요).
- **SC-G2**: `:150-155`(closeout Level-2 listed-surface) + `:205-210`(conformance-gate 역방향) + check.ps1(신설 블록 + SCOPE INFO `:865` + PASS/FAIL 태그 `:888/:892`) + `tests/docs-working-model-check.Tests.ps1`(신설 케이스). sibling-sweep: closeout checklist(`:13` item-8 계열)·SCOPE INFO 열거의 형제 desync 대조.
- **SC-`:95`**: `:95` rename half + deletion half(동일 문장 두 절). sibling-sweep: `:126`(backlog/folder deletion 조건)·RULE_DOCS-ORPHAN 와의 정합.
- **backlog**: DWM-B-10 행 삭제 + G6-full·G7 행 신설 + next-ID `DWM-B-12`→진행. 
- **closeout checklist**: G1 governing-version 항목 + G2 sync 항목 신설.

## 4. edge-case 노트

- **(I)/(III) seam 해소**: cheap 구조검사가 이 changeset 에서 실행돼도 invariant I 무충돌 — 검사 대상이 *pre-amendment* 구조 fact(`:69/:67`, 불변식 II 상수)라 pre-amendment 텍스트가 지배; self-applied 신규 머신 아님. `:106-107` 즉시-binding 구조검사와 동형(governance-version defer 와 별개 축).
- **`:176` seriality**: "이 changeset 이후 시작 revision"의 well-definedness 는 State migration same-role-slot 선행-disposition(seriality 강제)에 의존; 타 role-slot 병렬 revision 은 docs-working-model 자기 governing-version 미접촉.
- **EN-2 non-collision**: cheap check(template path·all-3 marker) vs EN-2(produced `docs/<domain>/<domain>_spec.md`·정확히 1) = 다른 target·역극성; template 은 `rules/.../templates/` 라 EN-2 scan 밖. fixture 를 `docs/<domain>/` 에 두면 EN-2 촉발(주의).
- **cheap-check 커버리지 경계**: prelive-급 재발(template-menu marker 누락, `09aced5`)=커버 / rule-output-forms 재발(check-script 로직, `c2574bd` flat-form)=미커버(그건 process 의무). 정직 표기.
- **RULE_DOCS-ORPHAN guard**: `:95` folder/no-orphan 의무는 script `:280-282`(+state-independent guard `:250-252`)로 기계집행 중 — `:95` 명확화가 이를 약화하면 live check 와 desync.
- **spec template 는 E2 recursive scan(`rules/**`) 안**(SCOPE INFO): 신설 cheap check 는 template path 만·docs/** 재스캔 금지.

## 5. reviewer-question 준비 (Stage-2 dual-blind + canonical)

Stage-2 게이트에 던질 질문(저작 후):
- **G1**: self-reference hole 닫혔나(changeset-through-closeout·`:176`)? genus 과-일반화? `:112/:128` "not a precedent" 문면 보존? governing-version 축이 `:106-107` 즉시-binding 과 교차 안 하나?
- **G2**: `:20/:210` authority 경계 유지(rule 이 surface 지배 주장 0)? "forms" 용어가 `:209`(templates/checklists)와 정합? cheap check 가 EN-2 촉발/중복? form-bound 목록 under/over-inclusion? 신설출력↔기존 negative-assertion 충돌(자초-회귀)?
- **`:95`**: meaning-preserving 성립(의무 미신설·미약화)? 두 half 대칭? RULE_DOCS-ORPHAN 의무 intact? backlog pointer item-ID 미복사?
- **cross**: DWM-B-10 literal 문면-gap 해소(추상 아님)? next-ID monotonic? mechanical-green 전량(full Pester·verify-ps1·check)?
