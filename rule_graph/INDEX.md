# INDEX — key 의 단일 소유자

이 파일이 **key → 정본 경로** 매핑을 소유한다. 발번도 여기서만 한다.

설계상 이 파일은 **개정 진입점**이며, `V1`(참조 무결성)이 읽는 유일한 입력이다. 그래서 좁게 유지한다 — 출처 앵커 블록은 각 원소 정본 옆에 있다(`_journal/DECISIONS_LOG.md` `D-3`).

## 발번 상태

| 항목 | 값 |
|---|---|
| 다음 발번 번호 | `00057` |
| 번호 공간 | **원소·합성 공유 단일 카운터** (`D-2`) |
| 반납된 key | 없음 |
| 재사용 금지 | 반납된 key 는 다시 쓰지 않는다 |

## 필드

| 필드 | 값역 |
|---|---|
| `key` | `RE-<5자리>` / `RC-<5자리>`. 참조할 때는 항상 대괄호로 닫는다 — `[RE-00001]` |
| `종류` | 원소 / 합성 |
| `상태` | 살아있음 / **발번됨(정본 미생성)** / 반납됨 |
| `authority` | `false` / `true`. **접두사가 아니라 이 필드가 권위의 현재 값을 소유한다** (`D-6`, `FINDINGS.md` `F-2`) |
| `방향` | `—` 막지 않음 / `정` 작업을 막음 / `역` 차단 주장을 막음 (`FINDINGS.md` `F-3`) |
| `정본 경로` | repo 상대 경로 |
| `출처` | `추출` 문면 그대로·부분 인용 / `복원` 문면의 선행사로 주어·조응을 채움 / `저작` 문면에 없는 문장 (`D-11`) |
| `생성` | 발번 시점 |

## 원소

| key | 종류 | 상태 | authority | 방향 | 정본 경로 | 출처 | 생성 |
|---|---|---|---|---|---|---|---|
| `RE-00001` | 원소 | 살아있음 | false | — | `rule_graph/elements/scope-and-load.md` | 저작 | 2026-07-27 |
| `RE-00002` | 원소 | 살아있음 | false | — | `rule_graph/elements/scope-and-load.md` | 추출 | 2026-07-27 |
| `RE-00003` | 원소 | 살아있음 | false | — | `rule_graph/elements/definition.md` | 추출 | 2026-07-27 |
| `RE-00004` | 원소 | 살아있음 | false | — | `rule_graph/elements/fact.md` | 추출 | 2026-07-27 |
| `RE-00005` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 저작 | 2026-07-27 |
| `RE-00006` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 저작 | 2026-07-27 |
| `RE-00007` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 저작 | 2026-07-27 |
| `RE-00008` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 복원 | 2026-07-27 |
| `RE-00009` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 복원 | 2026-07-27 |
| `RE-00010` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 저작 | 2026-07-27 |
| `RE-00011` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 저작 | 2026-07-27 |
| `RE-00012` | 원소 | 살아있음 | false | — | `rule_graph/elements/definition.md` | 추출 | 2026-07-27 |
| `RE-00013` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 저작 | 2026-07-27 |
| `RE-00014` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 저작 | 2026-07-27 |
| `RE-00015` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 저작 | 2026-07-27 |
| `RE-00016` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 저작 | 2026-07-27 |
| `RE-00017` | 원소 | 살아있음 | false | — | `rule_graph/elements/requirement.md` | 저작 | 2026-07-27 |
| `RE-00018` | 원소 | 살아있음 | false | — | `rule_graph/elements/definition.md` | 추출 | 2026-07-27 |
| `RE-00019` | 원소 | 살아있음 | false | — | `rule_graph/elements/fact.md` | 복원 | 2026-07-27 |
| `RE-00020` | 원소 | 살아있음 | false | — | `rule_graph/elements/fact.md` | 복원 | 2026-07-27 |
| `RE-00021` | 원소 | 살아있음 | false | — | `rule_graph/elements/fact.md` | 추출 | 2026-07-27 |
| `RE-00022` | 원소 | 살아있음 | false | — | `rule_graph/elements/fact.md` | 추출 | 2026-07-27 |
| `RE-00023` | 원소 | 살아있음 | false | — | `rule_graph/elements/definition.md` | 추출 | 2026-07-27 |
| `RE-00024` | 원소 | 살아있음 | false | — | `rule_graph/elements/fact.md` | 복원 | 2026-07-27 |
| `RE-00025` | 원소 | 살아있음 | false | — | `rule_graph/elements/fact.md` | 복원 | 2026-07-27 |
| `RE-00045` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |
| `RE-00046` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |
| `RE-00047` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |
| `RE-00048` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |
| `RE-00049` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |
| `RE-00050` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |
| `RE-00051` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |
| `RE-00052` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |
| `RE-00053` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |
| `RE-00054` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |
| `RE-00055` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |
| `RE-00056` | 원소 | 살아있음 | false | — | `rule_graph/elements/authored-term.md` | 저작 | 2026-07-27 |

