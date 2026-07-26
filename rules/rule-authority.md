# 규칙: 규칙 권위와 개정 (repo-only)

이 파일은 **쓰는 법**만 담는 쿡북이다. 규범의 정본은 원소와 합성이 소유하며, 진입점은 `rule_graph/INDEX.md` 다.

**언제 읽는가** — `[RE-00002]` repo 규칙을 저작·개정하거나 상위 규칙이 정당한 작업과 충돌할 가능성이 있을 때만.

## 규칙을 새로 쓰거나 고칠 때

1. clause × scope × enforcement path 단위로 본다. 파일 전체나 label 단위로 평가하지 않는다 — `[RC-00028]`
2. 어느 등급인지 정한다 → 아래 「등급을 판정할 때」
3. 상위 invariant 를 세우려면 세 요건을 전부 갖춘다 — `[RC-00029]`

## 등급을 판정할 때

| 등급 | 자격 | 막는가 |
|---|---|---|
| Hard gate | 네 요건 전부 — `[RC-00031]` | 예 |
| Binding rule | 다섯 항목 명시 — `[RC-00032]` | 예 |
| Advisory | `[RE-00018]` | 아니오 |

- diagnostic 이 실행 시 hard-fail 한다는 것만으로 hard gate 가 되지 않는다 — `[RC-00035]`
- PASS 는 그 diagnostic 이 선언한 predicate 까지만 입증한다 — `[RC-00036]`
- Advisory 를 읽지 않은 것은 결함이 아니다 — `[RC-00033]`
- Advisory 는 필수 registry·scanner·load·의례를 만들지 않는다 — `[RC-00034]`

## 상위 규칙이 작업을 막을 때

1. 영향받는 mutation 을 중단하고 작업을 보존한다 — `[RC-00037]`
2. 정확한 clause·scope·enforcement path 를 특정한다 — `[RE-00003]`
3. downstream workaround 를 추가하기 전에 그 상위 규칙을 감사한다 — `[RC-00038]`
4. 보호 primitive 로 소급되지 않는 강한 파생 규칙이면 **자동 삭제하지 않는다.** 강등 후보다 — `[RC-00030]`
5. 처분은 사용자 결정 후에 한다 — `[RC-00039]`

## 처분할 때

- 처분은 유지 · 축소 · 강등 · quarantine · 제거 · 이관 중 하나다 — `[RE-00046]`
- 처분은 active owner 와 enforcement 를 함께 바꾼다 — `[RE-00022]`
- quarantine 은 등급이 아니라 상태다 — `[RE-00023]`. 승인된 source 변경 후에만 발효된다 — `[RC-00040]`. active owner 기록은 대상·scope·fallback·종료 조건 네 항목만 — `[RC-00041]`
- 전칭·절대 claim 은 유지 전에 대안 realization 이나 counterexample 로 시험한다 — `[RC-00042]`. 견디지 못하면 축소하거나 강등한다 — `[RC-00043]`

## 이 규칙 자신에 대해

- 권위 분류와 처분의 정의는 이 규칙이 소유한다 — `[RC-00026]`
- 개별 규칙이 무엇을 규범하는지는 각 규칙이 소유한다 — `[RC-00027]`
- 이 규칙을 위해 영구 rubric·registry·scanner·checklist 또는 작업 간 필수 load 를 만들지 않는다 — `[RC-00044]`
- 이 규칙의 적용 범위는 이 repo 내부다 — `[RE-00001]`
- 이 규칙은 영구적으로 남길 최소 문면이다 — `[RE-00025]`

## 개정 진입점

**차단이 발생하면 그 자리에서 무엇이 막았는지를 key 로 말한다.** key 가 나오면 아래 표로 개정 진입점이 즉시 결정된다.

| 무엇을 고치려는가 | 어디로 |
|---|---|
| 위 항목 하나의 내용 | `rule_graph/INDEX.md` 에서 그 key 의 정본 경로 |
| 어떤 원소들의 조합인지 | `rule_graph/composites/rule-authority.md` |
| 원소의 문면 | `rule_graph/elements/` |

`RE-` 는 원소, `RC-` 는 합성이다. **막을 수 있는 것은 합성뿐이다.** 다만 강등된 합성은 `RC-` 접두사를 유지한 채 차단력을 잃으므로, **차단 가능 여부의 현재 값은 INDEX 의 `authority` 열이 소유한다.**

## 3-tier 축에 대한 주

이 규칙이 정의하는 `Hard gate / Binding rule / Advisory` 는 **조각 단위로** 적용된다. 파일이나 문단에 붙은 label 이 아니라 clause 마다 따로 판정한다 — 근거는 이 규칙 자신의 `[RE-00003]` 이다.

그 결과 `Advisory` 로 label 된 문단 안에도 차단하는 clause 가 있을 수 있다. 실제로 이 규칙의 이전 문면이 그랬다 — `[RC-00034]` 가 그 사례다. **label 을 보고 차단 여부를 판단하지 말고 clause 를 보라.**
