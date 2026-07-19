# rule-authority Plan

> 이 Plan은 현재 `rule-authority` lifecycle 재수용의 승인 대상 결정을 담는 임시 문서다. terminal rule을 재설계하지 않으며, current-bearing 내용의 owner 대조가 끝난 closeout에서 삭제한다. 이 문서는 mutation/commit/push 승인이 아니다.

## Header

- 이 문서는 누락된 per-rule lifecycle home을 현재 상태에서 재수용하고 idle 상태로 닫는 Plan이다.
- 이 체인이 끝나면 terminal rule·routing 경계가 재확인되고, planning folder와 future-work queue가 남는다.
- 이 문서는 과거 저작 기록, 최종 normative wording, 실행 기록 또는 다른 규칙의 수정 계획이 아니다.

## Batch 순서와 의존

1. **현재 의미 대조:** Design의 owner model을 terminal rule, root routing, rules index, 인접 conflict-routing rule과 대조한다. terminal rule 결함이 발견되면 closeout하지 않고 중단한다.
2. **lifecycle closeout:** 대조에서 terminal rule 변경이 불필요한 경우, 아직 시작하지 않은 상류 절차 후보만 backlog에 남기고 Design/Plan을 retire해 folder를 idle 상태로 전환한다.

두 batch는 terminal-rule 재설계가 이번 corrective에 조용히 유입되는 것을 막기 위해 순서를 고정한다. Work Packet은 필요하지 않다. exact surface 분석이 작고 Design/Plan과 terminal owner 대조만으로 닫히며, 별도 round-scoped 조사 산출물이 없다.

승인 owner는 사용자다. 이 Plan의 결정은 하위 lifecycle 대조 범위만 정하며, terminal rule 변경이나 commit 권한을 부여하지 않는다.

## Batch 정의

### 현재 의미 대조

- **목적:** 현행 terminal rule이 권위 자격·등급·처분을 자족적으로 소유하고 routing 및 인접 rule이 그 의미를 침범하지 않는지 확인.
- **scope:** `rules/rule-authority.md`, root 두 routing row, `rules/README.md`, `rule-conflict-and-revision-routing`의 owner 경계. 새 normative 문면 저작은 제외.
- **hard boundary:** terminal rule이나 routing을 편의상 수정하지 않는다. managed-block/parity/GFM 표면과 다른 rule lifecycle은 건드리지 않는다.
- **validation expectation:** terminal rule 의미가 Design의 semantic target을 충족하고, routing은 read-first pointer이며, 인접 rule은 conflict transport에 한정된다.
- **review focus:** owner 중복, terminal defect의 무단 흡수, 과거 lifecycle 사후 위장.

### lifecycle closeout

- **목적:** current-bearing 의미를 terminal rule과 backlog에 1:1로 귀속하고 per-rule folder를 유효한 idle 상태로 남김.
- **scope:** Design/Plan 삭제, `.gitkeep`, `rule-authority_backlog.md`의 next-ID와 한 개 future-work row.
- **hard boundary:** backlog 행을 구현 승인이나 현재 rule 의미로 소비하지 않는다. terminal rule·routing·glossary는 변경하지 않는다.
- **validation expectation:** folder에는 `.gitkeep`과 backlog만 남고, backlog는 단조 next-ID와 reopen/start condition을 갖는다. DWM 구조 검사와 전체 repo 검증이 통과한다.
- **review focus:** planning 문서에만 남은 고유 의미, backlog scope creep, idle-folder purity.

## Open decision의 close 지점

- terminal rule이 현 Design을 충족하는지는 첫 batch에서 대조해 닫는다. 불충족이면 이 Plan으로 교정하지 않고 중단한다.
- 상류 사전 절차를 terminal rule에 흡수할지는 이번에 닫지 않는다. 별도 scoped lifecycle을 시작할 조건과 함께 backlog로 이관한다.
- Design/Plan retire 가능 여부는 두 번째 batch의 owner absorption 및 closeout checklist에서 닫는다.

## Stage rewind 조건

- terminal rule의 실제 결함이나 routing의 의미 침범이 발견되면 closeout을 멈추고 별도 rule revision 결정을 요청한다.
- backlog가 현재 착수된 작업이나 normative 절차를 담게 되면 Plan을 고쳐 future-work 경계로 되돌린다.
- 구현 범위가 P3-F1 표면, 다른 rule owner 또는 glossary mutation으로 확장되면 이 corrective를 중단한다.
- closeout 대조에서 Design/Plan의 current-bearing 의미가 terminal rule·backlog에 귀속되지 않으면 retire하지 않고 Design부터 재검토한다.
