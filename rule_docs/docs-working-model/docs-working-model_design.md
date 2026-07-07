# docs-working-model Design — self-amendment governing-version (G1) + rule↔package-implementation 1:1 sync (G2) + live-rename `:95` scope 명확화 (G6-partial)

## Header

이 문서는 docs-working-model 규칙의 한 **revision 방향성 Design** 이다 — Track 3 gap 중 G1(자기참조 revision governing-version)·G2(rule↔package-implementation 1:1 sync)와, G6(live rename)의 dangling assertion `:95` 문장의 scope 명확화를 묶는다.
이 체인이 끝나면 terminal rule file(`rules/docs-working-model/docs-working-model.md`, 자기 자신이 spec-of-record — 별도 Spec 없음)이 G1 governing-version 조항 + G2 sync 게이트 + 명확화된 `:95` 를 담고, DWM-B-10 은 포섭·close 되며 G6-full·G7 은 reopen-trigger 를 단 backlog 행으로 등재된다.
이 문서가 아닌 것: G6-full live-rename 절차·G7 candidate identity/kind transition·공유 identity-change sweep primitive 추출(전부 defer)·rule↔form 완전 semantic 등가 검사기가 아니며, mutation/commit/push 승인이 아니다(1회 진술).

## 이 revision 의 지배 조건 — 고정 불변식 (decision-grade preamble)

G1 이 자기참조라 이 revision 자체가 self-revision 이므로, 메타 자기참조 가드에 따라 착수 전 불변식을 고정한다:

