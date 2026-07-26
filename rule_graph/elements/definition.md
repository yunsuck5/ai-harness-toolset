# 원소 — 정의

용어나 단위의 **뜻을 고정**하는 원소. class 기준은 `_journal/DECISIONS_LOG.md` `D-5`.

전부 `authority = false` 다. 정의는 무엇을 막지 않는다 — 막는 것은 그 정의를 조건으로 쓰는 합성이다.

---

### RE-00003 — 권위 평가의 단위

> 권위는 clause × scope × enforcement path 단위로 평가한다.

- **출처**: 추출(부분) — 원문 문장에서 부정구 "파일 전체나 label이 아니라"를 뺀 것. 그 부정구는 차단 성질을 가지므로 `RC-00028` 로 분리됐다

```text
ANCHOR RE-00003
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 단위로 평가한다
  MEANS: 권위 평가 단위를 고정하는 문장의 서술부
  VERIFY: 매치 1
```

### RE-00012 — Binding rule 의 정의

> Binding rule 은 사람이나 AI가 준수해야 하는 규범이다.

- **출처**: 추출 — 원문의 정의 대시(`— `)를 서술어로 복원했을 뿐 어휘는 그대로

```text
ANCHOR RE-00012
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: **Binding rule** — 사람이나 AI가 준수해야 하는 규범이다
  MEANS: Binding rule 등급의 정의문
  VERIFY: 매치 1
```

### RE-00018 — Advisory 의 정의

> Advisory 는 선택적인 비차단 지침이다.

- **출처**: 추출
- **비고**: 이 정의는 자신을 **비차단**이라고 선언하는데, 같은 원문 줄 안에 차단 조각 두 개(`RC-00033` `RC-00034`)가 있다. `_journal/FINDINGS.md` `F-5`

```text
ANCHOR RE-00018
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: **Advisory** — 선택적인 비차단 지침이다
  MEANS: Advisory 등급의 정의문
  VERIFY: 매치 1
```

### RE-00023 — Quarantine 의 지위

> Quarantine 은 권위 등급이 아니라 처분 상태다.

- **출처**: 추출 — 문면 그대로

```text
ANCHOR RE-00023
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: Quarantine은 권위 등급이 아니라 처분 상태다
  MEANS: quarantine 을 등급 축에서 빼고 처분 축에 두는 정의
  VERIFY: 매치 1
```
