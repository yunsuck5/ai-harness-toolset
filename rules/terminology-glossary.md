# 규칙: 프로젝트 용어집

이 파일은 `ai-harness-toolset` repo 개발에서 실제로 공유하는 프로젝트 용어의 한 줄 의미와 채택·기각 상태를 두는 단일 home이다. 절차와 전체 semantics는 각 active owner가 소유하며, 이 용어집은 그것을 복제하지 않는다. repo-only 규칙이며 adopter payload로 배포하지 않는다.

## 사용할 때

- 이미 채택된 용어의 뜻을 확인해야 할 때 이 single home을 read-only로 조회한다. 뜻을 이미 아는 채택 용어의 평범한 사용은 다시 읽을 필요가 없다.
- 용어 결정·분류를 수정하는 trigger는 새 프로젝트 공용 용어 도입, 채택 의미·분류 변경, 실제 이름 충돌 해소, 기각 용어 부활 위험 네 경우다. 기존 용어가 더 이상 프로젝트 공용이 아니어서 항목을 제거하는 처분은 두 번째 trigger에 포함되며 새 상태를 만들지 않는다. 의미를 바꾸지 않는 오탈자·표현 교정은 proportionality rule에 따라 직접 수정할 수 있으며 별도 상태나 등록 절차를 만들지 않는다.
- 후보 문서 안의 작업용 이름은 그 후보가 직접 소유한다. 프로젝트 공용 용어로 채택하거나 기각하기 전에는 선등록·예약 상태를 만들지 않는다.
- 채택 용어는 여기에서 한 번만 정의한다. 다른 문서는 그 용어를 일관되게 사용하되 전체 정의를 복사하지 않는다.
- 기각 용어는 새 이름을 붙여 공용 domain·owner·bucket으로 되살리지 않는다.
- 이 파일은 mutation·commit·push·review verdict 권한을 부여하지 않고, `INSTALL.md`나 다른 active owner의 자족 계약을 약화하지 않는다.
- committed 용어집에는 tracked 파일이나 git history로 해소되지 않는 durable pointer를 두지 않는다. `log/**`·`polishing/**` 같은 경로 class의 설명은 가능하지만 구체 runtime/scratch 경로나 drive 절대경로를 기록하지 않는다.

## 채택 용어

- **`Design`** — 변경의 이유·방향·owner 경계·trade-off·non-goal·semantic target을 담는 임시 lifecycle artifact.
- **`Plan`** — Design을 batch 순서·scope·hard boundary·validation·review focus 같은 승인 대상 결정으로 분해하는 임시 lifecycle artifact.
- **`Spec`** — domain의 target-state 명세이며 closeout 후 implementation과 의미 수준 1:1로 유지되는 live 문서.
- **`Implementation`** — final Spec을 구현하고 closeout에서 Spec과 1:1로 대조되는 active surface.
- **`final Spec only`** — implementation이 Design·Plan이나 별도 문서가 아니라 완성된 Spec 하나만 구현 기준으로 삼는 원칙.
- **`stage rewind`** — 하위 단계가 상위 단계를 위반하면 상위 단계로 돌아가 다시 진행하는 절차.
- **`owner surface`** — behavior를 실제로 정의하는 script·test·template·snippet·skill·config·root instruction·rule 등의 active surface.
- **`source-of-truth` (single home)** — 한 사실에는 권위 있는 home 하나만 두고 다른 위치는 복사가 아니라 pointer만 두는 원칙.
- **`stable filename rule`** — lifecycle 문서가 정해진 domain/rule-prefixed role filename을 재사용하고 topic별 파일·우회 subfolder 증식을 금지하는 규칙.
- **`Work Packet`** — 회차성 조사·분류·구현 메모를 담는 committed temporary·비승인 문서. domain/rule의 정해진 role path에 두며 실행 명령·실행 기록은 넣지 않고 해당 closeout에서 흡수 후 삭제한다.
- **`incubation`** — domain 또는 rule 후보가 promotion·discard·continue 판단 전 repo 안에서 non-authoritative하게 성숙하는 pre-promotion lifecycle.
- **`rule-candidate incubation` (`rule_docs/`)** — terminal output이 단일 rule인 후보가 `rule_docs/<candidate>/`에서 진행하는 incubation. `rule_docs/`는 기존 rule revision도 수용하는 1:1 rule-bound planning workspace이며 candidate-only bucket이 아니다.
- **`incubation anchoring`** — 검증된 incubation 문서가 승인된 첫 commit으로 repo에 들어오는 시점.
- **`sync-required`** — 기존 live Spec이 새 target state로 갱신됐지만 implementation closeout 재동기화가 끝나지 않은 상태.
- **`future-work queue`** — 아직 시작하지 않은 일을 reopen/start condition·monotonic next-ID와 함께 두는 non-authoritative domain/rule backlog. Spec·구현 승인이 아니며 닫힌 row는 기본 삭제한다.
- **`proportionality rule`** — 의미 보존 교정은 직접 수정할 수 있지만 boundary·behavior·owner·validation 의미 변경은 정규 lifecycle을 요구하는 규칙.
- **`domain-local closure`** — domain이 자기 Spec·active surface·명시된 안정 interface만으로 이해되는 성질.
- **`top-down reference`** — orientation에서 owner surface로 내려가며 하위 문서가 상위 routing 문서에 의미를 의존하지 않는 참조 원칙.
- **`owner absorption proof`** — Design·Plan을 retire하기 전에 모든 current-bearing 결정을 올바른 owner surface가 흡수했음을 보이는 확인.
- **`4-class reference sweep`** — filename/path, bare token/ID, folder-as-bucket, semantic phrasing 네 종류로 잔여 참조를 찾는 조사.
- **`corrected-state Codex review`** — 수정 전 상태가 아니라 교정된 working tree를 검토하는 Codex review.
- **`mutation approval`** — repo 파일을 바꿀 수 있다는 사용자 명시 승인.
- **`commit / push approval`** — commit과 push 각각에 필요한 별도 사용자 명시 승인.
- **`package-local template / checklist`** — 다른 domain의 lifecycle 문서를 생산·검사하는 package-prefixed form.
- **`external workspace baseline`** — repo 밖의 고정된 read-only 자료를 advisory 입력으로만 사용하는 분류.
- **`checkpoint`** — Brief workflow에서 명시 요청으로 저장하는 복구 가능한 진행 지점.
- **`restore point`** — 사용자 요청으로 Brief restore가 재개하는 저장 지점.
- **`ProjectRoot`** — 작업 대상 project의 root.
- **`ToolRoot`** — 설치된 toolset의 `config`·`scripts`·`snippets`·`templates` root.
- **`ProjectLogRoot`** — `<ProjectRoot>/log` runtime factual-record root.
- **`candidate-lifecycle closeout`** — promotion 또는 discard로 후보 lifecycle을 끝내고 `_incubation.md`를 처분하는 closeout.
- **`promoted-lifecycle closeout`** — promoted artifact의 Design·Plan·Work Packet을 흡수 후 retire하는 closeout.
- **`prelive`** — promotion 뒤 첫 closeout 전 domain Spec 상태; discoverable target-state blueprint지만 implementation authority는 아니다.
- **`consultation`** — operator가 행동 전에 read-only 의견·반론·조사를 수집하고 한계를 포함해 종합하는 비판정 advisory workflow.
- **`operator synthesis`** — consultation의 usable response·불일치·한계·남은 결정을 operator가 근거와 함께 종합한 결과.
- **`독립 의견`** — operator의 결론·선호를 주입하지 않고 fresh one-shot으로 받는 consultation operation.
- **`재조율`** — operator의 현재 입장을 명시하고 전제·논리·반례를 multi-round로 공격하는 consultation operation.
- **`blind-advisory` (`blind advisory`)** — 명시 호출 시 current repo를 fresh read-only 정적으로 살펴 결함 후보만 반환하는 경량 prefilter.

