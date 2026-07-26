# 원소 — 저작된 용어 정의

**원문이 쓰기만 하고 정의하지 않은 용어**의 정의. 전부 `출처 = 저작` 이다. class 기준은 `_journal/DECISIONS_LOG.md` `D-13`.

이 class 가 존재한다는 것 자체가 관측이다 — 합성 선언에 필요한 슬롯 45개를 채우려니 **원문 어디에도 없는 원소 12개를 새로 써야 했다.** `_journal/FINDINGS.md` `F-7`.

전부 `authority = false` 다.

각 원소의 앵커는 **그 용어가 원문에서 쓰이는 지점**을 가리킨다. 정의가 아니라 사용처다 — 정의가 없다는 것이 이 class 의 존재 이유이므로 정의 지점을 가리킬 수 없다.

---

### RE-00045 — 권위 분류

> 권위 분류는 어떤 규범을 Hard gate · Binding rule · Advisory 중 하나로 판정하는 일이다.

- **출처**: 저작 — 원문은 이 용어의 소유만 주장하고 뜻을 정의하지 않는다

```text
ANCHOR RE-00045
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 이 파일은 권위 분류와 처분을 소유하며
  MEANS: 용어 「권위 분류」가 정의 없이 쓰이는 지점
  VERIFY: 매치 1
```

### RE-00046 — 처분

> 처분은 어떤 claim 을 유지 · 축소 · 강등 · quarantine · 제거 · 이관 중 하나로 정하는 일이다.

- **출처**: 저작 — 처분 6종은 원문 23행에 열거로만 있고 각각의 뜻이 없다
- **앵커**: `RE-00045` 와 같음

### RE-00047 — 강등

> 강등은 규범에서 차단력을 제거하되 그 규범을 삭제하지 않는 처분이다.

- **출처**: 저작 — 원문은 "강등 후보다", "축소하거나 강등한다"로 쓰기만 한다
- **비고**: **이 정의가 이번 작업의 설계에서 온 것이지 원문에서 온 것이 아니다.** 설계의 「강등」 조항(*"강등되면 authority = false 가 되어 차단력을 잃는다"*, *"강등은 삭제가 아니다"*)을 원소로 옮겨 적었다. 원문이 뜻을 비워 둔 자리에 설계가 들어갔다 — `_journal/FINDINGS.md` `F-7`

```text
ANCHOR RE-00047
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 해당 primitive로 소급되지 않는
  MEANS: 용어 「강등 후보」가 정의 없이 처음 쓰이는 지점
  VERIFY: 매치 1
```

### RE-00048 — 작업 간 필수 load

> 작업 간 필수 load 는 어떤 작업을 하기 전에 반드시 읽어야 하는 문서를 두는 것이다.

- **출처**: 저작

```text
ANCHOR RE-00048
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 영구 rubric·registry·scanner·checklist 또는 작업 간 필수 load를 만들지 않는다
  MEANS: 용어 「작업 간 필수 load」가 정의 없이 쓰이는 지점
  VERIFY: 매치 1
```

### RE-00049 — PASS

> PASS 는 diagnostic 이 선언한 predicate 를 충족했다는 결과다.

- **출처**: 저작

```text
ANCHOR RE-00049
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: PASS는 해당 diagnostic이 선언한 predicate만 입증한다
  MEANS: 용어 PASS 가 정의 없이 쓰이는 지점
  VERIFY: 매치 1
```

### RE-00050 — 과잉 적용

> 과잉 적용은 상위 규칙이 자신의 scope 밖 작업을 막는 것이다.

- **출처**: 저작

```text
ANCHOR RE-00050
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 상위 규칙이 과잉 적용될 가능성이 있으면
  MEANS: 용어 「과잉 적용」이 정의 없이 쓰이는 지점
  VERIFY: 매치 1
```

### RE-00051 — 작업 보존

> 작업 보존은 중단 시점의 작업 산출물을 버리지 않고 남기는 것이다.

- **출처**: 저작
- **앵커**: `RE-00050` 과 같음

### RE-00052 — downstream workaround

> downstream workaround 는 상위 규칙을 고치지 않고 하위에서 우회 경로를 추가하는 것이다.

- **출처**: 저작

```text
ANCHOR RE-00052
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 정확한 clause, scope, enforcement path를 특정한 뒤
  MEANS: 용어 downstream workaround 가 정의 없이 쓰이는 문장의 시작
  VERIFY: 매치 1
```

### RE-00053 — 승인된 source 변경

> 승인된 source 변경은 사용자가 승인한 뒤 실제로 반영된 파일 변경이다.

- **출처**: 저작

```text
ANCHOR RE-00053
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 승인된 source 변경 후에만 발효되며
  MEANS: 용어 「승인된 source 변경」이 정의 없이 쓰이는 지점
  VERIFY: 매치 1
```

### RE-00054 — active owner

> active owner 는 어떤 규범의 현재 정의를 소유하는 표면이다.

- **출처**: 저작
- **비고**: 이 용어는 이 repo 의 다른 규칙 표면에서도 쓰인다. **원소 중복 여부는 이 파일럿 범위 밖**이며 B2 이후에 드러난다

```text
ANCHOR RE-00054
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: active owner에는 대상·scope·fallback·종료 조건만 기록한다
  MEANS: 용어 active owner 가 정의 없이 쓰이는 지점
  VERIFY: 매치 1
```

### RE-00055 — 전칭 claim

> 전칭 claim 은 예외 없이 성립한다고 주장하는 claim 이다.

- **출처**: 저작

```text
ANCHOR RE-00055
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 전칭 또는 절대 claim을 유지하기 전에
  MEANS: 용어 「전칭 claim」이 정의 없이 쓰이는 지점
  VERIFY: 매치 1
```

### RE-00056 — counterexample

> counterexample 은 claim 이 성립하지 않는 실제 사례다.

- **출처**: 저작
- **앵커**: `RE-00055` 와 같음
