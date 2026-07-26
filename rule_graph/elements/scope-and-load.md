# 원소 — 범위와 적재

규칙이 **어디에 적용되고 언제 읽히는가**를 진술하는 원소. class 기준은 `_journal/DECISIONS_LOG.md` `D-5`.

전부 `authority = false` 다. 원소는 차단하지 못한다(불변식 4).

---

### RE-00001 — `rule-authority` 의 적용 범위

> 규칙 `rule-authority` 의 적용 범위는 이 repo 내부다.

- **출처**: 저작 — 원문에는 제목행 괄호 표기 `(repo-only)` 만 있고 서술어가 없다
- **비고**: 표기를 문장으로 세운 것이므로 원문에 대응 문장이 없다

```text
ANCHOR RE-00001
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: # 규칙: 규칙 권위와 개정 (repo-only)
  MEANS: 제목행의 (repo-only) 표기. 이 원소가 문장화한 대상
  VERIFY: 매치 1
```

### RE-00002 — `rule-authority` 의 적재 조건

> repo 규칙을 저작·개정하거나 상위 규칙이 정당한 작업과 충돌할 가능성이 있을 때만 이 규칙을 읽는다.

- **출처**: 추출 — 문면 그대로
- **비고**: 규범(「읽는다」)이지만 작업을 막지 않는다. 설계가 원소에 허용한 *"경고와 권고"* 범위다

```text
ANCHOR RE-00002
  PATH:  rules/rule-authority.md
  HASH:  2ecb5b9
  QUOTE: repo 규칙을 저작·개정하거나
  MEANS: 이 규칙의 로드 트리거를 진술하는 문장의 시작
  VERIFY: 매치 1
```
