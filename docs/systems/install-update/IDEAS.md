# install-update — idea-only notes

> **이 문서는 idea-only notes 다.**
>
> - **Not planned work.**
> - **Not implementation backlog.** `docs/systems/install-update/BACKLOG.md` 의 IU-B-* row 가 아니다.
> - **Not deferred implementation scope.** `docs/systems/install-update/DEFERRED.md` 의 reopen-조건부 deferred 항목과도 분리된 class.
> - **No planning / design / implementation 진행 — 별도 user 명시 결정 (별도 scoped `/goal` + Codex review gate) 없이는 어떤 작업도 시작하지 않는다.**
>
> 본 문서의 목적은 install-update subsystem 의 candidate 중 **deferred backlog 도 아니고 implementation 대상도 아닌** idea 들을 durable source-managed 문서에 기록하여 future operator turnover / long-term governance review 시점에서 누락되지 않도록 하는 것이다. 형식과 의의는 `docs/systems/review/IDEAS.md` 의 idea-only durability mitigation 을 참고하되, install-update 의 lifecycle 맥락에 맞게 별도로 작성한다 (복제 아님).

## Relationship to other surfaces

- `docs/systems/install-update/BACKLOG.md` (IU-B-* row) — implementation candidate 의 entry point. Phase 4b candidate (One-shot natural-language update completion / safe activation auto-apply) 의 triage-level row 는 BACKLOG.md 에 있으며, 그 row 가 본 IDEAS.md 의 항목 1 을 참조한다. 본 IDEAS.md 항목의 promotion-to-implementation 은 (1) reopen criteria 충족 + (2) BACKLOG row 의 explicit entry + (3) user 의 별도 scoped `/goal` + (4) Codex review gate 의 4 단계 모두 충족 시에만 가능.
- `docs/systems/install-update/STATUS.md` — install-update subsystem 의 current status. Phase 4a (activation apply orchestration) 의 완료 + main PC / notebook PC global dogfood 완료 + original Phase 4 one-shot goal 미완료가 STATUS.md current state 에 기록되어 있다. 본 IDEAS.md 항목 1 은 그 "미완료로 남은 original objective" 의 idea-only 기록이다.
- `INSTALL.md` — install/update/activation 의 operative contract. 본 IDEAS.md 는 INSTALL.md 의 현행 동작을 변경하지 않으며, INSTALL.md 가 codify 한 현행 동작 (update-source = payload mutation + activation byte-identity verify-only; activation apply = 별도 `scripts/activate-global.ps1` step + explicit approval) 을 전제로 한 future candidate 만 기록한다.
- `docs/systems/install-update/GLOBAL_INSTALL_UPDATE_MODEL.md` — operating model/design. 본 idea 가 구현으로 promote 될 경우 model 문서의 갱신이 동반되어야 하나, 본 IDEAS.md 안에서 그 변경은 없다.

## Idea-only items

### 1. One-shot natural-language update completion / safe activation auto-apply

**Original intended behavior.** Phase 4 의 원래 핵심 목표는, 단일 자연어 업데이트 지시 한 번으로 — 추가 yes/no 승인 입력 없이 — payload 업데이트부터 safe activation apply 까지 완결되는 흐름이었다:

```
사용자: "ai-harness-toolset 최신버전으로 업데이트해줘"
  → latest source acquisition (최신 소스 획득)
  → latest INSTALL.md re-adoption (최신 INSTALL.md 재적용)
  → inspect (설치 상태 점검)
  → update-source (payload 갱신)
  → safe activation preflight (activation 안전성 사전 점검)
  → activation apply without extra yes/no approval (추가 yes/no 승인 없이 activation 적용)
  → final verify_pass (최종 검증 통과)
  → cleanup (정리)
  → final report (최종 보고)
```

즉 "업데이트해줘" 한 번으로 acquisition → re-adoption → inspect → update-source → preflight → activation apply → verify → cleanup → report 가 추가 승인 round-trip 없이 끝나는 것이 의도였다.

**Current implemented Phase 4a behavior.** 현재 구현된 동작은 위 one-shot 완결과 다르다. 자연어 업데이트 지시는 payload 갱신까지 도달한 뒤 activation 은 별도 명시 승인 단계를 거친다:

