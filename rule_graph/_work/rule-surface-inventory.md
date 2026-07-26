# 규칙 표면 전수와 4동작 채널

B5(종결 판정)의 입력이다. 종결 기준은 *"현존 규칙이 모두 평가 대상에 올라가고, 그 모든 규칙에 결과와 목표를 동일한 기준으로 적용한다"* 이며, 확인 방법은 *"규칙을 세고, 각각에 대해 4동작(추가·수정·삭제·재개) 채널이 정의됐는지 확인하고, 전부 예면 닫힌다"* 다.

**이 문서는 그 세기와 확인의 결과다.** 조사는 서브에이전트가 수행했고 근거는 전부 파일:줄로 확인됐다.

## 판정 기준

그 표면의 **문면 안에** 다음이 정의되어 있는가.

- **추가** — 새 조항을 넣는 경로
- **수정** — 기존 조항을 고치는 경로
- **삭제** — 조항 또는 규칙 자체를 없애는 경로
- **재개** — 그 규칙이 작업을 막았을 때 막힌 작업을 다시 진행시키는 경로

## 표면 수 — 36

| tier | 수 | 내역 |
|---|---|---|
| repo-only `rules/` | 14 | 규칙 5 + checklist 6 + template 3 |
| 배포 `snippets/rules/` | 5 | README + 규칙 4 |
| bootstrap | 2 | `CLAUDE_SNIPPET.md` · `AGENTS_SNIPPET.md` |
| 루트 instruction | 1 (파일쌍, 규범 절 6) | `CLAUDE.md` = `AGENTS.md` 공유 본문 |
| 그 밖의 규범 소유 주장 | 9 | `INSTALL.md` · skill 4 · template 2 · `tests/README.md` · `CONTRIBUTING.md` |

로드맵의 「규칙 표면 24」와 다르다. 이 조사는 **자기 문면에서 규범 소유를 주장하는 것**을 전부 셌고, checklist·template·skill·`CONTRIBUTING.md` 를 포함했다.

## 결과 — 4동작 채널

### 자기 채널을 스스로 정의한 표면: **2 / 36**

| 표면 | 추가 | 수정 | 삭제 | 재개 |
|---|---|---|---|---|
| `rules/rule-authority.md` | 정의됨 | 정의됨 (목적지가 `rule_graph/`) | 옵션 열거 수준 — 「제거」가 처분 선택지로 있으나 절차 없음 | 부분 — 차단 처리 절차는 있고 종점이 사용자 결정 |
| `rules/terminology-glossary.md` | 정의됨 | 정의됨 | **정의됨** — 항목 제거 처분 | 없음 |

`terminology-glossary.md:8` 이 **이 repo 전체에서 조항 삭제를 명시적으로 채널화한 유일한 문면**이다. 그 적용 범위는 용어집 항목뿐이다.

### 나머지 34 표면

4동작이 전부 `없음` 이거나, **다른 표면이 대신 정의**한다. 대신 정의하는 쌍은 14건 확인됐다(`X1`~`X14`). 대표적인 것:

| 정의하는 쪽 | 대상 | 동작 |
|---|---|---|
| `rules/rule-authority.md` | repo 내 모든 규칙 clause | 추가·수정·처분 |
| `rules/docs-working-model/docs-working-model.md:47-55` | 모든 domain Spec 및 terminal rule | 추가·수정 |
| `snippets/rules/no-background-or-hidden-state.md:8-9` | managed trigger 를 채택하는 모든 owner | 추가·수정·**삭제** |
| `snippets/rules/rule-conflict-and-revision-routing.md:31,36-37` | 모든 active rule owner | 수정·**재개** |
| `CONTRIBUTING.md:51-62` | `INSTALL.md` · docs-working-model · marker 정책 · verdict contract 등 | 추가·수정 개시 |

`rule-conflict-and-revision-routing.md` 가 **이 repo 에서 「재개」를 정면으로 채널화한 유일한 표면**이다. B2 대상으로 이 파일을 고른 것(`D-16`)이 결과적으로 트랙의 불변식 1 에 가장 가까운 파일을 고른 것이 됐다.

### 삭제 채널 — **규칙 파일 자체를 삭제하는 경로는 0 / 36**