## 채택 용어 — owner boundary 포함

- **`INSTALL.md as protected root-level self-contained install / update / uninstall operative contract`** — `INSTALL.md`는 install/update/uninstall의 자족 operative contract이며 용어집이나 `rules/**`가 이를 pointer-only 문서·docs-cleanup 대상으로 만들거나 실행 계약을 다른 home으로 옮기지 않는다.
- **`contextual duplication`** — 자족 계약 안에서 hard boundary를 의도적으로 다시 설명하는 허용된 중복.
- **`brief owner surface`** — Brief가 자기 semantics를 소유하며 다른 surface는 interface만 참조한다.
- **`review owner surface`** — review가 자기 semantics를 소유하며 다른 surface는 interface만 참조한다.
- **`install-update interface vs semantics`** — install-update의 cross-domain mention은 안정 interface만 보유하고 foreign semantics는 해당 owner에 남긴다.

## 기각 용어

- **instruction-surface as independent domain** — 여러 owner를 섞는 broad domain이므로 기각; 좁은 mechanism 위치 질문과 혼동해 되살리지 않는다.
- **global-invocation as independent domain** — 별도 broad domain owner가 없으므로 기각.
- **evidence umbrella as independent domain** — evidence를 공용 domain·system·shared contract로 묶는 broad bucket이므로 기각.
- **managed-block as independent domain** — install·instruction surface가 소유하는 marker/payload boundary이지 독립 domain이 아니므로 기각.
- **manifest as broad domain** — broad owner와 lifecycle이 없으므로 기각.
- **packaging as broad owner** — 이 toolset의 broad owner 개념이 아니므로 기각.
- **project folder as broad owner** — `docs/project/` 같은 장기 broad owner를 기각.
- **policy bucket as broad owner** — `docs/policies/` 같은 장기 execution-policy bucket을 기각.
- **handoff/snapshot as repo feature domain** — 독립 repo feature domain으로의 승격을 기각; trigger synonym이나 ordinary wording까지 금지하지 않는다.
- **docs/domains broad taxonomy** — scope boundary가 아닌 저장 bucket 형태의 broad taxonomy를 기각.
- **architecture broad bucket as long-term owner** — 여러 owner를 섞는 장기 architecture bucket을 기각. 좁은 architecture domain은 narrow owner·lifecycle·domain-local closure·reference model·active-surface 관계를 입증할 때만 별도로 검토할 수 있다.
- **rule_docs as a broad/mixed-owner bucket** — `rule_docs/`를 general policy·architecture·philosophy workspace로 쓰는 형태를 기각; 1:1 rule-bound planning workspace만 허용한다.
- **repo consumed/ archive lifecycle** — retire 대신 `consumed/`나 archive folder를 남기는 lifecycle을 기각; preservation은 git history가 맡는다.
