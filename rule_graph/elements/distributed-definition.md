# 원소 — 정의 (배포 대상)

배포 tier(`snippets/rules/`)의 합성이 참조하는 **정의** 원소. class 기준은 `_journal/DECISIONS_LOG.md` `D-5`, 배포 대상 분리는 `D-18`.

**정본 문장은 영어다.** 사본이 `snippets/rules/` 로 가고 그 표면은 영어를 유지하므로, 정본과 사본의 언어가 다르면 `V2`(정본·사본 일치)가 문자열 비교로 성립하지 않는다. 이 언어 혼재의 대가는 `_journal/FINDINGS.md` `F-12` 에 있다.

전부 `authority = false` 다.

---

### RE-00057 — `conflict-isolated`

> A work unit is `conflict-isolated` when it shares no blocked output, state, assumption, invariant, owner contract, validator, transaction or commit boundary, acceptance gate, or coherence unit with the blocked work, and has independent evidence, acceptance, and status.

- **출처**: 복원 — 원문 15행의 `means` 정의문에서 주어("the affected work unit")를 문면 밖 지시에서 풀었다
- **주의**: 원문은 "shares no blocked output …" 이라고만 하고 **무엇과 공유하지 않는지를 말하지 않는다.** 정본에 `with the blocked work` 를 채워 넣었다. 이것은 복원의 경계에 있다 — 문면에 선행사가 없고 문맥으로만 결정된다
- **미분해**: 열거 12항(`blocked output` … `status`)은 원소로 세우지 않았다. **12항 전부가 원문 어디에도 정의되지 않아** 원소로 세우면 판정 불가능한 원소 12개가 된다. `_work/rule-conflict-routing.extract.md` 「자르지 못한 것」 1번

```text
ANCHOR RE-00057
  PATH:  snippets/rules/rule-conflict-and-revision-routing.md
  HASH:  a67eca8
  QUOTE: means the affected work unit shares no blocked output
  MEANS: conflict-isolated 의 정의문
  VERIFY: 매치 1
```

### RE-00058 — `conflict-unit-blocking`

> A work unit is `conflict-unit-blocking` when it is not `conflict-isolated`.

- **출처**: 저작 — 원문은 이 토큰을 16행의 조건문으로만 도입하고 정의문을 두지 않는다
- **주의**: 원문 16행("If every isolation condition is not established …")은 **부정 작용역이 두 가지로 읽힌다.** 이 정본은 「전부 성립하지는 않으면」쪽 독해를 고정한 것이 아니라, 그 조건문에서 **판정 대상만** 떼어 정의로 세운 것이다. 조건 자체의 중의는 `RC-00066` 에 남아 있다. `_journal/FINDINGS.md` `F-15`

```text
ANCHOR RE-00058
  PATH:  snippets/rules/rule-conflict-and-revision-routing.md
  HASH:  a67eca8
  QUOTE: classify the affected unit as
  MEANS: 토큰 conflict-unit-blocking 이 정의 없이 도입되는 지점
  VERIFY: 매치 1
```

### RE-00059 — dependency containment

> Dependency containment is the classification of a work unit by what it shares with blocked work.

- **출처**: 저작 — 원문에서 이 어휘의 유일한 출처는 **H2 제목 `## Dependency containment`** 다. 16행이 그것을 본문에서 재사용하고 36행이 요건으로 요구하는데, 정의 문장이 없다

```text
ANCHOR RE-00059
  PATH:  snippets/rules/rule-conflict-and-revision-routing.md
  HASH:  a67eca8
  QUOTE: ## Dependency containment
  MEANS: 이 어휘의 유일한 출처인 H2 제목
  VERIFY: 매치 1
```

### RE-00060 — permission

> A permission is an authorization to carry out an operation.

- **출처**: 저작 — 원문 16행이 대조항으로만 쓴다

### RE-00061 — severity

> A severity is a rank of how serious a problem is.

- **출처**: 저작 — 원문 16행이 대조항으로만 쓴다

### RE-00063 — complete

> A unit is complete when its own acceptance conditions are met and no blocking dependency remains open.

- **출처**: 저작 — 원문은 `complete` / `completion` 을 11·17·27행에서 쓰고 정의하지 않는다

### RE-00064 — `canonical-ready`

> A unit is `canonical-ready` when it is eligible to enter the canonical review path.

- **출처**: 저작 — `snippets/` 전역에서 이 토큰은 원문 17행에만 존재하고 **어느 규칙도 정의하지 않는다**

```text
ANCHOR RE-00064
  PATH:  snippets/rules/rule-conflict-and-revision-routing.md
  HASH:  a67eca8
  QUOTE: canonical-ready
  MEANS: 이 토큰의 유일한 출현 지점
  VERIFY: 매치 1
```

### RE-00065 — `commit-ready`

> A unit is `commit-ready` when it is eligible to be committed.

- **출처**: 저작 — `RE-00064` 와 같은 상태
- **앵커**: `RE-00064` 와 같은 행
