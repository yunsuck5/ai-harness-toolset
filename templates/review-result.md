# Review Result

이 파일은 `log/review/<review-task-id>/pass-NN/result.md` 의 형식 기준이다. Codex CLI 가 `--output-last-message` 로 같은 pass directory 에 결과를 작성한다. operator-role AI (Claude Code) 가 `result.md` 본문을 읽고 finding / risk / required change 의 의미를 판단한다.

`<review-task-id>` 는 하나의 Claude Code `/goal` 작업 또는 하나의 review gate 단위이며 Claude Code chat / session id 가 아니다. `pass-NN` 는 같은 review task 의 corrective loop 안에서의 각 Codex review attempt 다 (`docs/REVIEW_RESULT_CONTRACT.md`).

결과는 본 한 파일로 닫힌다. 다른 sidecar 파일은 canonical contract 의 일부가 아니다.

`## Verdict` heading 직후 첫 비어있지 않은 줄은 lowercase 정확히 다음 셋 중 하나여야 한다 — `yes`, `no`, `yes with risk`. 다른 토큰, qualifier, inline 형태 (`Verdict: yes`, `Final verdict: yes`), prose 안 verdict 는 모두 거부된다. 따라서 본 template 의 `## Verdict` 본문은 그 contract 를 따르는 형태로 비워 두며, reviewer 는 이 첫 비어있지 않은 줄을 실제 verdict 값으로 교체하기만 한다. 본 contract 안내는 `## Verdict` heading 밖 (위 본문 또는 `## Notes`) 에 둔다.

## Verdict

yes

## Findings

reviewer 가 발견한 사항을 한 항목씩 나열한다. 본문이 길어도 무방하다. 발견한 사항이 없으면 `No blocking findings.` 와 같이 명시한다.

## Risks

(선택) verdict 가 `yes with risk` 또는 `yes` 인 경우에 후속 단계에서 인지해야 할 risk 를 나열한다. risk 가 없으면 본 section 을 생략해도 무방하다.

## Notes

(선택) 추가 코멘트, 참고 evidence path, 후속 inspection 권고 등을 자유 형식으로 기록한다. 본 section 도 생략 가능하다.
