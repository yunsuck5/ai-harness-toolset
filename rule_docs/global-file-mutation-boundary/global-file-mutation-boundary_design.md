# global-file-mutation-boundary Design — managed adoption과 authored source 유지보수 분리

## Header

- 이 문서는 distributed `global-file-mutation-boundary` 규칙 개정의 방향을 정한다.
- 완료 시 managed-block adoption과 source repo의 tracked root instruction 유지보수가 서로 다른 경로를 가진다.
- terminal rule이나 실행 기록이 아니며 mutation·commit·push 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현 규칙은 user-global·project-root의 managed-block adoption과 source repo의 root `CLAUDE.md`·`AGENTS.md` 유지보수를 한 scope로 묶는다. 그 결과 marker가 없는 authored source도 adoption 실패 상태로 취급된다. 반대로 파일을 두 종류로 가르면 tracked source 안의 managed block이 어느 경로인지 모호해진다.

파일이 아니라 작업·영역을 분류한다. Managed payload의 삽입·교체·갱신·제거에는 marker와 fail-fast 보호를 그대로 적용하고, repo-authored 영역에는 명시 승인·scoped diff·해당 repo가 명시한 confidentiality/publication 경계와 repo-local 검증을 적용한다. Source-product 지위는 사용자가 대상 repo와 root instruction surface를 명시하고 대상 밖의 tracked active product surface가 뒷받침해야 하며, repo 내부 문면만으로 추론·자기승인하지 않는다. Universal 경로는 단일 surface와 pair를 모두 허용하고 paired/parity 여부는 repo-local 계약에 맡긴다. 이 repo의 root corrective에는 repo-local public-safe 경계가 그대로 적용된다. Root parity checker의 별도 정비는 이 revision에 흡수하지 않고 rule backlog에 둔다.

## Owner surface model

- distributed rule: 두 경로의 분류 기준, 공통 승인 경계, stop 조건
- managed-block scripts/tests: adoption marker·byte preservation·rollback의 기계적 enforcement
- source repo의 root instruction과 repo-local validation: authored source 유지보수 계약과 그 repo가 요구하는 검증
- global snippets와 distributed index: 항상 로드되는 요약과 rule trigger routing

## 수정 대상

- `snippets/rules/global-file-mutation-boundary.md`
- `snippets/CLAUDE_SNIPPET.md`, `snippets/AGENTS_SNIPPET.md`
- `snippets/rules/README.md`
- 같은 changeset에서 수행하는 root instruction pair의 scoped terminology trigger corrective

권위 분류는 clause × scope × enforcement 기준으로 다음과 같다.

- managed adoption의 marker·stop 계약: **Binding rule**, scope = user-global 및 optional adopter project-root adoption, enforcement = explicit approval + managed-block scripts
- authored source까지 marker-only로 막던 기존 전칭: **Binding rule의 과대 scope**, enforcement에 정상 repair/resume 경로가 없어 작업·영역 기준으로 분리
- 새 authored-source 경로: **Binding rule**, scope = 사용자가 source-product로 명시하고 대상 root instruction surface 밖의 tracked active product surface와 repo-local 계약이 뒷받침하는 repo-authored 영역, enforcement = external user identification + explicit approval + scoped diff + repo-specific confidentiality/publication boundary + repo-local validation

## 하지 않을 것 (non-goals)

- user-global 또는 adopter project-root의 marker 보호를 약화하지 않는다.
- authored source라는 이름으로 임의 project-root whole-file mutation을 허용하지 않는다.
- global/user 파일 자동 생성이나 implicit mutation을 허용하지 않는다.
- root parity checker 정비를 이 changeset에 흡수하지 않는다.

## Plan readiness / open risks

Plan으로 진행할 준비가 됐다.

- 같은 파일의 두 영역 오분류 위험: terminal rule의 작업·영역 판별, 사용자 source-product 명시와 대상 root instruction surface 또는 surfaces 밖의 corroborating 근거, managed block byte 보존, ambiguous-state stop으로 닫는다.
- 같은 changeset의 root pair corrective가 개정 전 전칭에 걸리는 전환 문제: 명시 승인된 정확한 pair·scoped diff에만 한정하고 review input에서 전환 경계를 검증한다.
- 저작 언어: repo 내부 Design/Plan은 한국어 본문+영어 기술어를 유지하고, 불특정 adopter가 읽는 배포 tier의 terminal rule·bootstrap·index는 영어를 유지한다. Terminal rule의 한국어 WIP는 같은 조건을 보존한 영어 문면으로 재작성하며, 언어 교정에 의미 변경이나 다른 표면의 전체 번역을 섞지 않는다.
