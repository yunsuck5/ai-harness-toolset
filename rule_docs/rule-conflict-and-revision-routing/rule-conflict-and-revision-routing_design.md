# rule-conflict-and-revision-routing Design

> 이 Design은 rule revision handoff의 종결 공백을 닫기 위한 방향성 문서다. 영구 live surface가 아니며 closeout에서 current-bearing 의미를 흡수한 뒤 삭제된다. 이 문서는 mutation/commit/push/adoption/activation 승인이 아니다.

## Header

- 이 문서는 `rule-conflict-and-revision-routing`의 revision handoff가 송신에서 끝나지 않고 수신 owner의 처분과 원 작업 상태까지 재구성되도록 하는 Design이다.
- 이 체인이 끝나면 terminal rule은 owner 의미를 복제하지 않으면서 handoff의 최소 종결 의미를 자족적으로 소유한다.
- 이 문서는 공통 queue/schema, owner별 실제 처분 절차, 일반 handoff 규격 또는 bootstrap 확장의 Design이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 terminal rule은 blocked work를 owner-local revision으로 운반하는 경계까지는 정의하지만, 수신 owner가 무엇을 처분으로 남겨야 하고 그 결과 원 작업이 재개·차단·종결 중 어디에 놓이는지는 닫지 않는다. 이 공백은 caller가 handoff 발신 자체를 완료나 unblock으로 오인하거나, 반대로 수신 owner의 미결 의미가 durable home 없이 사라지게 할 수 있다.

변경은 handoff 아래에 새 공통 workflow를 만들지 않는다. 이 rule이 소유할 것은 수신 결과를 `absorbed`, `rejected`, `rerouted`, `explicitly unresolved` 중 하나로 식별하고, 미결이면 구체 close point를 남기며, 원 작업의 resume/block/close 상태를 함께 보존한다는 최소 transport 의미뿐이다.

## Owner surface model

- `snippets/rules/rule-conflict-and-revision-routing.md`는 이 rule로 시작된 revision handoff의 최소 terminal outcome과 원 작업 상태 보존을 소유한다.
- 수신 owner는 실제 의미 판단, durable 기록 위치, 재개 조건과 후속 lifecycle을 소유한다. 이 rule은 foreign owner의 schema·용어·절차를 복제하지 않는다.
- `docs-working-model`, `global-file-mutation-boundary`, `powershell-and-file-encoding`의 future-work queue는 각 owner에서 아직 시작하지 않은 잔여 의미만 소유한다.
- bootstrap은 기존 broad pre-read/stop 문면을 유지한다. HN-02의 과거 재검토 의무는 사용자 재정으로 철회됐으며 새 owner나 backlog를 만들지 않는다.

## 수정 대상

- terminal rule의 `Revision handoff` 의미를 좁게 보강한다.
- 아직 시작하지 않은 잔여 의미를 `DWM-B-20`, `GFM-B-05`, `PFE-B-05`로 각 owner backlog에 분리한다.
- 이 Design, 대응 Plan과 Work Packet은 planning anchor로 보존한 뒤 terminal landing closeout에서 삭제한다.
- distributed index와 두 bootstrap trigger는 action-class가 바뀌지 않는지 확인하되, 새 routing 필요가 없으면 수정하지 않는다.

## 하지 않을 것 (non-goals)

- ordinary cross-owner handoff 전체에 공통 schema, registry, queue, checklist 또는 machine gate를 강제하지 않는다.
- `explicitly unresolved`를 성공, unblock, whole-task completion 또는 무기한 보류의 동의어로 만들지 않는다.
- HN-02를 다시 backlog로 등록하거나 bootstrap pre-read/stop 문면을 축소·확장하지 않는다.
- historical incident ID, relay 좌표, source-repo residue 또는 owner-local taxonomy를 distributed terminal rule에 넣지 않는다.
- DWM-B-07의 generic split-check를 착수하거나 새 checker를 만들지 않는다.

## Plan readiness / open risks

사용자가 HN-02 유지, owner-local 잔여 분리, exact two-commit lifecycle을 결정했으므로 Plan으로 내려갈 준비가 됐다.

- **과대 적용 위험:** terminal outcome 요구가 ordinary handoff 전반의 새 ceremony로 읽힐 수 있다. terminal rule 문면과 fresh review에서 이 rule 아래 revision handoff로 범위를 한정한다.
- **완료 세탁 위험:** `rerouted`나 `explicitly unresolved`가 원 작업 unblock으로 읽힐 수 있다. terminal rule에서 결과 분류와 원 작업 상태를 독립 축으로 닫는다.
- **owner 침범 위험:** close point 요구가 foreign owner의 형식을 규정할 수 있다. 기존 owner surface 또는 현재 report를 재사용하고 공통 schema를 금지하는 경계로 닫는다.
- **잔여 의미 유실 위험:** source finding을 terminal rule에 과적재하거나 planning 문서 삭제와 함께 잃을 수 있다. 각 owner backlog의 reopen/start condition과 closeout 대조에서 닫는다.
