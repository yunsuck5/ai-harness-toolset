# install-update Design — git-url exact target 결박

## Header

- 이 문서는 git-url 기존-install update가 bootstrap·inspect·apply·source-validity 검사에서 같은 target을 보도록 하고, 기록된 옛 branch를 묵시적으로 재사용하지 않도록 하는 방향을 정한다.
- 실행 기록이나 terminal Spec이 아니며 commit·push·실제 install/update·activation 승인이 아니다.

## 왜 바꾸는가

기존 inspect는 `-Ref`를 remote refname pattern으로 해석하지만 apply는 fresh clone의 commit으로 해석해 exact SHA가 두 단계에서 비대칭이었다. selector 생략은 `install.json.branch`를 묵시적으로 골라 의도하지 않은 옛 branch로도 update를 성공시킬 수 있었다. bootstrap clone과 D3 source-validity 검사는 선택 target이 아닌 remote default checkout을 볼 수 있었고, source resolve가 먼저 실패하면 payload·activation 진단이 평가되지 않은 값으로 보고되었다. 따라서 target identity와 진단 의미를 하나의 coherence batch로 닫는다.

## 선택 의미

1. git-url `inspect`와 `update-source`는 target selector를 정확히 하나 요구한다. `-Ref <40-hex commit>`은 exact one-shot target이고, `-Branch <recorded branch>`는 이동 가능한 tracking target이다. 둘 다 생략하거나 함께 지정하면 source resolve failure로 닫고 persistent install을 바꾸지 않는다.
2. exact `-Ref`의 자격은 inspect/preflight 시점에 remote의 `refs/heads/*`가 현재 광고하는 branch-tip SHA인지로 판단한다. tag·symbolic/short ref·광고되지 않은 historical commit은 받지 않는다. apply는 fresh clone에서 preflight SHA가 commit으로 available하고 동일한지만 확인한다. inspect 뒤 branch가 전진해 그 SHA가 더 이상 tip이 아니어도 clone에서 resolve되면 같은 one-shot target을 적용하고, unavailable/mismatch면 persistent mutation 전에 실패한다.
3. source validity(D3)와 payload archive는 모두 같은 `resolvedRefSha` Git tree를 본다. clone의 default working tree/HEAD는 어느 판단의 근거도 아니다. operator bootstrap도 resolved SHA를 detached checkout하고 HEAD equality를 확인한 뒤에만 그 tree의 `INSTALL.md`와 script를 소비한다.
4. `-Ref`는 one-shot payload target이며 기존 `install.json.branch`와 `remote`를 빈 값까지 포함해 보존한다. `-Branch`와 `-Remote`는 recorded identity와 같은 값만 허용하고 다른 값은 기존 source-cut guard가 막는다. run-scoped clone은 recorded remote가 non-empty면 그 이름, empty면 `origin`을 alias로 사용한다.
5. recorded branch가 empty이면 remote symbolic/default HEAD가 가리키는 SHA를 현재 advertised branch-tip과 대조해 exact `-Ref`로만 진행한다. branch 이름을 추정·persist하거나 moving `-Branch`를 합성하지 않는다.
6. git-url install에서 `-SourcePath`는 inspect/apply source 불일치를 만들므로 fail-fast한다. metadata가 valid하면 inspect는 payload·root README·source·activation 진단군을 전부 실제 평가한 뒤 `payload > source > activation > clean` precedence로 하나의 status를 고른다. source target이 unresolved이면 status와 무관하게 apply 전에 실패한다.

## Owner surface model

- `INSTALL.md`와 installed-root README template: exact target 결정, verified bootstrap checkout, selector 의미, 실패·승인 경계를 self-contained하게 소유한다.
- `scripts/install-update.ps1`: selector 검증, inspect 전체 진단, preflight/apply SHA 결박, custom remote alias와 mutation 전 fail-fast를 소유한다.
- `scripts/lib/install-pipeline-core.ps1`: selected-SHA tree의 D3 marker 검증과 같은 SHA의 archive materialization을 공통 소유한다.
- `scripts/install-global.ps1`: fresh-install clone alias와 existing-install selector 안내를 소유한다.
- `scripts/update-global.ps1`: selector를 재해석하지 않고 canonical implementation으로 전달하는 thin wrapper로 유지한다.
- install-update Spec과 affected Pester: target-state 의미와 회귀 보호를 소유한다.

## 하지 않을 것

- metadata schema·source-cut identity field·status vocabulary·approval model을 바꾸지 않는다.
- apply 시점의 tip 재광고를 요구하거나 remote에 광고되지 않은 arbitrary historical commit을 지원하지 않는다.
- local-clone working tree를 checkout하거나 git-url `-SourcePath`를 acquisition cache 전달 수단으로 부활시키지 않는다.
- persistent selector state, source-cut override, branch metadata 자동 전환, activation apply, 실제 stable update를 수행하지 않는다.
- clone-failure cleanup ownership, cache framework, 새 parser/schema를 이번 batch에 흡수하지 않는다.

## Plan readiness / risks

owner와 최소 동작이 닫혀 Plan으로 진행할 수 있다. branch-only target은 inspect와 apply 사이에 이동할 수 있으므로 exact 배포에는 40-hex `-Ref`를 권장한다. inspect가 성공해도 apply 시 해당 SHA가 clone에서 unavailable하거나 다른 SHA로 해석되면 mutation 전에 실패한다.
