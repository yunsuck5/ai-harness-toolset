# Canonical review packet lens 감산 Plan

## Header

이 Plan은 사용자에게 승인된 Design의 F10·F11·F13 결정을 Review Spec·배포 skill·input template에 동기화하고, 순감 확인과 corrected-state dual review를 거쳐 content commit gate까지 가져가는 approval-target 기록이다. Work Packet은 만들지 않으며 이 문서는 구현·commit·push·배포 승인이 아니다.

## Batch 순서와 의존

1. 사용자가 Design과 이 Plan의 네 결정점 및 exact scope를 검토한다. 변경 요청이 Design 결정을 바꾸면 구현하지 않고 Design으로 돌아간다.
2. 승인 뒤 Review Spec의 input/operator/coverage target state를 갱신하고 lifecycle marker를 `sync-required`로 둔다.
3. 배포 review skill의 packet admissibility·semantic intake·same-wave join 문단과 input template의 Context·Review questions·Known concerns 안내를 감산 교체한다.
4. Spec↔active surface 의미, physical prose와 caller duty의 비증가, exact scope를 대조한다.
5. Affected/full Pester, `scripts/verify-ps1.ps1`, DWM diagnostic, diff/whitespace 검사를 한 validation cycle로 수행한다.
6. 설치본 `42a96f0`의 eligible pre-change review engine으로 canary-first local-correctness unit을 완료·소비한 뒤 system-coherence remainder를 실행해 fresh dual coverage를 닫는다. 이 candidate의 F13을 자기 review에 소급 적용하거나 corrected-state acceptance 근거로 사용하지 않는다.
7. 결과의 evidence·risk·limitation·assumption을 intake하고 staleness를 판정한다. Blocker나 material input omission이 있으면 처분 없이 진행하지 않는다.
8. Corrected candidate가 닫히면 실제 변경과 검증에 맞춘 commit message 초안을 준비하고 content commit 직전 사용자 gate에서 정지한다.
9. Content landing 뒤 별도 사용자 승인으로 retirement-only closeout을 수행한다. Design/Plan 삭제와 Spec marker의 `live` 전이 외 source delta가 있으면 closeout하지 않고 candidate correction으로 돌아간다.

## Batch 정의

단일 content batch의 exact source 경로 집합은 다음 다섯 개다.

- `docs/review/review_design.md`
- `docs/review/review_plan.md`
- `docs/review/review_spec.md`
- `snippets/claude-skills/ai-harness-review/SKILL.md`
- `templates/review-input.md`

Planning-only 상신에서는 앞의 Design/Plan 두 파일만 만들고 live Spec·구현은 바꾸지 않았다. 사용자 planning 승인 뒤 나머지 세 파일을 같은 content candidate에 포함한다.

목적은 다음 세 의미를 한 번에 닫는 것이다.

- F10: packet neutrality나 tilt 자기신고를 방어책으로 삼지 않고 회피 가능한 conclusion/prior-verdict anchor를 감산한다.
- F11: material fact·open question·원 evidence는 보존하되 load-bearing하지 않은 prior verdict/advocacy는 packet에서 제외한다.
- F13: proven same-wave의 terminal accounting 전 semantic consumption을 막고 canary-first를 좁은 예외로 유지한다.

Hard boundary는 required 5-H2, active placeholder, result verdict/disclosure shape, runner preamble, direct-read transport, verifier, run-fact, no-retry/no-averaging, 사용자 gate를 바꾸지 않는 것이다. 새 H2·checklist·parser·cross-unit state·sidecar·evidence artifact·test assertion을 만들지 않는다. Exact5 밖 source 수정이 필요하면 조용히 scope를 늘리지 않고 사용자 결정으로 돌아간다.

Work Packet은 만들지 않는다. 표본별 fact/limit와 owner 결정은 Design에 자족 흡수됐고, 별도 line-level 조사나 current-bearing round note가 남아 있지 않다. 이 revision은 review domain-local lifecycle이므로 terminal-rule foreign-Spec direct-sync target은 적용되지 않는다.

### Validation expectation

- `tests/review-input-verify.Tests.ps1`: required H2·placeholder·compact skill/template 계약이 그대로 성립하는지 affected validation
- 전체 `tests/`: 인접 review·install distribution 계약까지 회귀가 없는지 full validation
- `scripts/verify-ps1.ps1`: 발주에서 요구한 repository PowerShell 검증; `.ps1` 수정이 없다는 사실과 별도로 실행 결과를 보고
- `scripts/docs-working-model-check.ps1`, `git diff --check`: lifecycle shape와 tracked diff hygiene 확인
- 순감 대조: SKILL/template/Spec의 packet·join 관련 문단에 새 heading·bullet class·caller phase가 0인지, required field/parser가 불변인지, prior-verdict disclosure와 tilt 요청을 제거한 대신 input+result intake 한 문장만 교체됐는지 의미와 물리 diff를 함께 확인

### Review focus

- Caller 결론을 뺀 것이 material confirmed fact나 open question 은폐로 바뀌지 않았는가.
- S4의 input disclosure가 result verdict 뒤에서 다시 유실되지 않는가.
- S5의 raw evidence/direct-read 경계와 run-fact 네 종이 그대로 보존되는가.
- Same-wave non-consumption과 canary-first가 충돌하지 않고, runner/verifier에 orchestration 책임이 넘어가지 않았는가.
- F14 authoring matrix나 DWM/Q-series 작업이 섞이지 않았는가.

Canonical review는 `local-correctness`와 `system-coherence` 두 focused unit으로 한다. Candidate가 review skill/template/contract를 바꾸므로 pre-change engine의 canary-first를 따른다. Local unit은 `contract-sensitive`, system unit은 `system-coherence-heavy` category를 사용하고, 첫 dual에서 `reviewer-version`(현재 executable 기대값 `0.153.0`)·`applied-effort`·`reviewer-session-id`·`reviewer-safe-posture`를 보고한다. 발주가 관측을 요구한 version·effort·session-id 중 하나라도 `not-observed`면 정지·보고하며 회귀 처분을 제조하지 않는다.

## Open decision 의 close 지점

- F10의 conclusion/prior-verdict/tilt 감산과 불가피한 selection lens 공개 방식은 이 Design/Plan의 사용자 승인으로 닫는다.
- F11의 load-bearing conditional policy와 input+result intake는 이 Design/Plan의 사용자 승인으로 닫는다.
- F13의 same-wave terminal join과 canary 예외는 이 Design/Plan의 사용자 승인으로 닫는다.
- Controlled paired-packet exercise는 B5에서 실시하지 않는 것으로 닫는다. 별도 관측은 별도 goal과 사용자 승인 없이는 만들지 않는다.
- F14는 B5 landing 뒤 별도 발주로만 넘긴다. H2 matrix나 authoring 분류를 이 Plan에서 결정하지 않는다.

## Stage rewind 조건

사용자 검토가 packet에 prior verdict를 다시 싣거나 open hypothesis를 전부 제거하는 등 Design의 fact/anchor 경계를 바꾸면 Design을 다시 쓴다. Spec이 이 Plan의 의미를 바꾸면 re-plan한다.

구현에 새 H2·parser·checklist·runner/verifier mutation·test hard gate·paired evidence exercise 또는 exact5 밖 source가 필요하면 확대하지 않고 사용자 scope 결정으로 돌아간다. Actual validation이나 pre-change review engine이 전제를 반증하거나, 구현이 Spec boundary를 넘거나, review 뒤 content가 바뀌면 해당 candidate 단계에서 정지하고 corrected-state review를 다시 판정한다.