- **(I) 이 revision 의 지배 버전 = 기존 bootstrap 패턴 근거의 transitional declaration.** 이 revision 의 Design→Plan→landing→**closeout 까지(= 이 changeset 전체)** 는 개정-전 규칙 텍스트가 지배한다; 새 G1 조항은 *이 changeset 이후 시작되는* revision 부터 적용. **governing unit = changeset 전체(자기 closeout 포함) — landing 에서 끊기지 않는다**(그래야 자기 closeout 이 새 G1 로 재판정되어 self-reference 가 재개되는 hole 이 안 생긴다). **'이후 시작'의 well-definedness 는 State migration(`:176`)의 same-role-slot 선행-disposition 요구(seriality 강제)에 의존** — 병렬/중첩 revision seam 은 `:176` 이 닫는다(명시 의존). 근거: newly-introduced governance mechanism 은 자기 도입 changeset 에 적용될 수 없다(E5 `:112`·backlog-bootstrap `:128`·Transition check-enablement `:106` 와 동형). 이는 새 G1 의 self-application 이 *아니라* 기존 carve-out 패턴에 근거한 transitional 선언이다.
- **(II) 상수로 고정하는 foundational 원칙(정렬 앵커·변경 안 함):** artifact-class taxonomy(5분류)·single-home-plus-pointers·Design→Plan→Spec/terminal-rule lifecycle 와 Lifecycle invariant·Proportionality rule·docs≠authority(root Final hard rule)·incubation tier 와 **E1–E5 의 실질 의미**·reduced-two-level closeout gate 의 **구조**. E5 의 mechanism-specific 실질(incubation-can't-incubate-itself + pre-domain→pre-promotion 일반화)은 상수 — G1 은 E5 문장에 "이는 transitional-applicability 의 한 인스턴스" pointer 만 meaning-preserving 하게 덧댈 뿐 E5 실질을 재작성하지 않는다(Proportionality `:144` 급). 이 조건을 못 지키면 E5 는 상수 목록에서 빠지고 별도 edit target 이 된다(Plan 판정). (II) 원칙 자체 변경을 요구하는 설계 압력 = 별개의 더 큰 결정 → 멈추고 flag.
- **(III) 새 머신 금지 (정밀):** 새 state/marker/version-tracking *머신* 금지. G1 = 기존 bootstrap 2조항의 공통 패턴 명시. G2 = 기존 spec-of-record↔implementation 1:1 sync(`:130-136`)와 closeout inspect-and-report(`:152`)의 *listed-surface 집합 확장*(gate **구조** 불변) + **닫힌-스키마 구조검사 1블록 허용**(기존 check 패턴 재사용). **단 그 cheap 구조검사는 `:106-107` 'rule requirements now' 모델로 *즉시-binding*(구조 E1–E3 검사와 동형) — invariant (I) 이 유예하는 것은 lifecycle/process *governance*(G1 governing-version 조항·G2 closeout *의무*)이지 즉시-binding 구조검사가 아니다** (이 seam 은 G1·G2 를 한 revision 에 번들했기 때문 — G2 가 G1 후 별도 landing 이면 이미-개정 텍스트가 깔끔히 지배). G6 `:95` = 문면 명확화(새 절차 아님).
- **(IV) scope fence:** G6-full 절차·G7 identity/kind transition·공유 sweep primitive 추출은 non-goal.

## 왜 바꾸는가 / 무엇을 바꾸는가

Track 3 gap-landscape 조사의 수렴 결론: 세 지점이 규칙의 *자기-거버넌스* 를 미완으로 남긴다.

**G1 — self-revision governing-version.** 규칙은 자기 lifecycle/governance 조항을 스스로 개정하지만(자기 spec-of-record) *어느 버전이 그 self-revision 을 지배하는지* 일반 조항이 없다. 현존은 E5·backlog-bootstrap 두 *특정* carve-out 뿐이고 일반 원칙은 세션-외에만 있어 매 self-revision 이 재litigation 된다.
- **semantic target(paraphrase — 최종 문구는 Stage 2):** "이 규칙의 lifecycle/governance 조항을 개정하는 changeset 은 그 changeset 전체(자기 closeout 포함)까지 개정-전 텍스트가 지배하고, 개정-후 텍스트는 이 changeset 이후 시작되는 작업을 지배한다; 새 mechanism 을 도입 changeset 자신에 쓰려면 *자기 고유의* 명시 transitional carve-out 이 필요하다."
- **generalization 축 = (b) 확정.** 상위항 "newly-introduced governance mechanism 의 transitional applicability" 아래 governing-version·E5·backlog 세 형제 인스턴스((a) governing-version-이 둘을-포섭 안 함 — E5 의 self-non-application 을 version 으로 억지 편입하면 납작해짐). **상위항 의미(Design 고정)** = "새로 도입되는 각 mechanism 은 자기 도입 changeset 에 *자동 적용되지 않고*, 그 changeset 이 *자기 고유의 명시 transitional carve-out* 을 필요로 한다 — **구조적 self-non-application·동형(isomorphism)이지 precedent-borrowing/자동 면제가 아니다**(E5 `:112`·backlog `:128` 의 "not a precedent" 보존)". 라벨 wording 은 R1(축은 확정). 각 인스턴스 mechanism-specific 실질 보존(과병합 금지); backlog `:128` 의 "mirrors ... E5" 교차참조는 새 single-home 으로 re-point.
- **governing unit** = changeset 전체(closeout 포함; seriality 는 `:176` 의존 — 위 (I)). part "same-changeset self-use carve-out"의 실 referent = E5·backlog·`:106`·이 revision 자신; `:106-107` "rule requirements now"(즉시-binding 구조검사 *timing*)와는 *다른 축*(governance-version)임을 Plan 명시 정합(R6).
- 이 일반화가 하위 사례 DWM-B-10 을 포섭.

**G2 — rule ↔ package-implementation 1:1 sync.** 규칙 본문(spec-of-record)이 모델을 정의하고 package 산출물이 이를 구현/집행하는데, 본문 변경 시 그 구현 surface 가 1:1 동기됐는지 강제하는 조항이 없다. 이 desync 클래스는 실측 2회 재발(prelive marker·rule-output-forms)했고 매번 가장 비싼 canonical cross-FILE 게이트만 포착.
- **framing(정밀)**: G2 는 "rule body 가 surface 를 *지배*"가 아니다(그건 `:20/:210` active-surface-owns-behavior 와 충돌). **용어(`:209` 정합)**: 'package forms' = templates/checklists(규칙 `:209` 고정 용어) / check script·tests = 'package implementation·validation surfaces'(forms 아님); 상위어 = **package implementation surfaces**(둘 다). **embodiment vs behavior-ownership(ownership-boundary·`:60` Design 소유)**: template 은 *동시에* (a) `:20` active surface 로서 *자기 behavior 소유* + (b) 규칙의 normative 요구를 *embody*. G2 가 sync 하는 건 (b)의 spec↔embodiment 대응이지 (a)를 override 하거나 rule 이 surface 에 authority 를 주장하는 게 *아니다*(`:210` 보존). 즉 G2 = 기존 spec-of-record↔implementation 1:1 sync(`:130-136`)를 이 규칙의 package implementation surfaces 까지 확장 + closeout inspect-and-report(`:152`) listed-surface 집합 확장(rule-package 보유 규칙 한정 **Level-2 package-local extension** — 구조 불변·집합만 확장, `:150-155` "domain-local"에 억지 편입 안 함).
- **"form-bound 진술" intensional 기준(Design 소유)**: 한 rule 진술은, *그 surface 가 없으면 produced artifact 나 check behavior 가 규칙 의미를 구현하지 못할* 때 form-bound 다(단순 'embody 가능'이 아니라 *구현-필수*). 이 기준은 **Direction-1**(rule 진술→form embodiment; `:133`)의 기계화 경계; **Direction-2**(orphan form-element→normative sentence; `:134`)는 기계화 아닌 closeout process 의무(Plan 이 커버 확인). 대표 예: Spec-identity 8-section 열거·lifecycle-marker 셋·rule-output-forms 열거·content-boundary·checklist-tested 의무. 닫힌 *목록* 은 R2.
- **cheap 구조검사 조각(정직한 커버리지)**: spec-template *파일* 이 규칙 `:69` 8-heading + `:67` 3-marker 를 담는지의 닫힌-스키마 존재검사(template path 한정). 이는 desync 클래스의 *기계화 가능한 조각* — **prelive-급 재발(template-menu 에서 marker 누락, 09aced5)은 커버**하나, rule-output-forms 재발(check-script 3형태 로직 `:234-238` 소관)은 *미커버*(그건 process 의무). 즉 cheap check = template-menu drift tripwire; 클래스 전량은 process 의무. EN-2(produced spec·정확히 1 marker)와 다른 target·역극성이라 중복 아님(R3 hermetic).

**G6 `:95` — dangling assertion scope 명확화.** `:95` 의 "On rule rename the folder is renamed/migrated; on rule deletion the folder is deleted (no orphan)"는 *절차가 존재하는 듯* 읽히나 실제 live 절차는 부재(G6-full 은 defer).
- **성격(정밀)**: 이 명확화는 "폴더만 바꾸면 *불충분*"이라는 *새 normative insufficiency-boundary* 를 주장하지 *않는다*. 대신 이 조항의 *scope 가 folder-step 뿐이고 전체 live-rename/deletion 절차는 여기서 정의되지 않는(future work)* 다는 scope-clarification pointer 다(meaning-preserving 급). backlog 는 item-ID/next-ID 복사 없이(`:71`) *개념* future-work pointer 로만 가리킨다.
- **live guard 명시**: `:95` 의 no-orphan/folder 의무는 이미 `RULE_DOCS-ORPHAN` 검사(script `:280-282`·state-independent guard `:250-251`)로 *기계 집행 중* — 이 명확화는 그 folder/no-orphan 의무를 *약화하지 않고*(약화 시 live check 와 desync), 오직 *더 넓은 절차* 만 future-work 로 표시한다. RULE_DOCS-ORPHAN 이 folder 의무 binding 을 강제하는 guard-rail.
- **paired-sentence sibling**: `:95` 는 rename·deletion 두 half 의 paired 진술 — 두 half 를 대칭 명확화(한 half 만 고치면 intra-doc sibling-desync).
- Proportionality 상 direct-edit 급이나 이 revision 안에서 함께 검토(abuse-guard `:148` doubt→lifecycle 정합).
- **이 revision 의 package 정합 = voluntary alignment**(기존 `:152` inspect-and-report 정신 + G2 가 요구할 것을 미리 맞춤); 단 그중 *cheap 구조검사* 는 (III) 대로 즉시-binding.

## Owner surface model

terminal rule file `rules/docs-working-model/docs-working-model.md` 가 세 조각의 normative 문면을 소유(rule = 자기 spec-of-record; class/invariant/approval-boundary 만 진술, behavior 미흡수):
- **G1 조항** = transitional-applicability 상위항 + governing-version 인스턴스(+ E5/backlog re-point). 집행 = closeout-checklist 항목(process gate); 기계검사 없음.
- **G2** = spec-of-record↔implementation 1:1(`:130-136`)의 package implementation surfaces 확장 + closeout Level-2 listed-surface 집합 확장(신규 중복 item 아님·구조 불변). cheap 구조검사 소유 = `scripts/docs-working-model-check.ps1`(template-path 닫힌-스키마 존재검사·즉시-binding) + `tests/docs-working-model-check.Tests.ps1`. SCOPE INFO(script) + PASS/FAIL 요약태그 확장 필요.
- **"8-section" fact single-home = 규칙 `:69`**(enumerating home); template 은 그 embodiment; cheap check 는 Direction-1 realization(`:43` 금지-중복 아님). (Plan 미루기 제거 — framing 이 답함.)
- **G6 `:95`** = 기존 문장 소유 위치 불변·문면만 scope-명확화 + 개념 future-work pointer.
- **backlog** = G6-full·G7 행·next-ID 소유(단일 home). glossary = 이 revision 신규 term 없음.

## 수정 대상

- **rule 본문**: G1 조항 신설(배치 R1) + E5 `:112`·backlog `:128` 에 meaning-preserving 인스턴스-pointer(실질 보존) + backlog "mirrors E5" re-point; G2 를 closeout `:150-155`(listed-surface 집합) + conformance-gate `:205-210` 에 확장; `:95` 두 half 대칭 scope-명확화.
- **check + tests**: `docs-working-model-check.ps1` template-path 8-heading+3-marker 존재검사 1블록 + SCOPE INFO/요약태그 확장; `docs-working-model-check.Tests.ps1` 회귀(fixture 배치 주의).
- **package forms**: `checklists/docs-working-model_closeout_checklist.md` — G1 governing-version 항목 + G2 sync 항목(listed-surface 확장 형태); 그 외 template/checklist 는 voluntary alignment 로 checked—no change 확인.
- **backlog**: DWM-B-10 close(G1 포섭); G6-full·G7 행 신설(reopen trigger); next-ID 진행.
- **docs/README.md**: 대체로 rule-internal — Level-1 orientation 변화 최소 예상; closeout 판정.

## 하지 않을 것 (non-goals)

- G6-full live-rename 절차·G7 candidate merge/rehome 및 넓은 identity/kind-transition 클래스(split·rename-before-promotion·kind-change)·공유 identity-change sweep primitive 추출 — triggered backlog defer(과통합·미밟힌 edge 방지).
- G2 의 full semantic rule↔form 등가 검사기 — 닫힌-스키마 조각만 구조검사, 나머지 process 의무.
- foundational 원칙(불변식 II) 변경·재구조화 — artifact-class/lifecycle/proportionality/incubation/E1–E5 실질·closeout gate 구조는 상수.
- rejected terms/domains 부활·broad cleanup·scope creep 차단.

## Plan readiness / open risks

이 Design 은 Plan 으로 내려갈 수 있다(방향·scope·불변식·governing-unit·form-bound 기준·generalization 축·G2 surface 용어 고정). Plan 이 닫을 approval-target 결정(세 sub-change 를 **분리 approval target** 으로) + open risk:

- **R1 (Plan)** — G1 조항 배치(Proportionality 인근 vs State-migration 형제 vs 신규 절) + genus 라벨 wording(축은 (b) 확정) + E5/backlog 인스턴스-pointer 최소 편집(실질 보존).
- **R2 (Plan)** — "form-bound 진술"의 **닫힌 목록** 확정(intensional 기준은 Design 고정; 목록만 Plan) + **Direction-2(orphan form-element) closeout 커버 확인** → validation-expectation.
- **R3 (Stage2)** — cheap 검사 hermeticity(heading 포맷)·template-path 한정·EN-2 비촉발·신설출력↔기존 negative-assertion 전수 대조·SCOPE INFO 정합 → mechanical-green.
- **R4 (backlog·이 revision 밖)** — G6-full·G7·sweep-primitive reopen trigger = 실제 live rename/candidate merge·rehome 필요 or DWM-B-09 promotion 임박; G7↔DWM-B-05(cross-folder E3) 중첩 명기.
- **R5 (검증 비례)** — load-bearing self-revision → Stage 2 = dual-blind + canonical dual(s17 패턴); 조각별 비례(`:95` proportionality-level).
- **R6 (Plan)** — G1 governance-version 축 ↔ `:106-107` "rule requirements now"(즉시-binding 구조검사 timing) 명시 정합(두 timing 규칙 교차 금지).
- **R7 (Plan/closeout)** — DWM-B-10 은 `:128` 편집이 그 *literal* 문면-gap("later revision 이 도입 revision 자기 closeout 을 덮나")을 해소할 때 close(추상 umbrella pointer 만으로 부분-close 금지).
