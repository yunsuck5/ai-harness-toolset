# 원소 — 요건

어떤 대상이 **무엇을 갖추어야 하는가**를 한 항목씩 진술하는 원소. class 기준은 `_journal/DECISIONS_LOG.md` `D-5`.

전부 `authority = false` 다. 요건 하나는 아무것도 막지 못한다 — 막는 것은 이 요건들을 **모두** 요구하는 합성이다.

**이 class 는 12개 중 10개가 저작이다.** 원문이 요건을 「명사구 나열 + 공통 서술어」로 압축해 써서 원자 단위가 문면에 존재하지 않는다. `_work/rule-authority.extract.md` 「자르지 못한 것과 그 이유」 참조.

---

## 상위 invariant 의 자격 요건 (`RC-00029` 가 참조)

### RE-00005 — 보호 primitive 요건

> 상위 invariant 는 명시적 scope 를 가진, 원자적이고 상호 충돌하지 않는 보호 primitive 를 갖춘다.

- **출처**: 저작 — 원문은 서술어 없는 명사구 "명시적 scope를 가진 원자적이고 상호 충돌하지 않는 보호 primitive"

```text
ANCHOR RE-00005
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 상위 invariant가 자격을 가지려면
  MEANS: 세 요건 명사구가 공통 서술어를 공유하는 문장의 시작
  VERIFY: 매치 1
```

### RE-00006 — 충돌 판정 기준 요건

> 상위 invariant 는 파생 규칙 간 충돌을 해소하는 판정 기준을 갖춘다.

- **출처**: 저작 — 원문은 명사구 "파생 규칙 간 충돌을 해소하는 판정 기준"
- **앵커**: `RE-00005` 와 같음 (같은 문장에서 나왔다)

### RE-00007 — 재개 채널 요건

> 상위 invariant 는 추가·개정·축소·강등·이관·제거 후 작업을 재개하는 정상적인 열린 채널을 갖춘다.

- **출처**: 저작 — 원문은 명사구 "추가·개정·축소·강등·이관·제거 후 작업을 재개하는 정상적인 열린 채널"
- **앵커**: `RE-00005` 와 같음
- **비고**: 이 원소가 로드맵 불변식 1(*"규칙 권위 주체가 신규추가·수정·삭제에 대한 정규채널을 보유한다"*)이 겨냥하는 지점이다. 원문에서 **서술어 없는 명사구로만 존재**했다

## Hard gate 의 자격 요건 (`RC-00031` 이 참조)

### RE-00008 — lifecycle 연결 요건

> Hard gate 는 결정 가능한 predicate 가 명시된 lifecycle transition 에 실제로 연결되어 있다.

- **출처**: 복원 — 원문에서 주어를 공급하는 label `**Hard gate**` 가 같은 줄에 있다

```text
ANCHOR RE-00008
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: **Hard gate** — 결정 가능한 predicate가
  MEANS: Hard gate 등급의 자격 조건 4개가 나열되는 줄
  VERIFY: 매치 1
```

### RE-00009 — claim·실패 단위 한정 요건

> Hard gate 는 claim 과 실패 단위가 한정되어 있다.

- **출처**: 복원
- **앵커**: `RE-00008` 과 같음

### RE-00010 — repair·resume 경로 요건

> Hard gate 는 사용할 수 있는 repair 또는 resume 경로를 갖춘다.

- **출처**: 저작 — 원문에서 이 항목과 `RE-00011` 이 서술어 "갖춘다" 하나를 공유한다. 떼어내려면 서술어를 복제해야 한다
- **앵커**: `RE-00008` 과 같음

### RE-00011 — 비례 요건

> Hard gate 는 claim 에 비례하는 coverage 와 차단 비용을 갖춘다.

- **출처**: 저작 — 위와 같은 이유
- **앵커**: `RE-00008` 과 같음

## Binding rule 의 명시 요건 (`RC-00032` 가 참조)

### RE-00013 — 보호 성질 명시

> Binding rule 은 보호 성질을 명시한다.

- **출처**: 저작 — 원문은 다섯 명사구가 서술어 "명시한다" 하나를 공유하고 주어가 생략돼 있다

```text
ANCHOR RE-00013
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: 보호 성질, scope, owner 또는 actor
  MEANS: Binding rule 이 명시해야 할 다섯 항목이 나열되는 문장
  VERIFY: 매치 1
```

### RE-00014 — scope 명시

> Binding rule 은 scope 를 명시한다.

- **출처**: 저작
- **앵커**: `RE-00013` 과 같음

### RE-00015 — owner 또는 actor 명시

> Binding rule 은 owner 또는 actor 를 명시한다.

- **출처**: 저작
- **앵커**: `RE-00013` 과 같음

### RE-00016 — evidence 와 counterevidence 명시

> Binding rule 은 evidence 와 counterevidence 를 명시한다.

- **출처**: 저작
- **앵커**: `RE-00013` 과 같음

### RE-00017 — 비례 경로 명시

> Binding rule 은 효과에 비례하는 모호성 해소·개정·이의·재개 경로를 명시한다.

- **출처**: 저작
- **앵커**: `RE-00013` 과 같음
- **비고**: `RE-00007` 과 같은 지점을 다른 등급에서 요구한다. 두 원소가 중복인지는 이 파일럿 범위 밖이며 B2 이후에 드러난다