**출처 분포** — 추출 9 · 복원 5 · 저작 **23**. 원소 37개 중 **원문 문장을 그대로 쓸 수 없는 것이 28 / 37 = 76%** 다.

`RE-00026`–`RE-00044` 는 **존재하지 않는다.** 그 번호 구간은 합성에 발번됐다(`D-2` 공유 번호 공간). 숫자에 의미는 없다.

### 역참조가 비어 있는 원소

| key | 내용 | 왜 비어 있는가 |
|---|---|---|
| `RE-00001` | `rule-authority` 의 적용 범위 | 쿡북만 참조한다. 쿡북은 그래프 밖이다 |
| `RE-00002` | `rule-authority` 의 적재 조건 | 같음 |
| `RE-00020` | Advisory 는 stale 하면 정리할 수 있다 | 어느 합성도 참조하지 않는다. 원문에 있던 허가가 그래프에서 고아가 됐다 |

설계는 *"`refs⁻¹(k) = ∅` 이 지속되면 강등·반납 후보로 부상"* 이라고 한다. 세 건 모두 **원문에 실재하는 내용**이므로 반납하면 규범이 사라진다. `_journal/FINDINGS.md` `F-8`

## 합성

key 는 `item-02` 에서 먼저 발번했고(`D-10`), 정본은 `item-03` 이 `rule_graph/composites/rule-authority.md` 에 생성했다. 19건 전부 `살아있음` 이다.

합성이 참조하는 슬롯 총합은 **45** 이며, 그중 12개가 `item-03` 에서 새로 저작한 원소(`RE-00045`–`RE-00056`)로 채워졌다. `\|S\| ≥ 2` 를 못 채운 것은 `RC-00027` 하나이고 방향이 `역` 이라 `D-7` 로 인정했다.

| key | 종류 | 상태 | authority | 방향 | 정본 경로 | 출처 조각 | 생성 |
|---|---|---|---|---|---|---|---|
| `RC-00026` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-03` | 2026-07-27 |
| `RC-00027` | 합성 | 살아있음 | true | 역 | `rule_graph/composites/rule-authority.md` | `RA-04` | 2026-07-27 |
| `RC-00028` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-05b` | 2026-07-27 |
| `RC-00029` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-07` | 2026-07-27 |
| `RC-00030` | 합성 | 살아있음 | true | 역 | `rule_graph/composites/rule-authority.md` | `RA-08` | 2026-07-27 |
| `RC-00031` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-09` | 2026-07-27 |
| `RC-00032` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-11` | 2026-07-27 |
| `RC-00033` | 합성 | 살아있음 | true | 역 | `rule_graph/composites/rule-authority.md` | `RA-14` | 2026-07-27 |
| `RC-00034` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-15` | 2026-07-27 |
| `RC-00035` | 합성 | 살아있음 | true | 역 | `rule_graph/composites/rule-authority.md` | `RA-18` | 2026-07-27 |
| `RC-00036` | 합성 | 살아있음 | true | 역 | `rule_graph/composites/rule-authority.md` | `RA-19` | 2026-07-27 |
| `RC-00037` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-20` | 2026-07-27 |
| `RC-00038` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-21` | 2026-07-27 |
| `RC-00039` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-22` | 2026-07-27 |
| `RC-00040` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-25` | 2026-07-27 |
| `RC-00041` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-26` | 2026-07-27 |
| `RC-00042` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-27` | 2026-07-27 |
| `RC-00043` | 합성 | 살아있음 | true | 정 | `rule_graph/composites/rule-authority.md` | `RA-28` | 2026-07-27 |
| `RC-00044` | 합성 | 살아있음 | true | 역 | `rule_graph/composites/rule-authority.md` | `RA-31` | 2026-07-27 |

`출처 조각` 은 `_work/rule-authority.extract.md` 의 조각 id 다. 조각 id 는 key 가 아니며 그래프에 들어가지 않는다 — 추출 작업 기록의 지역 라벨이다.

## 반납

없음.

반납이 발생하면 해당 행의 `상태` 를 `반납됨` 으로 바꾸고 `정본 경로` 를 `(반납)` 으로 둔다. **행을 지우지 않는다** — 지우면 그 번호가 미발번처럼 보여 재사용 금지를 지킬 수 없다.
