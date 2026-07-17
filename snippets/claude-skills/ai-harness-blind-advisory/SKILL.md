---
name: ai-harness-blind-advisory
description: 사용자 또는 ordinary non-toolset caller가 "$ai-harness-blind-advisory 실행", "Blind 스킬 실행", "블라인드 결함 prefilter를 실행해"처럼 이 스킬 실행을 명시적으로 요청할 때만 현재 repo에서 fresh read-only 정적 reviewer 한 명을 시작하고 final response를 가공 없이 반환한다. 이름 인용·설명·검토, 일반 review·canonical review·consultation·Brief·ordinary task와 일반 "블라인드 리뷰"·"블라인드로 봐줘"류 문구만으로는 실행 요청이 아니다.
---

# ai-harness-blind-advisory

## 실행

1. current caller가 자신이 ai-harness-toolset skill 실행으로 생성된 lineage임을 알고 있으면 reviewer를 시작하지 않고 `unavailable(ai-harness-toolset-created lineage 재호출)`만 반환한다.
2. 검토 범위, 작업 목적, 현재 위치를 한 문장씩 정리한다. 검토 범위는 사용자 지정 scope가 있으면 그 범위이고, 없으면 `현재 repo 작업 상태 전체`다. 이전 결론, worker narrative, 예상 finding, test 결과는 넣지 않는다.
3. host의 final-message-only/no-trace 결과 경로를 사용할 수 없으면 reviewer를 시작하지 않고 `unavailable(output-isolation-unavailable)`만 반환한다.
4. fresh ordinary reviewer를 current repo에서 시작하고 아래 prompt만 전달한다.

```text
이 세션은 <검토 범위>를 독립적으로 read-only 정적 리뷰한다.
파일 변경·테스트 실행, ai-harness-toolset 스킬을 쓰지 마라.

작업 목적: <목적>
현재 위치: <위치>
결함 후보만 위치와 이유를 붙여 보고해줘.
```

작업량이 클 때만 다음 한 줄을 추가한다.

```text
작업량이 크면 같은 경계를 지키는 서브에이전트를 한 단계 활용하되, 추가 위임하지 마라.
```

사용자가 scope를 지정하지 않았다면 diff-only나 selected-file-only로 축소하지 않는다. reviewer와 그 child가 모두 끝나거나 명시적으로 중단된 뒤 결과를 받는다.

## 반환

- reviewer final message를 가공하지 않고 그대로 반환한다. 별도 요약·schema·artifact를 만들지 않는다.
- final message를 얻지 못했거나 금지된 변경·테스트·toolset 재호출이 호스트나 호출자에게 관측되면 `unavailable(<짧은 실제 사유>)`만 반환한다.
