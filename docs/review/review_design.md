# review Design

> 이 문서는 review campaign identity와 pass allocation 교정의 Design이다. 외부 task와 독립 review campaign을 구분하고, 공개 campaign claim과 동시 allocation의 target 의미를 함께 정한다. 이 체인이 끝나면 review 기록은 기존 three-level/2-file 구조 안에서 campaign 혼입과 pass overwrite 경쟁을 fail-closed로 막는다. 이 문서는 구현 authority나 mutation/commit/push 승인이 아니며 closeout에서 흡수 후 삭제된다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 `<review-task-id>`는 작업/gate 단위로 설명되지만, 같은 외부 task를 별도 독립 campaign이 다시 사용할 때 정상 corrective pass와 구분할 claim이 없다. 또한 auto allocation의 max+1 산정과 pass directory 생성이 분리되고 생성에 overwrite 허용 동작이 있어, 같은 좌표를 고른 두 process가 모두 성공할 수 있다. 사후 경고나 pass count 출력은 이 두 문제를 막지 못한다.

외부 task 하나는 서로 다른 목적·gate를 가진 복수의 review campaign을 가질 수 있다. API/layout 이름 `ReviewTaskId`는 유지하되 그 값은 한 purpose/gate에 결박된 campaign의 공개 key로 사용한다. 같은 campaign은 여러 perspective와 corrective/stale 후속 pass를 포함하고, 독립 평가이거나 목적·gate·Stage가 실질적으로 달라지면 새 key를 쓴다. `Purpose`는 unit 설명과 stdout 확인값일 뿐 저장된 identity나 equality proof가 아니다.

기본 prepare 호출은 새 campaign을 claim하고 기존 task root와 충돌하면 실패한다. `-ContinueCampaign`은 기존 campaign에 다른 perspective 또는 corrective pass를 추가한다는 operator의 공개 assertion이며 권한 token이 아니다. continuation에는 기존 canonical `input.md`가 anchor로 필요하다. anchor 없는 legacy/crash residue는 자동 채택하지 않고, pre-contract canonical record는 operator가 명시적으로 continue할 때만 이어 쓴다.

pass allocation은 auto/explicit 모두 후보 하나를 정한 뒤 최종 pass directory를 배타적으로 생성하는 지점을 선형화점으로 삼는다. 같은 preselected pass 좌표를 경쟁한 호출 중 claim 성공자만 새 0-byte `input.md`를 만들고 둘 다 끝난 경우에만 성공하며, loser는 다음 pass로 자동 이동하지 않는다. explicit 호출이 `pass-02`를 먼저 claim한 뒤 auto 호출이 새 scan에서 `pass-03`을 고른 경우처럼 서로 다른 좌표를 정상 선택한 두 allocation은 둘 다 성공할 수 있다. claim 뒤 중단된 pass는 occupied orphan으로 보존하고 자동 cleanup·rollback·재사용하지 않는다. 선택한 perspective의 `pass-99`가 이미 사용됐으면 그 perspective만 stop하며 explicit lower number로 우회하거나 새 key로 자동 rollover하지 않는다. lower pass의 precheck와 claim 사이에 concurrent `pass-99`가 생길 수 있으므로 lower allocation은 성공 발행 직전에 같은 perspective를 재확인한다. 그때 `pass-99` 점유가 확인되면 lower 호출은 nonzero이고 이미 claim한 lower pass는 occupied orphan으로 보존한다. parent·열거를 확인할 수 없으면 역시 nonzero지만 `pass-99` 점유나 lower artifact 잔존을 단정하지 않고 자동 retry·cleanup 없이 상태 확인을 요구한다. 다른 perspective의 독립 numbering은 계속 사용할 수 있다.

continuation admission과 첫 mutation 전에는 project log root부터 task entry까지, write 직전에는 task entry부터 선택된 write parent까지의 기존 ancestry와 canonical anchor를 다시 해석한다. 그중 하나라도 reparse entry이거나 기대한 directory/file shape가 아니면 mutation 전에 fail-closed한다. 이 guard는 호출 시작 시 정적으로 존재하는 entry를 대상으로 하며, 검사 뒤 hostile actor가 path를 교체하는 mid-invocation replacement race까지 봉인하는 보안 메커니즘은 아니다.

## Owner surface model

- `review-prepare.ps1`가 new/continue admission, 단일 후보 선택, 성공/실패 자기설명을 소유한다.
- `scripts/lib/path.ps1`가 path containment와 exclusive pass-directory claim + 0-byte no-clobber input allocation primitive를 소유한다.
- 배포 SKILL이 campaign key 선택과 첫 perspective/new·후속 perspective/corrective continuation의 point-of-use 규율을 소유한다.
- review Spec은 위 외부 관찰 가능 의미와 불변 경계를 기록하고, tests는 경쟁·legacy·orphan·range 경계를 지속 검증한다.
- user guide는 operator-facing 요약만 제공하며 active behavior authority를 갖지 않는다.

## 수정 대상

현재 live review Spec의 task-id·allocation·retention 의미와, SKILL·prepare/path helper·관련 tests·사용자 가이드의 대응 설명을 같은 lifecycle에서 교정한다. canonical path token과 three-level layout, pass별 `input.md`/`result.md` 두 파일, per-perspective numbering과 write-once는 유지한다.

## 선택의 trade-off

공개 key와 명시적 continuation은 sidecar 없이 accidental campaign collision을 fail-closed로 만들지만, 두 호출의 목적이 실제로 같은지를 기계적으로 증명하지는 않는다. marker가 없는 pre-contract canonical record도 신계약 record와 완전 자동 구분할 수 없다. 이 한계는 숨은 identity나 parser를 추가하지 않고 operator assertion과 canonical anchor로 드러내는 편을 택한다.

## 하지 않을 것 (non-goals)

- 사람·machine·session·process identity, opaque token, global mutex를 campaign authority로 사용하지 않는다.
- sidecar, lock file, history DB, 새 path segment, input seed, parser/schema를 추가하지 않는다.
- 같은 preselected 좌표 collision 뒤 rescan/next-pass retry, orphan auto-cleanup·복구·재사용, perspective별 pass range 확장을 하지 않는다.
- static existing ancestry의 reparse guard를 생략하지 않되, hostile mid-invocation path replacement까지 막는 보안 subsystem은 만들지 않는다.
- directory와 file 두 entry를 process crash까지 무잔여로 묶는 filesystem transaction을 주장하지 않는다.
- 이 review-local 용어를 프로젝트 공용 glossary나 새 상시 rule로 승격하지 않는다.

## Plan readiness / open risks

campaign model과 failure 의미는 Plan으로 내릴 만큼 닫혔다. Plan은 승인된 exact scope, affected-first validation, fresh dual review와 closeout 조건을 결박한다. supported filesystem에서 같은 preselected 좌표의 exclusive create가 exactly-one을 보장하지 못하거나 static existing reparse ancestry를 fail-closed할 수 없거나 machine-verified purpose equality·strict legacy version 판별·새 artifact가 필요해지면 구현을 넓히지 않고 Design으로 rewind한다.
