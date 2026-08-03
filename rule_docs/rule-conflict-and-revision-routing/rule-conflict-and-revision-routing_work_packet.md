# rule-conflict-and-revision-routing Work Packet

> 이 Work Packet은 B04 회차의 source finding 처분, 구현 surface와 edge case를 매핑하는 non-authoritative temporary artifact다. 승인 대상·live rule·최종 normative wording·실행 기록·readiness 판정이 아니며 mutation/commit/push/adoption/activation을 승인하지 않는다.

## 회차 분석 범위

- source finding I17/I20/I31/I33의 현재 owner와 종결 상태 재구성.
- terminal rule에 흡수할 최소 의미와 owner-local backlog로 보낼 잔여 의미 분리.
- HN-02 유지 재정과 bootstrap checked-no-change 경계 추적.
- terminal landing에서 확인할 edge case, reviewer 질문과 비례 evidence 제안.

## Source finding 처분 map

| source | 현재 처분 | owner / durable surface | close point 또는 보존 경계 |
|---|---|---|---|
| I17 counter-framing | rerouted | agenda-local relay restore contract와 operator-local instruction surface | product-wide standardization은 별도 사용자 결정이 있을 때만 착수 |
| I17 provenance / non-retroactivity | 일부 absorbed, 잔여 explicitly unresolved | DWM self-amendment는 현 rule에 흡수됨; 일반 out-of-order lifecycle은 `DWM-B-20` | 다음 실제 소급 lifecycle 사례 또는 별도 scoped DWM goal |
| I17 cross-domain contrast | absorbed | DWM `Domain-local closure and cross-domain semantics` | commit `742e69d`의 active wording 유지 |
| I20 cheap-first / minimum evidence | absorbed | `subagent-work-orchestration` incubation candidate | 현 candidate 문면을 유지하고 세 pilot 뒤 promote/discard/continue 판단 |
| I20 legacy operator-combinable output JOIN | rejected | Blind rewrite decision | 사용자 재작성 경계(`99dcc98`) 유지 |
| I20 invocation member completeness | absorbed | no-background terminal accounting | B03 closeout `e8d0dea`에서 종결 |
| I20 cross-unit semantic JOIN | rerouted + explicitly unresolved | orchestration candidate의 open question | 세 pilot 뒤 candidate 처분 시 닫음 |
| I31 HN-02 broad pre-read/stop | retain; 과거 backlog 의무 철회 | 현 bootstrap 문면 | 2026-08-03 사용자 재정. bootstrap 수정·새 row 없음 |
| I31 HN-07 scope correction vs weakening exception | rerouted | `GFM-B-05` | 구체 exception/bypass 또는 별도 scoped GFM goal |
| I31 HN-10 non-PS1 encoding authority/enforcement | rerouted | `PFE-B-05` | 별도 scoped PFE goal 또는 false-pass/operational incident |
| I31 HN-12 | absorbed | DWM cross-domain semantics | commit `742e69d`의 active wording 유지 |
| I33 E-IU-1/2 | absorbed | dual-vendor activation/verify | B02 closeout `5829492`에서 종결 |
| I33 E-IU-3 | rerouted | canonical fan-out | manual copy를 authority로 사용하지 않는 현 경계 유지 |
| I33 E-IU-4 | absorbed | wrapper status handling | B02 closeout `5829492`에서 종결 |
| I33 E-IU-5 | context only | 새 owner 없음 | 구현·backlog로 승격하지 않음 |

## Terminal landing surface map

| surface | 이번 회차 mapping |
|---|---|
| `snippets/rules/rule-conflict-and-revision-routing.md` | 이 rule 아래 revision handoff의 수신 outcome, unresolved close point, 원 작업 resume/block/close 상태 보존만 추가 |
| `rule_docs/docs-working-model/docs-working-model_backlog.md` | 일반 out-of-order lifecycle provenance 잔여를 `DWM-B-20`으로 분리하고 next ID 증가 |
| `rule_docs/global-file-mutation-boundary/global-file-mutation-boundary_backlog.md` | scope correction과 safety-weakening exception의 lifecycle 경계를 `GFM-B-05`로 분리하고 next ID 증가 |
| `rule_docs/powershell-and-file-encoding/powershell-and-file-encoding_backlog.md` | non-PS1 encoding claim의 authority/enforcement 범위를 `PFE-B-05`로 분리하고 next ID 증가 |
| `snippets/rules/README.md` | terminal rule action class와 index admission이 그대로인지 확인. trigger scope가 불변이면 수정 없음 |
| `snippets/CLAUDE_SNIPPET.md`, `snippets/AGENTS_SNIPPET.md` | HN-02 유지와 기존 rule trigger route를 확인. 수정 없음 |
| DWM forms/checker/tests | 이번 semantic change를 직접 embody/enforce하는 form-bound dependency가 있는지 확인. generic schema/checker는 추가하지 않음 |

## Terminal meaning edge cases

| case | 확인할 경계 |
|---|---|
| caller가 handoff를 발신했지만 receiver가 아직 읽지 않음 | 발신만으로 terminal disposition이나 unblock이 생기지 않는가 |
| receiver가 `rerouted`를 기록함 | 새 owner와 close point가 재구성되며 원 작업 상태가 별도로 남는가 |
| receiver가 `explicitly unresolved`를 기록함 | 구체 close point가 있고 success/whole-task completion으로 읽히지 않는가 |
| receiver가 `rejected`를 기록함 | foreign owner의 이유 schema를 강제하지 않으면서 원 작업의 resume/block/close를 판단할 수 있는가 |
| owner가 기존 backlog나 report를 보유함 | 새 공통 queue를 만들지 않고 기존 surface를 재사용하는가 |
| ordinary informational handoff | 이 rule의 genuine conflict/revision 경계 밖에서 새 ceremony를 요구하지 않는가 |
| 여러 owner가 얽힌 conflict set | 각 owner outcome은 독립적이지만 affected unit 상태가 조기 완료로 세탁되지 않는가 |
| HN-02 | bootstrap 문면과 trigger route가 변경되지 않고 과거 의무가 새 row로 부활하지 않는가 |

## Evidence 제안

- **구조:** planning anchor exact-path, closeout 시 planning artifact 삭제, backlog next-ID 단조 증가와 row ID 유일성.
- **local correctness:** terminal outcome 네 종류, unresolved close point, origin status가 서로 재구성되는지 정적 반례로 대조.
- **system coherence:** distributed rule admission, snippet/index route 불변, DWM closeout, 각 backlog의 owner-local future-work 역할.
- **false-positive attacks:** ordinary handoff 과대 적용, `rerouted`/`unresolved` completion laundering, common schema 유입, HN-02 재개방, incident/relay ID의 distributed rule 유입.
- **mechanical:** DWM checker, PowerShell verifier, affected/full Pester, encoding/diff, payload/index parity. 새 test는 기존 suite가 놓치는 안정적 기계 predicate가 실제로 확인될 때만 고려.

## Reviewer 질문 준비

- terminal outcome 요구가 `Revision handoff`에만 결박되고 ordinary handoff를 확장하지 않는가.
- 수신 owner의 substantive decision과 이 rule의 transport meaning이 분리되는가.
- `explicitly unresolved`가 구체 close point 없이 영구 상태로 남거나 pass에 가까운 상태로 오독되지 않는가.
- originating work의 resume/block/close 상태가 outcome 분류와 별개로 보존되는가.
- owner-local backlog 세 행이 이미 시작한 작업·incident ledger·결정 기록이 아니라 실제 future work인가.
- HN-02 retain 재정이 bootstrap 수정이나 새 queue 없이 closeout report에만 정확히 남는가.
