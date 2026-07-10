# docs-working-model Design — prelive 정의 명확화 (promoted-but-not-live 와 배포-경로의 관계)

> Design 은 변경의 **방향성 문서**다 — 영구 live 아님: closeout 시 current-bearing 내용이 terminal rule 로 흡수된 뒤 retire(삭제). 이 Design 은 mutation/commit/push 승인이 아니다(1회 진술).

## Header

- 이 문서는 `rules/docs-working-model/docs-working-model.md` 의 **prelive(promoted-but-not-live) 정의 명확화** revision 의 Design 이다 — E1 two-layer 의 not-authority 제약이 무엇을 묶고 무엇을 묶지 않는지.
- 이 체인이 끝나면 = terminal rule 의 E1 절이 "not-authority marker 는 domain 의 lifecycle 위치 서술(검증된-authority 소비의 제약)이며, active surface 의 정규 배포-경로 편입(= 운용 검증 경로)을 막지 않는다"를 명시한다.
- 이 문서가 아닌 것 = 규칙의 최종 normative wording 아님(terminal rule 소관) · lifecycle 구조 변경 아님 · 승인 게이트 변경 아님.

## 왜 바꾸는가 / 무엇을 바꾸는가

**실증된 문제**: domain Implementation 의 리뷰에서 E1 의 not-authority 문장에 대해 두 독해가 갈린다 — "prelive domain 의 구현물이 기본 배포 표면에 편입되는 것 자체가 'the default a consumer builds on' 위반"이라는 독해와, "E1 은 promoted artifact 의 authority 소비에 대한 제약"이라는 독해(발생 사례와 판정 이력은 git history 가 보존). 규칙이 이 경계를 명시 조문으로 갖지 않아, 같은 모호가 매 domain promote 마다 재발할 구조다.

**확정된 운영 모델(운영 결정권자의 설계-의도 확정)**: prelive 부터가 정규 배포 경로다 — 이 repo 는 프로젝트-로컬 skill 표면을 두지 않으므로(루트 지시 파일 Non-goals) 정규 글로벌 배포 경로가 운용 테스트의 실 경로이고, 그 phase 가 live 와 공유하는 것은 **runtime activation topology**(같은 배포 표면)이지 governance 상태가 아니다. 이 revision 의 closeout 은 그 운용 검증의 산출을 입력으로 소비한다(이 revision 의 retire 전략 — Plan 소관이며, rule 이 landing 이나 그 소비를 일반 의무로 만들지는 않는다). 운용 중 드러난 결함은 promoted lifecycle 이 분류·수정할 failure signal 이며, 수정 후 다시 배포 절차를 밟는다.

**semantic target(이 변경이 의미하게 될 것)**: not-authority marker 는 domain 의 lifecycle 위치 서술(아직 무엇도 closeout-확정 아님)이며 "검증된 authority 로의 소비"를 묶는다 — implementation 의 배포-경로 편입을 막는 조항이 아니다. 편입은 운용-검증(dogfood) 경로이고, 그 phase 의 deployed implementation 사용은 **검증-입력**이지 확정-behavior 주장이 아니다(배포된 구현을 *통해* artifact 내용을 소비해도 artifact 에 없는 authority 가 생기지 않는다 — 우회 차단). 운용 중 결함은 promoted lifecycle 이 분류·수정할 failure signal(구현/spec-sync/lifecycle 결함 중 무엇이든)이다. 이 명확화는 어떤 별도 승인 게이트(activation apply·commit·push)도 약화하지 않는다.

## Owner surface model

- terminal rule(`rules/docs-working-model/docs-working-model.md`)의 **E1 절**이 이 명확화의 single home 이다 — two-layer discovery 가 E1 소유이므로 그 경계 명확화도 E1 에 산다.
- Spec identity 절의 prelive 정의와 Incubation tier 의 promoted-but-not-live 서술은 기존 "(E1)" pointer 구조 유지 — 중복 서술하지 않는다(single-home-plus-pointers).
- 배포/activation 의 behavior 는 여전히 install-update domain 의 active surface 소유 — 이 rule 은 lifecycle 경계만 명명한다.

## 수정 대상

- `rules/docs-working-model/docs-working-model.md` E1 절 — 기존 `implementation authority` 괄호의 authority-축 명시(consumer 의 default 가 build on 하는 권위 — `live` = closeout-검증 기반 / `sync-required` = 승인된 target-state 기반의 이원; runtime availability 와 분리) + "a `prelive` … artifact's mere existence is *not* authority …" 문장 뒤에 명확화를 잇는다(기존 artifact not-authority 불변식의 *의미*는 보존하되 문면 무변은 아니다).

## 하지 않을 것 (non-goals)

- pilot-gate / 비기본-activation 구분의 도입(대안으로 검토·기각: 프로젝트-로컬 skill 표면 부재 구조상 글로벌 배포가 실 테스트 경로이며, activation apply 의 명시 승인이 이미 게이트다 — 차단형 gate 는 검증 경로 자체를 막는다).
- 소비자-가시 prelive 상태 표시의 도입 — **차단형 gate 와는 별개 축**이다(수동적 표시는 activation·dogfood 를 막지 않는다). 미도입 이유는 trade-off 가 아니라 소유와 필요: 그 표시의 owner surface 는 이 rule 이 아니라 각 배포물/설치 표면(cross-domain)이고, 현 운영(단일 운영자 dogfood)에서 필요가 실증되지 않았다. DWM-B-14 가 그 안건을 추적한다.
- E1 의 artifact-측 제약(Spec 을 live authority 로 소비 금지) 약화 — 불변.
- lifecycle 구조(promote → Design/Plan/Spec → Implementation → closeout)·closeout gate·승인 게이트 변경 — 전부 불변.
- consultation/blind-advisory 등 개별 domain 문서의 소급 수정 — 이 revision 은 rule 만 만진다.

## Plan readiness / open risks

- Plan 으로 내려갈 준비 됨 — 수정 대상이 한 절이고 semantic target 이 사용자 판정으로 확정됨.
- open risk 1: 문안이 "배포 편입 허용"을 넘어 "배포를 의무화"로 읽히면 과교정 — Plan 의 validation expectation 에서 방지(허용·경로 서술이지 의무 아님).
- open risk 2: 이 명확화 자체가 실전에서 충분한지는 B 재리뷰·O promote 실사용이 검증한다 — **이 revision 의 closeout(본 Design/Plan retire)은 그 실사용 검증 후로 미룬다**(Plan 의 retire 조건 소관; 선행 revision 이 검증 소비자보다 먼저 닫힌 재발 방지).
- open risk 3: 배포된 prelive skill 을 소비자가 live 와 구분할 표시 장치는 도입하지 않는다(차단형 gate 와 별개 축인 수동적 표시 — non-goals 의 둘째 항이 미도입 근거[owner surface 가 이 rule 밖 + 필요 미실증]를 보유) — 수용 리스크로 남기며, DWM-B-14 로 추적.
