# rule-authority — whole-rule disposition handoff Plan

> 이 문서는 existing `rule-authority` revision의 승인 대상 Plan이다. clause 처분과 terminal identity 전체 처분을 구분하고 whole-rule 처분을 DWM lifecycle로 넘기는 한정된 interface를 landing한다. 이 Plan은 mutation/commit/push 승인이 아니며 closeout에서 삭제된다.

## Batch 순서와 의존

1. 현재 `## 자격`과 `## 충돌과 처분`의 authority taxonomy를 보존한다.
2. terminal identity 유지 여부에 따른 처분 경계를 명료화한다.
3. whole-rule 처분의 실행을 DWM owner-local lifecycle로 넘긴다.
4. DWM terminal 문면과 1:1 대조하고 이 planning artifact를 closeout한다.

`rule-authority`는 처분 결정을 먼저 소유하고 DWM은 승인된 whole-rule 처분의 lifecycle을 수행한다. 둘 중 한쪽의 변경만으로 완료를 주장하지 않는다.

## Batch 정의

### Authority handoff

- 목적: clause-level 처분과 whole-rule 처분을 구분하고 정상 lifecycle owner를 명시한다.
- scope: `rules/rule-authority.md`의 처분 interface 한정.
- hard boundary: DWM artifact 순서, reference sweep, distribution/install 절차를 복제하지 않는다.
- validation expectation: DWM counterpart와 meaning-level 1:1 대조, 관련 owner/backlog 확인, 전체 suite.
- review focus: 권위 분류가 file identity 중심으로 바뀌지 않는지, 사용자 처분 전 상태가 계속 binding인지, handoff가 예외를 만들지 않는지.
- Work Packet: 만들지 않는다. 한 단락의 owner interface이며 별도 line-level 조사 home이 필요하지 않다.

### Closeout

- 목적: durable handoff가 terminal rule에 흡수됐는지 확인하고 Design/Plan을 삭제한다.
- scope: terminal rule과 existing backlog.
- hard boundary: 미실증 whole-rule 실행을 closeout 증거로 쓰지 않는다.
- validation expectation: two-level closeout과 corrected-state self-review.
- review focus: foreign semantics 복제, 불필요한 backlog row, stale planning residue.
- Work Packet: 없음.

## Open decision의 close 지점

- whole-rule 처분을 구분하는 최소 기준: Authority handoff에서 terminal identity가 active owner로 남는지로 닫는다.
- DWM을 가리키는 interface의 상세도: artifact·distribution semantics를 복제하지 않는 한 문단으로 닫는다.
- 새 rule-authority backlog 필요성: Closeout에서 current correctness가 모두 닫히면 no-change로 결정한다.

## Stage rewind 조건

- Plan이 clause × scope × enforcement 평가 단위를 바꾸면 Design으로 돌아간다.
- terminal 문면이 DWM이나 개별 rule 의미를 흡수하면 Plan으로 돌아간다.
- DWM counterpart가 whole-rule terminal/resume를 제공하지 못하면 이 handoff만 단독 landing하지 않고 두 owner를 함께 재검토한다.
