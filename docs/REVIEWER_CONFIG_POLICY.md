# Reviewer Config Policy

## Config location

| Layout | Path |
|---|---|
| Source repo | `config/reviewer.json` |
| Target project | `<project-root>/.ai-harness/config/reviewer.json` |

## Precedence

```
explicit CLI parameter > config/reviewer.json > built-in safe default
```

## Defaults

- Default model: `gpt-5.5`
- Fallback model: `gpt-5.4`
- Default reasoning effort: `medium`
- High effort is recommended for high-risk architecture, migration, release, or security-sensitive review.
- `xhigh` is not a default because it is model-dependent.

## Constraints

- Reviewer model and effort must remain config-driven.
- Script-level hardcoding of model / effort / timeout / sandbox is forbidden except as a final fallback.
- The first seed must not call Codex automatically.

## Output location

Future reviewer output must live under `<project-root>/log/review/<run-id>/`.

A root `codex-review-input.md` or `codex-review-result*.json` is forbidden.

## MVP reviewer boundary

현재 MVP는 reviewer 자동 실행 wrapper를 제공하지 않는다.

- `run-codex-review.ps1` adapter는 **존재하지 않는다.**
- `review-run` wrapper는 **존재하지 않는다.**
- `review-prepare.ps1` 실행 직후의 packet은 **prepared 상태**이며, reviewer 실행은 toolset 밖에서 수동으로 한다.
- 자동 reviewer 실행 / commit gating은 post-MVP 후보로만 남긴다.

## Manual Codex reviewer recipe

이 절은 manual recipe만 제공한다. project-local adapter가 아니다. 아래 명령은 local `codex exec --help` 로 옵션 호환성을 한 번 직접 확인한 뒤에만 권장 예시로 사용한다.

`review-prepare.ps1` 실행 후 `log/review/<run-id>/`에 `meta.json` + `input.md` 가 생성된 상태에서, Codex CLI를 사람이 직접 호출해 `result.md`를 만든다.

### 호출 형태 (PowerShell / Claude Code shell)

`codex exec` 는 Codex CLI의 비대화형 subcommand다. interactive `codex` 는 TTY를 요구하므로 비대화형 Claude Code shell에서는 적합하지 않다.

```
$runId = "<run-id>"
$model = "<model-from-config>"
Get-Content -Raw -LiteralPath "log/review/$runId/input.md" |
  codex --ask-for-approval never exec --sandbox read-only --model $model -c web_search=disabled --output-last-message "log/review/$runId/result.md" -
```

- `$model` 은 배포된 target project 에서는 `<project-root>/.ai-harness/config/reviewer.json` 의 값을 사용한다. source `ai-harness-toolset` repo 에서의 대응 source config 는 `config/reviewer.json` 이다. 사용자가 명시적으로 override 한 경우에만 다른 모델을 쓴다.
- `--sandbox read-only` 와 `-c web_search=disabled` 는 reviewer가 target tree나 외부 네트워크에 영향을 주지 못하게 하는 안전 기본값이다.
- `--output-last-message` 는 reviewer 의 최종 message를 `result.md` 에 직접 기록한다. stdout redirection (`> result.md`) 은 default 로 사용하지 않는다. 설치된 Codex CLI 가 long form 대신 `-o` 만 지원한다면, local `codex exec --help` 결과를 근거로 `-o "log/review/$runId/result.md"` 로 대체한다.
- `--ask-for-approval never` 는 top-level Codex flag 로, `exec` subcommand **앞에** 두어야 한다. `codex exec --ask-for-approval ...` 형식은 codex-cli 0.125.0 의 exec parser 가 unexpected argument 로 거부한다. 설치된 Codex CLI 가 어떤 위치에서도 이 flag 를 받지 않으면 멈추고, 실제 terminal 에서 실행하거나 별도 승인 fallback 을 사용한다.
- 마지막 `-` 는 stdin 에서 prompt 를 읽으라는 marker 다.
- root `codex-review-input.md` 를 만들지 않는다. input 은 항상 `log/review/<run-id>/input.md` 다.
- root `codex-review-result*.json` 을 만들지 않는다. machine-readable result 는 항상 `log/review/<run-id>/result.json` 이다.

### Post-MVP adapter 시 권고

robust 한 Windows / PowerShell automation 이 필요하면 post-MVP adapter 로 분리한다. 그 adapter 는 legacy `-File` wrapper pattern 을 따른다. `powershell.exe -Command` 는 exit code 전달이 부정확해 wrapper 모드로 사용하지 않는다. 이 권고는 wrapper 가 만들어질 때 적용되며, 이번 MVP 의 manual recipe 자체에 영향을 주지 않는다.

### result.md 이후

`result.md` 가 생기면 `docs/REVIEW_RESULT_CONTRACT.md` 를 참고해 같은 디렉터리에 `result.json` 을 사람이 작성한다. 값 출처:

- `runId`, `targetPath`, `targetSha256`, `sourceHead` — `meta.json` 에서 옮긴다.
- `inputSha256` — 동일 디렉터리 `input.md` 의 실제 SHA-256.
- `resultMarkdownSha256` — 방금 생성한 `result.md` 의 실제 SHA-256.
- `createdAtUtc` — contract가 요구하는 정확한 shape `yyyy-MM-ddTHH:mm:ss.fffffffZ` (UTC).

`result.md` 와 `result.json` 이 모두 존재하는 시점에만 `scripts/review-verify.ps1 -RequireResult` 를 실행한다. `-RequireResult` 가 통과해야 해당 run record가 completed binding을 만족한 것으로 본다.

### Verdict의 의미

reviewer verdict 는 commit / push / publish / merge / release 에 대한 승인이 아니다. 그 단계들은 모두 별도 사용자 승인을 요구한다.
