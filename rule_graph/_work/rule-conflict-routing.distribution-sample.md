# 배포 자립 표본 — `Dependency containment` 절

B2 의 실측 산출물이다. `snippets/rules/rule-conflict-and-revision-routing.md` 의 **한 절**을 설계대로 완전히 처리해서, **원소 트리 없이 배포본만으로 자립하는지**를 잰다.

**대상 파일은 수정하지 않았다.** 8개 절 중 1개만 전환하면 파일이 반쪽 상태가 되므로, 전환 결과를 이 문서에 표본으로 둔다(`D-21`).

## 왜 이 절인가

`Dependency containment` 는 이 규칙의 **주 차단 트리거**를 담는다 — 어떤 작업 단위가 막히는지가 여기서 결정된다. 자립이 깨진다면 가장 크게 깨질 자리다.

## 원문 (13–17행)

```markdown
## Dependency containment

- `conflict-isolated` means the affected work unit shares no blocked output, state, assumption, invariant, owner contract, validator, transaction or commit boundary, acceptance gate, or coherence unit, and has independent evidence, acceptance, and status.
- If every isolation condition is not established, classify the affected unit as `conflict-unit-blocking`. These tokens describe dependency containment, not permission or severity.
- A user may prospectively rescope future work, but a later split cannot retroactively complete a blocked unit. Continuing isolated work does not make the blocked branch or whole task complete, canonical-ready, or commit-ready.
```

**5행 · 687자 · 692 bytes.**

## 추출 결과

| 구분 | 수 | key |
|---|---|---|
| 원소 | 9 | `RE-00057`–`RE-00065` |
| — 추출 | **1** | `RE-00062` |
| — 복원 | 1 | `RE-00057` |
| — 저작 | **7** | `RE-00058` `RE-00059` `RE-00060` `RE-00061` `RE-00063` `RE-00064` `RE-00065` |
| 합성 | 4 | `RC-00066`–`RC-00069` |
| — 방향 `정` | 1 | `RC-00066` |
| — 방향 `역` | **3** | `RC-00067` `RC-00068` `RC-00069` |

**원소 9개 중 문면 그대로 쓸 수 있는 것이 1개다.** 나머지 8개는 복원 1 · 저작 7 이다. B1 전체 비율(추출 9 / 37 = 24%)보다 낮다.

## 배포본 전환 결과 (`D-17` 합병 · `D-19` 추적 정보 제외)

아래가 `snippets/rules/rule-conflict-and-revision-routing.md` 에 실제로 들어갈 형태다. 앵커·출처 조각 id·실측은 배포 tier admission 조건(`snippets/rules/README.md:28` (d))에 따라 전부 제외됐다.

```markdown
## Dependency containment

**`[RC-00066]`** If a work unit does not establish every isolation condition, classify it as `conflict-unit-blocking`.

- `[RE-00057]` A work unit is `conflict-isolated` when it shares no blocked output, state, assumption, invariant, owner contract, validator, transaction or commit boundary, acceptance gate, or coherence unit with the blocked work, and has independent evidence, acceptance, and status.
- `[RE-00058]` A work unit is `conflict-unit-blocking` when it is not `conflict-isolated`.

**`[RC-00067]`** Do not read `conflict-isolated` or `conflict-unit-blocking` as a permission grant or a severity rank.

- `[RE-00059]` Dependency containment is the classification of a work unit by what it shares with blocked work.
- `[RE-00060]` A permission is an authorization to carry out an operation.
- `[RE-00061]` A severity is a rank of how serious a problem is.

**`[RC-00068]`** A later split does not retroactively complete a blocked unit.

- `[RE-00062]` A user may prospectively rescope future work.
- `[RE-00063]` A unit is complete when its own acceptance conditions are met and no blocking dependency remains open.

**`[RC-00069]`** Continuing `conflict-isolated` work does not make the blocked branch or the whole task complete, `canonical-ready`, or `commit-ready`.

- `[RE-00057]` A work unit is `conflict-isolated` when it shares no blocked output, state, assumption, invariant, owner contract, validator, transaction or commit boundary, acceptance gate, or coherence unit with the blocked work, and has independent evidence, acceptance, and status.
- `[RE-00063]` A unit is complete when its own acceptance conditions are met and no blocking dependency remains open.
- `[RE-00064]` A unit is `canonical-ready` when it is eligible to enter the canonical review path.
- `[RE-00065]` A unit is `commit-ready` when it is eligible to be committed.
```

