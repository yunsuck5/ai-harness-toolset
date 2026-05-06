# Decision

decision entry 한 건의 형식. 자세한 규약은 `docs/CHATLOG_CONTRACT.md`의 `사용자 원문과 AI 작성물의 분리` 절을 참고한다.

각 entry 안에서 **사용자 원문 reference**와 **AI judgment**를 분리한다. 같은 bullet 안에서 두 출처를 섞지 않는다. 사용자 원문은 짧은 verbatim excerpt만 인용하고, summarize / compress / rephrase / translate / interpret 하지 않는다. 원문 전문이 필요하면 `raw-transcript.md` 또는 별도 `User original input` 파일의 path / anchor를 reference로 둔다.

## Date

> ISO 8601 형식 권장. 예: `2026-05-06`.

## Decision

> 결정 한 줄. AI-authored.

## User original reference

> 결정의 trigger가 된 사용자 원문 인용. verbatim 짧은 excerpt 또는 raw-transcript.md / user-input.md anchor reference. 가공하지 않는다. 사용자 입력이 직접 trigger가 아니면 `none`.
>
> 예:
>
> ```
> > "이 부분은 commit 하지 말고 보고만 해 줘"
> source: log/chatlog/current/raw-transcript.md (line 42)
> ```

## AI judgment

> AI가 사용자 원문과 현재 상태를 어떻게 해석했는지. 사용자 원문 인용과 같은 bullet에 섞지 않는다.

## Reason

> 결정의 근거. 사실 위주.

## Alternatives considered

> 검토했지만 채택하지 않은 안. 채택하지 않은 이유를 짧게.

## Risks

> 결정으로 인한 알려진 risk. 사실/추정 구분.

## Status

> `proposed` / `accepted` / `superseded` / `rejected` 중 하나.
