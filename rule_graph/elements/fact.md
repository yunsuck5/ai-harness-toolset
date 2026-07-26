# 원소 — 사실

**무엇이 무엇이다/ 무엇이 아니다**를 진술하는 원소. 규범을 지시하지 않는다. class 기준은 `_journal/DECISIONS_LOG.md` `D-5`.

전부 `authority = false` 다.

---

### RE-00004 — 입증 부담을 결정하는 것

> 실제 차단 효과가 자격 입증 부담을 결정한다.

- **출처**: 추출 — 문면 그대로

```text
ANCHOR RE-00004
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 실제 차단 효과가 자격 입증 부담을 결정한다
  MEANS: 자격 입증 부담의 크기를 무엇이 정하는지에 대한 진술
  VERIFY: 매치 1
```

### RE-00019 — Advisory 와 correctness evidence

> Advisory 는 correctness evidence 가 아니다.

- **출처**: 복원 — 원문은 주어가 생략된 "correctness evidence가 아니며". 선행사 `Advisory` 가 같은 줄에 있다

```text
ANCHOR RE-00019
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: correctness evidence가 아니며
  MEANS: Advisory 가 correctness 근거로 쓰이지 않는다는 진술
  VERIFY: 매치 1
```

### RE-00020 — Advisory 의 정리 가능성

> Advisory 는 stale 하면 정리할 수 있다.

- **출처**: 복원 — 주어 생략을 선행사로 채움

```text
ANCHOR RE-00020
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: stale하면 정리할 수 있다
  MEANS: Advisory 의 폐기 허가
  VERIFY: 매치 1
```

### RE-00021 — diagnostic 의 hard-fail 가능성

> 결정 가능한 diagnostic 은 실행할 때 hard-fail 할 수 있다.

- **출처**: 추출 — 역접 어미 "-지만" 앞까지. 뒤 절은 차단 성질을 가지므로 `RC-00035` 로 분리됐다

```text
ANCHOR RE-00021
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 결정 가능한 diagnostic은 실행할 때 hard-fail할 수 있지만
  MEANS: diagnostic 의 실패 능력에 대한 진술. 이 원소는 역접 앞까지만 취한다
  VERIFY: 매치 1
```

### RE-00022 — 처분의 동반 변경

> claim 을 변경하거나 제거하는 처분은 active owner 와 enforcement 를 함께 바꾼다.

- **출처**: 추출 — 문면 그대로

```text
ANCHOR RE-00022
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: claim을 변경하거나 제거하는 처분은
  MEANS: 처분이 무엇을 동반해서 바꾸는지에 대한 진술
  VERIFY: 매치 1
```

### RE-00024 — 상세 rubric 의 지위

> `rule-authority` 의 상세 평가 rubric 은 일회성 입력이었다.

- **출처**: 복원 — 원문 "상세 평가 rubric은 일회성 입력이었다"는 문맥상 이 규칙의 rubric 을 가리킨다. 원문 밖으로 나오면 어느 rubric 인지가 사라지므로 주어를 한정했다

```text
ANCHOR RE-00024
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 상세 평가 rubric은 일회성 입력이었다
  MEANS: 이 규칙의 평가 rubric 이 영구 자산이 아니라는 진술
  VERIFY: 매치 1
```

### RE-00025 — `rule-authority` 의 문면 지위

> 규칙 `rule-authority` 는 영구적으로 남길 최소 문면이다.

- **출처**: 복원 — 원문은 "**이 파일**은 영구적으로 남길 최소 문면이며". 원문 안에서는 자립하지만 **원소 트리로 옮기는 순간 "이 파일"이 이 원소 파일을 가리키게 되어 뜻이 뒤집힌다.** `_journal/FINDINGS.md` `F-6`

```text
ANCHOR RE-00025
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 이 파일은 영구적으로 남길 최소 문면이며
  MEANS: 이 규칙이 최소 문면으로 유지된다는 자기 진술
  VERIFY: 매치 1
```