## 실측

비공백 행 기준으로 실측했다.

| 무엇 | 행 | 자 | 원문 대비 |
|---|---|---|---|
| **원문 절** | 4 | 687 | 1.00× |
| **배포본 절** | 16 | **1865** | **2.71×** |
| 그중 합성 선언문 | 4 | 465 | 0.68× |
| 그중 원소 사본 | 11 | **1375** | **2.00×** |
| 원소 정본 (`rule_graph/elements/`, 배포 안 됨) | 9 | 857 | 1.25× |

**사본이 원문보다 길다.** 사본 11행 1375자가 원문 절 687자의 **2.00배**다.

원소 정본 합계(857자)보다 사본 합계(1375자)가 큰 것도 같은 이유다 — 사본은 중복을 포함하고 정본은 포함하지 않는다.

원인은 **중복**이다. `RE-00057` 이 두 합성(`RC-00066` `RC-00069`)에, `RE-00063` 도 두 합성(`RC-00068` `RC-00069`)에 각각 사본으로 들어간다. 사본 11행 중 **2행이 같은 내용의 재출현**이고, 그 2행이 사본 분량 1375자 중 **518자(38%)** 를 차지한다.

## B2 의 물음에 대한 답

로드맵이 정한 **설계가 틀렸다는 신호**는 다음이었다.

> 사본을 넣어도 배포본이 자립하지 않거나, **자립시키려면 사본이 원문 전체가 되어 복제의 의미가 사라진다**

### 자립하는가 — 조건부로 그렇다

배포본만 읽어도 **규범을 따를 수 있다.** 모든 참조 원소의 내용이 같은 파일 안에 있다.

따르지 **못하는** 것 두 가지가 남는다.

1. **`RE-00057` 의 열거 12항이 여전히 정의되지 않았다.** `blocked output` `owner contract` `validator` `acceptance gate` `coherence unit` 등이 무엇인지 배포본도 원문도 말하지 않는다. **분해가 이 문제를 만들지도 고치지도 않았다** — 원문에 이미 있던 구멍이 그대로 옮겨졌다
2. **`RC-00066` 의 부정 작용역 중의가 그대로 남았다.** 「전부 미성립」인지 「전부 성립하지는 않음」인지 배포본도 결정하지 않는다. 분해는 이 중의를 **드러냈지만 해소하지 못했다**

### 사본이 원문 전체가 되는가 — **그보다 더 커진다**

사본만으로 **2.00×**, 배포본 절 전체로 **2.71×** 다. 사본이 원문 전체가 되는 것이 아니라 **원문의 두 배가 된다.**

두 가지가 겹친다.

- **저작 팽창** — 원소 9개 중 8개가 원문에 없는 문장이다. 원문이 정의하지 않고 쓴 용어를 정의로 세우면 그만큼 늘어난다
- **참조 중복** — 한 원소가 여러 합성에 쓰이면 사본이 그 수만큼 복제된다. 이 표본에서 2회 중복이 사본 분량의 **38%** 다

두 번째가 **규모에 따라 악화된다.** 표본은 합성 4개짜리다. 파일 전체는 합성 26개이고 `conflict-isolated` 처럼 널리 쓰이는 원소는 훨씬 많은 합성에 복제된다.

### 전체 파일로 외삽

표본 배율 2.71× 를 그대로 적용하면 42행 3432자 → **약 9300자**다.

그러나 이것은 **하한**이다. 표본 4개 합성에서 이미 2회 중복이 났고, 전체 26개 합성에서는 중복률이 올라간다. 그리고 표본 절은 이 파일에서 **정의가 있는 유일한 절**이다 — 다른 7개 절은 정의된 용어가 0개이므로 저작 비율이 더 높다.

**이 외삽은 표본 1개에서 나온 것이며 전체를 수행해 확인하지 않았다.**
