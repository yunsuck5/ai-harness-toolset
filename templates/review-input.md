# Review Input

Operator가 빈 `input.md`를 직접 작성할 때 참조하는 compact skeleton이다. 이 template은 `review-prepare.ps1`가 자동 seed하지 않으며 reviewer output runtime 계약의 owner도 아니다. active placeholder(`AI_TO_FILL_...`)를 모두 실제 내용으로 바꾼 뒤 실행한다.

## Stage

{{AI_TO_FILL_STAGE}}

## Purpose

{{AI_TO_FILL_PURPOSE}}

## Review perspective

{{AI_TO_FILL_PERSPECTIVE}}

## Target files

{{AI_TO_FILL_TARGET_FILES}}

## Context

{{AI_TO_FILL_CONTEXT}}

확정 사실과 open hypothesis를 구분하고, stage와 artifact boundary를 명시한다. off-repo/sibling 자료는 advisory로 표시하고, caller가 `review-run.ps1`의 `-ExternalReadDirectory` / `-ExternalReadFile`로 절대·기존 경로를 전달한 뒤 아래에 exact load-bearing target을 적는다. Reviewer가 그 자료를 직접 읽게 하며 input·proxy·staging·workspace copy로 본문을 우회 복제하지 않는다. Load-bearing target을 읽을 수 없으면 verdict를 만들지 않고 review unavailable로 닫는다. 이전 기록을 load-bearing하게 인용할 때는 원본 path/section에서 exact text를 확인하고, 변동 가능한 count는 작성 직전 현재 상태에서 기계 재계산하며, 확인할 수 없으면 unverified로 적는다.

## Required inspection paths

{{AI_TO_FILL_REQUIRED_INSPECTION_PATHS}}

Reviewer가 read-only로 열어야 할 exact path와 각 path의 역할을 적는다. source target과 runtime evidence/off-repo context를 구분한다.

## Review questions

{{AI_TO_FILL_REVIEW_QUESTIONS}}

결론을 유도하지 않는 open-ended 질문을 쓴다. 마지막에는 input의 framing tilt가 있는지 별도로 surface하도록 요청한다.

## Constraints

{{AI_TO_FILL_CONSTRAINTS}}

허용/금지 mutation, scope, authority를 적는다. artifact persistence가 severity/closure에 영향을 주면 reviewer가 finding prose에 이를 명시하도록 요구한다. transient라는 이유만으로 finding을 자동 nonblocking 처리하지 않으며, committed temporary artifact도 존재하는 동안 실제 review target이다. 이를 위해 새 verdict/H2/parser field/tag를 만들지 않는다. 사용자 소유 task-grade 표가 실제로 제공된 경우에만 여기에 기록하고, 표가 없으면 default를 발명하지 않는다. 결과 뒤 threshold를 낮추거나 blocking finding을 자동 nonblocking으로 바꾸지 않으며, false-positive 판정에는 evidence와 사용자의 명시 결정을 요구한다.

## Validation evidence

{{AI_TO_FILL_VALIDATION_EVIDENCE}}

실행 claim이 있으면 `log/evidence/<scope>/<case>/validation-evidence.md` 같은 reviewer-readable Markdown bundle을 가리키고, 없으면 짧은 N/A를 쓴다. evidence는 supporting material이지 command 재실행·truth oracle·freshness binding·source-of-truth가 아니다. reviewer는 기본적으로 읽기만 한다. broad validation 재현을 원하면 exact command, cwd, 예상 read/write, 허용 output path, dependency, timeout, 해석 경계, sandbox failure 보고 방식을 명시적으로 authorize한다. 비재현은 자동 target risk가 아니며 누락/stale evidence·scope mismatch·정적 모순·명시적 고위험 공백 같은 독립 근거가 있어야 승격한다.

Validation scope는 change class에 비례한다. 수행/미수행 범위·사유·잔여 위험을 정직하게 적는다. `git diff --check`는 tracked/index-visible 변경만 다루므로 staging 권한이 없을 때는 신규 untracked 파일을 직접 whitespace/encoding 점검하고 그 한계를 밝힌다.

## Known concerns

{{AI_TO_FILL_KNOWN_CONCERNS}}

confirmed disclosure(실제 compromise·baseline failure·validation limitation·operator assumption)와 open hypothesis를 분리한다. 확정 사실을 가설로 약화하지 않는다. 없으면 명시적 N/A를 쓴다.

## Framing self-check

{{AI_TO_FILL_FRAMING_SELF_CHECK}}

previous verdict·closeout·advocacy 압력, 확인편향 표현을 점검해 남은 tilt와 중립화한 문구를 기록한다. `done` 같은 무내용 표시는 쓰지 않는다.

## Reference sweep

{{AI_TO_FILL_REFERENCE_SWEEP}}

이름/경로/식별자/구조/wording 변경이면 searched patterns와 paths, (1) path reference, (2) bare token/ID, (3) folder-as-bucket wording, (4) semantic phrasing의 점검 결과를 기록한다. 삭제는 case/variant/bare-section까지 확인한다. 부적용이면 N/A를 쓴다.

## Final verdict

yes / no / yes with risk

이 literal은 existing input gate가 요구하는 허용 verdict vocabulary다. reviewer output의 exact shape·failure instruction은 runner preamble(`review-run.ps1`)과 result verifier가 runtime에 제공한다. evidence가 blocker 존재 여부 판단에 불충분하면 verdict를 제조하지 않고 review result unavailable로 닫는다.