```
자연어 update 지시
  → payload update (update-source; command-implied approval)
  → activation_pending (activation drift 시 follow-up 필요로 보고)
  → dry-run (activate-global -DryRun; 3 surface preview)
  → explicit activation approval (사용자의 별도 명시 활성화 승인)
  → activation apply (activate-global -Apply)
  → verify_pass
```

Phase 4a 가 한 것은 activation apply 의 **substrate / coverage alignment** — install-update 가 verify 하는 3 surface 전부를 apply 가 cover 하도록 shared resolver 로 정렬하고, managed-block / canonical-overwrite 두 mutation class 의 apply orchestration 을 마련한 것이다. 그러나 "추가 yes/no 없이 자연어 지시 한 번으로 activation 까지 완결" 이라는 original objective 자체는 구현하지 않았다 — activation apply 는 여전히 별도 explicit approval step 이다 (의도된 현행 설계).

**Status.**

- **Not current behavior.** 위 one-shot 완결은 현재 동작이 아니다.
- **Not completed.** original Phase 4 one-shot objective 는 완료되지 않았다.
- **Future candidate / Phase 4b.** 폐기된 것이 아니라 future candidate 로 남긴다 — BACKLOG.md 의 Phase 4b row 가 entry point.
- **Requires separate scoped decision before implementation.** 구현 전 별도 scoped 결정 (별도 `/goal` + Codex review gate) 이 선행되어야 한다. activation 은 global / user instruction-file mutation 을 동반하므로 auto-apply 는 별도 explicit boundary 의 승인 모델 설계가 필요하다.

**Safe-condition outline (구현 시 충족되어야 할 안전 조건 윤곽; 설계 확정 아님).** auto-apply 가 안전하다고 판단되려면 적어도 다음이 모두 성립해야 한다:

- **payload update success** — payload 갱신이 성공적으로 끝났을 것.
- **activation surfaces resolved through shared resolver** — apply 대상 activation surface 가 shared resolver (verify 와 동일 resolver) 로 해소되어 destination drift 가 없을 것.
- **managed-block preflight passes** — managed-block apply 의 all-surface preflight 가 통과할 것.
- **no forbidden path** — 어떤 surface 도 금지 경로 (forbidden destination) 를 가리키지 않을 것.
- **no existing `.amb-backup`** — 기존 `.amb-backup` rollback-sidecar 가 남아 있지 않을 것 (남아 있으면 직전 apply 가 깔끔히 닫히지 않은 신호 → fail-fast).
- **skill mirror canonical-overwrite source exists** — skill mirror 의 canonical-overwrite source (in-payload SKILL.md) 가 존재할 것.
- **post-apply verify required** — apply 후 verify 가 반드시 수행되어 byte-identity / SHA-256 정합이 확인될 것.
- **fallback to activation_pending / manual apply if unsafe** — 위 조건 중 하나라도 불성립하면 auto-apply 하지 않고 현행 `activation_pending` / manual apply 경로로 안전하게 후퇴할 것.

위 윤곽은 안전 후퇴(fallback)를 기본으로 하는 보수적 형태의 스케치이며, 승인 모델 / preflight 범위 / verify 결합의 확정 설계는 Phase 4b 의 별도 scoped 작업에서 결정한다.

## Idea-only document discipline

- 본 IDEAS.md 는 source-managed (git-tracked) document 이며 `<ProjectRoot>/log/` 하위 runtime tree 아래의 working artifact 가 아니다.
- 본 문서의 추가 idea-only item 또는 기존 item 의 wording 갱신은 별도 source-doc governance batch 의 scope 영역이다.
- 본 문서의 idea-only item 의 promotion-to-implementation 은 (1) reopen / scoped 결정 + (2) BACKLOG.md row 또는 STATUS.md 의 explicit entry + (3) user 의 별도 scoped `/goal` + (4) Codex review gate 의 표준 cycle 의 4 단계 모두 충족 시에만 가능. 본 IDEAS.md 안에서 promotion 결정은 없다.
- 본 문서의 idea-only item 이 BACKLOG.md row 의 implementation entry 로 변환되거나 STATUS.md 의 완료 ledger 로 entry 되면, 본 IDEAS.md 의 해당 항목은 그 시점에서 superseded — historical 기록으로 archive 되거나 promotion batch 안에서 정리한다.
