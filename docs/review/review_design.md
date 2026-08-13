# review engine eligibility·target wording 정정 Design

## 문제

canonical review의 compact skill은 핵심 판단 규율을 보존했지만, 엔진 독립성과 target binding을 실제 운용에 적용할 때 몇 가지 오독 경로가 남았다.

- stable 설치 위치만으로 독립성을 가정하거나 reviewed state와의 aggregate 비동일성을 적격 근거로 역추론하면, 대상 변경을 이미 포함하면서 무관한 drift도 가진 self-review 엔진을 허용할 수 있다.
- stable을 사용할 수 없을 때 pre-change checkout을 누가 제공하는지 불명확하면 workflow가 checkout을 만들거나 다른 fallback을 발명할 수 있다.
- Mode A가 working tree만 가리키는 것처럼 읽혀 사용자가 지정한 base 대비 committed delta를 놓칠 수 있다.
- 같은 task의 corrective pass identity, input의 verdict literal과 placeholder gate, canary의 적용 pipeline이 압축 문면에서 오해될 수 있다.
- B2라는 내부 토큰은 exact-path read 우선과 inline fallback이라는 실제 보류 의미를 직접 설명하지 못한다.

## 선택한 의미

1. review tooling self-modification에서는 stable 설치의 current payload-head provenance를 canonical 3-way cross-binding `payload-manifest.json.head == payload-marker.json.head == install.json.lastUpdatedHead`로 확인·기록하고 최초 설치 history field인 `install.json.installedHead`와 구분한다. missing/unreadable/mismatch는 provenance 불완전이며, 3-way equality는 metadata가 함께 지칭하는 payload head만 확립할 뿐 payload integrity·pre-change·eligibility를 홀로 입증하지 않는다. 선택된 각 target component마다 pre-change baseline과 exact reviewed state를 결박하고 candidate engine·baseline·모든 reviewed state의 target-relevant payload를 line-ending-normalized 단위로 대조한다. working-tree와 committed delta를 함께 고르면 committed endpoint와 current working tree를 모두 포함한다. 모든 대상 변경을 배제한다는 affirmative pre-change 근거가 있을 때만 적격이다. 대상이 바꾼 payload의 reviewed after-state를 포함하는 엔진은 부적격이고 그 after-state와의 동일성은 포함 근거가 되지만, 비동일성만으로 적격을 입증하지 못하며 불완전한 coverage/provenance도 부적격으로 처리한다. user-provided checkout에는 install cross-binding을 요구하지 않지만 checkout provenance와 같은 baseline/payload/reviewed-state 대조를 요구한다.
2. eligible global stable ToolRoot를 우선 사용한다. unavailable/ineligible이면 already-existing user-provided pre-change 독립 checkout만 대안이며, workflow는 이를 만들지 않는다. 대안이 없으면 stop/request하고 임의 fallback을 만들지 않는다.
3. Mode A는 사용자 target에 따라 uncommitted working-tree changed set과 stated base 대비 committed delta의 전부 또는 일부를 포함한다.
4. 같은 task의 모든 pass는 같은 task-id를 재사용하고 task 자체가 바뀔 때만 새 ID를 고른다.
5. input의 `yes / no / yes with risk` literal은 gate용 문자열이지 operator verdict가 아니다. active `AI_TO_FILL_*` placeholder는 실행 전에 모두 치환한다.
6. canary-first는 실제로 사용 중인 engine pipeline에서 template·contract·perspective·artifact-binding이 새로 생기거나 바뀐 경우에만 발동한다.
7. off-repo 자료는 먼저 exact path로 읽고 실제 outcome/error를 보고하며, 별도 gated runner external-read-path integration 전에는 load-bearing 본문을 input에 verbatim inline한다.

## Owner와 경계

- active 운용 문면은 배포 `SKILL.md`가 소유한다. 기존 source-skill contract test를 affected validation으로 실행하되 이번 문면 batch에서 새 gate나 test contract를 만들지 않는다.
- 본 Spec은 target meaning과 owner 정합을 기록하되 operative authority가 아니다.
- verdict vocabulary, three-level/2-file/write-once topology, parser gate, B2/B3 hold의 substance, no-retry·mutation boundary는 바꾸지 않는다.
- 새 parser, sidecar, 자동 eligibility 판정 도구, 자동 checkout, 자동 fallback, 새 runtime layer를 만들지 않는다.

## 이번 batch에서 제외한 관측

- pre-change checkout과 새 엔진을 함께 다루는 절차의 추가 긴장(F7)
- fixed dual review의 동시 실행을 실제로 구현하는 orchestration 수단
- final report의 corrective-loop count 산정 정의

위 세 항목은 이 lifecycle에서 채택된 future work가 아닌 round-scoped intake observation이다. off-repo agenda 기록은 advisory evidence일 뿐 durable owner가 아니다. closeout 전에 사용자가 각 관측을 (a) reopen/start condition과 함께 `review_backlog.md`에 future work로 채택하거나 (b) 명시적으로 비채택·폐기해야 하며, 그 disposition 전에는 Design/Plan을 retire하지 않는다. W-07은 어느 disposition도 선결정하지 않는다.
