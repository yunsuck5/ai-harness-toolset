# review Design — canonical review 문면 축소와 pipeline owner 정합

## Header

- 이 문서는 canonical review의 operator/reviewer 문면을 현재 기계 owner와 다시 맞추는 Design이다.
- 완료 시 판단 규율은 간결하게 남고, 기계 shape·runtime output 계약·run facts는 실제 script/verifier owner에 한 번만 존재한다.
- 실행 기록이나 영구 문서가 아니며 mutation·commit·push·global activation 승인이 아니다.

## 왜 바꾸는가 / 무엇을 바꾸는가

현행 review skill과 input/result template은 scripts가 이미 강제하는 topology·write-once·output shape·provenance를 여러 번 다시 설명한다. 역사·cookbook과 정상 run-fact의 장문 재보고도 operator가 실제로 판단해야 하는 target/scope·staleness·risk·semantic intake를 가린다. 또한 prepare의 기본 full-template seed는 operator용 안내 전체를 reviewer input으로 복제하고, result template과 runner preamble에는 default verdict, generic finding/risk bucket, Counter-argument 강도 충돌이 남아 있다.

이번 변경은 다음 수렴을 한 coherence unit으로 적용한다.

- **C1/C2:** 기계 shape 재설명을 줄이고 reviewer output의 runtime contract를 runner preamble + 기존 result verifier에 둔다.
- **C3/C4:** legacy/cookbook을 제거하고 정상 telemetry는 stdout/provenance를 재사용한다. operator 보고는 coverage·invocation/pass/corrective 축·semantic verdict/risk/stale·validation·git/authority 경계에 집중한다.
- **C5:** engine independence, target/scope integrity, one unit/one invocation, no retry/fallback/bypass, unavailable 시 verdict 비제조, verdict/next-action, semantic result intake, framing·honesty·stale/retraction, semantic reference sweep, read-only parallel fixed-set/join, mutation gate를 보존한다.
- **C6/E1:** 새 pass는 빈 `input.md`를 만들고 full-template seed 경로와 `-NoSeed` 호환 손잡이를 제거한다. template은 자동 prompt가 아니라 operator가 필요할 때 읽는 compact 작성 reference로 남는다.
- **E2/E3:** result skeleton의 default `yes`와 generic `## Findings`/`## Risks`를 제거한다. named risk는 `## Non-blocking concerns`에 기록하고, Counter-argument는 optional·strongly-recommended·non-parser pressure-test로 일관되게 설명한다. `once`는 전체 dual review가 아니라 한 `(perspective, pass)` review unit당 reviewer invocation 1회를 뜻한다. index mutation인 `git add -N`은 일반 검증 팁에서 제거한다.

## Owner surface model

- `scripts/review-prepare.ps1`: write-once pass를 발급하고 빈 `input.md`를 만든다. template seed mode는 소유하지 않는다.
- `scripts/review-run.ps1` + `scripts/review-verify.ps1`: reviewer output runtime 지시와 candidate/final artifact shape 검증을 소유한다. verifier의 parser 의미는 바꾸지 않는다.
- `snippets/claude-skills/ai-harness-review/SKILL.md`: target/scope·engine independence·semantic intake·staleness·risk/authority·parallel join 등 기계가 대체할 수 없는 operator 판단을 간결하게 소유한다.
- `templates/review-input.md`: operator가 직접 작성할 때 참조하는 compact input skeleton과 point-of-use 의미를 소유한다. 자동 seed나 reviewer output contract의 runtime owner가 아니다.
- `templates/review-result.md`: default verdict와 generic bucket 없이 verdict + 네 required disclosure position, optional Counter-argument/Notes의 최소 skeleton과 point-of-use 의미를 보인다.
- `docs/review/review_spec.md`: 위 target state와 owner 경계를 명세하며 구현 중 `sync-required`로 유지한다.

### P04 선택 — 포함

현행 pre-provenance verify는 malformed candidate에 provenance를 붙이지 않는 경계로 유지한다. provenance append 시도 뒤 runner가 같은 `review-verify -RequireResult`를 다시 호출해 final canonical shape를 확인하고, SKILL의 별도 post-hoc 호출을 흡수한다. 이는 새 parser/gate가 아니라 기존 검사의 owner 이동이다.

- pre-verify 실패: 현행처럼 nonzero, provenance/PASS/H1 없음.
- append 성공 + tail verify 성공: PASS/H1/exit 0.
- append 실패 + tail verify 성공: 현행 nonfatal 계약을 유지해 PASS/H1/exit 0과 `provenance-persisted: FAILED`를 함께 보고.
- append 성공/실패 + tail verify 실패: nonzero `review result unavailable`; failed pass와 이미 기록된 실제 provenance는 보존하고 표준 PASS/H1 success line은 내지 않음. append 실패도 함께 발생했으면 두 진단을 모두 드러냄.

tail verify는 input/verdict/네 disclosure H2 shape만 다시 확인한다. provenance 내용·완전성 검증으로 과장하지 않는다.

## 하지 않을 것 (non-goals)

- 새 verdict, required section, parser rule, sidecar, 검사층, 자동 retry/fallback, multi-reviewer orchestration을 만들지 않는다.
- canonical three-level layout·two-file·write-once 계약을 바꾸지 않는다.
- B2 전 off-repo 자료의 실제 read 시도 + load-bearing body inline fallback을 제거하지 않는다.
- B3 전 validation evidence의 비권위성, broad reproduction 별도 승인, 비재현의 자동 risk 승격 금지, change-class 비례성을 줄이지 않는다.
- T2/T3를 구현하거나 global/stable/install surface를 갱신하지 않는다.
- Design/Plan을 working-tree candidate에서 삭제하지 않는다.

## Plan readiness / open risks

owner와 P04 failure semantics가 닫혀 Plan으로 진행할 수 있다. `-NoSeed` 제거는 승인된 seed-path 처분의 CLI 결과이며 affected test와 tracked reference sweep으로 잔존 호출을 닫는다. P04는 기존 verifier를 재사용해야 하고 검증 로직을 runner에 복제하면 안 된다. 구현이 hold zone, parser 의미, verdict/layout/topology 또는 승인 exact-path 밖 behavior를 바꾸면 중단하고 Design으로 돌아온다.