| 표면 | 문면 | 실제 대상 |
|---|---|---|
| `terminology-glossary.md:8` | "항목을 제거하는 처분" | 용어집 **항목** |
| `rule-authority.md:36` | "유지 · 축소 · 강등 · quarantine · **제거** · 이관" | 「제거」가 선택지로만 열거. 절차·단위·참조 정리 없음 |
| `rule-authority.md:31` | "**자동 삭제하지 않는다**" | 삭제 **억제** |
| `docs-working-model.md:173-174` | "Design and Plan retired by deletion; Work Packet deleted" | **임시 lifecycle artifact** |
| `docs-working-model.md:107` | "On discard, the incubation file is deleted" | **후보** 문서 |
| `docs-working-model.md:188` | "Once live, change uses the **normal repeal/supersede lifecycle**." | **이름만 언급.** `repeal`/`supersede` 는 규칙 tier 전체에서 이 1회뿐이고 **정의된 곳이 없다** |
| `global-file-mutation-boundary.md:19` | "Removal is also a managed-payload operation" | **adopter 파일의 payload 인스턴스** |
| `snippets/rules/README.md:30` | "explicitly discarded with recorded rationale" | 규칙에 넣을 **content** |

**git 이력 대조** — 규칙 표면 관련 커밋 64건 중 삭제 0건, 이름변경 1건(`0ee9863`, 패키지 이동). 로드맵의 「규칙 파일 삭제 이력 0건」이 재확인됐고, **문면상으로도 경로가 없다**는 것이 추가로 확인됐다.

## 기계 강제

**활성 git hook 0개** (`.git/hooks/` 에 `.sample` 만), **CI workflow 0개** (`.github/` 부재). 따라서 아래는 `M8` 하나를 빼고 **전부 실행해야만 강제**된다.

| # | 지점 | 규칙 표면을 실제로 검사하는가 |
|---|---|---|
| `M1` | `scripts/docs-working-model-check.ps1` | **예** — `rules/**` · `snippets/rules/**` 를 스캔. 자기 문면에서 *"lifecycle hard gates = 0"* 선언(`:783`) |
| `M2` | `tests/docs-working-model-check.Tests.ps1` | **아니오** — 전 호출이 `$TestDrive` 합성 트리. **Pester 전체를 돌려도 실제 규칙 트리는 한 번도 스캔되지 않는다** |
| `M3` | `tests/repo-local-instruction-parity.Tests.ps1` | **예** — 루트 두 파일. 검사 내용은 **「두 파일이 같은가」뿐** |
| `M4` | `scripts/verify-ps1.ps1` | 아니오 — `scripts/**/*.ps1` 만 |
| `M6` | `scripts/apply-managed-block.ps1` + 테스트 | 부분 — 실제 `snippets/CLAUDE_SNIPPET.md` 는 검사. `AGENTS_SNIPPET.md` 는 **검사 없음** |
| `M7` | `scripts/lib/install-pipeline-core.ps1` | 부분 — payload 바이트 무결성. **개별 규칙 파일 존재를 단언하는 테스트 0건** |
| `M8` | `.gitattributes` | **자동.** 줄바꿈만. BOM 은 강제하지 않는다 |

### 확인된 기계 강제 공백

1. `snippets/AGENTS_SNIPPET.md` 의 마커 쌍 형식 검사 없음
2. 두 snippet 간 대칭성 검사 없음 — 루트 `CLAUDE.md:23` 이 요구하는데 대응 테스트 0건
3. bootstrap 의 「2-H2」 형태를 검사하는 지점 없음
4. `snippets/rules/*.md` 개별 파일 존재를 단언하는 테스트 0건
5. `.md` = UTF-8 **without** BOM 규칙(`rules/powershell-and-file-encoding.md:18`)에 대응하는 기계 검사 **없음**

## 이 조사가 확인하지 못한 것

- `rule_graph/**` 내용 — 조사 범위에서 제외했다. 따라서 `rules/rule-authority.md` 의 「수정 = 정의됨」은 **라우팅이 존재한다**는 사실까지이고, **목적지가 채널을 갖는다**는 뜻이 아니다
- `ai-harness-review/SKILL.md`(274행) · `ai-harness-consultation/SKILL.md`(264행) · `INSTALL.md`(626행) 전문 — 대상 어휘 grep 범위 내 결론이다
- `tests/` 30개 스위트 전수 — 규칙 표면 경로를 키로 한 grep 기반이다
- `config/reviewer.json` / `.schema.json` — 산문 규범이 아니라고 판단해 제외했으며, 그 판단은 파일 유형만으로 내렸다

## B5 에 대한 함의

트랙의 불변식 1 은 *"규칙 권위 주체가 신규추가·수정·삭제에 대한 정규채널을 보유한다"* 이다.

| 동작 | 자기 채널을 가진 표면 |
|---|---|
| 추가 | 2 / 36 |
| 수정 | 2 / 36 |
| **삭제** | **0 / 36** (조항 삭제는 1, 규칙 삭제는 0) |
| 재개 | 0 / 36 (부분 다수, 정면 채널화는 타 규칙에 대해 1) |

**현재 상태에서 불변식 1 은 성립하지 않는다.** 이것은 이 설계의 실패가 아니라 **설계가 겨냥한 대상의 현재 상태**이며, B5 판정의 기준선이다.
