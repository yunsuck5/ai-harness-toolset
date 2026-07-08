# consultation Work Packet

> 회차성 작업 문서 — line-level reference 분류·조사/구현 노트·evidence 제안·edge-case 노트. **승인 대상 아님·live domain 문서 아님·Spec 대체 아님.** 금지 content: 실행 command sequence·staging 절차·review 결과·validation 결과·readiness 판정(이들은 operator report `log/**` 또는 미기록). promoted-lifecycle closeout 시 삭제.

## sibling-mention sweep 대상 인벤토리 (조사 — 실행 결과 아님)

promotion transition 이 같은 changeset 에서 sweep 해야 할 consultation 이름-참조의 *위치*(무엇을 checked/updated 할지의 대상 목록; 실제 실행 보고는 closeout report 소관):

- **glossary `rules/terminology-glossary.md`** — consultation 소유 pending 예약 5개 위치: `consultation` · `operator synthesis` · `consultation status vocabulary` · `독립 의견` · `재조율`(전부 `pending` = finalization-owner 미-live → promote 시 pending 유지가 규칙상 정당; finalize 금지).
- **형제 후보의 consultation 이름-참조** — `blind-advisory` 예약이 consultation 을 이름-참조: `not-this = not consultation` · `collision-note = Potential collision with consultation status vocabulary`. contrast/collision 성격이라 promote 후에도 유효(대개 checked—no-change 후보이나 판정은 closeout).
- **`docs/README.md` §5 · `rules/README.md`** — consultation 참조 0(sweep 대상 없음; E1 claim 유지).

## 원자적 swap 검증 노트

- 원자적 swap 의 baseline 대조(검증용 스냅샷 — 실행 결과·시점성 상태 판정 아님): pre-swap committed baseline = `consultation_incubation.md` 단일. 이 changeset(swap 후) committed 상태 = `_design`/`_plan`/`_spec`/`_work_packet`(incubation 삭제).
- closeout commit 이 같은 changeset 에서 `consultation_incubation.md` 삭제 + `_design`/`_plan`/`_spec` 작성을 수행해야 E3 non-coexistence(committed state) 충족 — swap atomicity 는 commit 단위(working tree 중간 공존은 uncommitted 라 무관).

## incubation → design E4 대조 대상 (조사 — 흡수 *결과* 는 closeout report 소관)

closeout 의 E4 흡수-완결 확인이 대조할 *대상 목록*(무엇을 design 어느 위치와 맞대는지; 확인 결과·판정은 여기 적지 않고 closeout report 로):
- E4 6요소(adopted conclusion / rejected alternatives / evidence type / scope / failure criteria / negative evidence) ↔ design 대응 위치.
- loop-state closed 값집합(`needs_reply`/`converged`/`human_residual`) ↔ design E4①.
- [실측 검증] inline 판단 · [stale] 기각 · 7 discard 기준 · 정밀구분 4쌍 ↔ design 대응 절.

## Spec 저작 인수 항목 (Design 이 Spec 으로 위임한 것 — 저작 시 참조)

Spec 저작 시 명세할 대상(Design 이 "Spec 소유"로 defer 한 것):
- operation 2축·loop state·status vocabulary·packaging 의 **운용 MUST·필드 위치/이름·round-by-round loop 제어**(값집합·정체성은 Design 확정, 전이 규칙은 Spec).
- read-only escalation 의 구체 절차.
- secret/redaction 최소 원칙의 Spec 명세(세부 구현은 Deferred).
- consultation 종료 조건의 loop 제어 MUST(어느 조건→어느 상태).
