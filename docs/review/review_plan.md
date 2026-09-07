# review Plan

## Header

범용 목적 카탈로그, 모델·effort 선정 기준, max/ultra 지원, 기존 Notes의 위임 관측을 하나의 구현 후보로 연결하는 계획이다. 방향은 `review_design.md`, 지속할 목표 의미는 `review_spec.md`에 있다.

이 계획은 구현 범위·호환 처분·검증을 설명하며 실행 결과나 완료 판정이 아니다. commit·push·main 반영·global 설치 변경을 승인하지 않는다.

## Batch 순서와 의존

목적별 카탈로그와 선택 설명을 기준으로 입력·적용 관측·응답 안내를 함께 맞추고, 그 통합 후보를 검증한다. 아래 순서는 구현 의존 순서이며 모델 지원·위임 관측을 독립 완료 항목으로 만들지 않는다.

1. 상황 카탈로그·schema·호출자 선택 안내를 동기화한다.
2. 동일 후보에 max/ultra 입력·적용 관측과 Notes 안내를 연결한다.
3. 기능 계약과 실제 선택·전달을 검증하고 내용이 갖춰진 전체 후보를 canonical review한다.

Spec의 선정 기준은 이 계획을 구현하기 전 목표 상태로 반영하며, 구현·검증과 의미가 맞아 closeout될 때까지 lifecycle marker를 `sync-required`로 둔다.

## Batch 정의

### 1. 목적 카탈로그와 호출자 선택

대상은 `config/reviewer.json`, `config/reviewer.schema.json`, `snippets/claude-skills/ai-harness-review/SKILL.md`다.

- 상황별 기본 모델·effort와 description을 config에 둔다. description에는 무엇을 검증하는지·언제 고르는지·중요한 제외 조건과 함께 해당 목적의 운영·전문 대안의 구체 모델·effort·적용 조건을 간결하게 담는다. 대안은 목적과 선택 근거가 있는 경우만 기록하며 기본값과 같은 조합을 반복하지 않는다. 형식은 순수 JSON이고 description은 자유문 문자열이며 별도 기계 문법·대안 필드·registry를 만들지 않는다.
- 국소 정확성·의미 보존·논리·완전성·근거·수치·실현 가능성·계약·권한 경계·교차 정합성·절차·코드 수명·코드 데이터 경계·검증 탐지력·복합 종합을 구별하고 default/highest를 별도 선택 의도로 둔다. 모델과 effort의 모든 조합마다 키를 만들지 않는다.
- 같은 이름을 유지하는 default·simple-local·complex-broad·system-coherence-heavy·contract-sensitive·boundary-sensitive는 새 선택 의미에 맞게 설명과 값을 조정한다. 기존 medium-scope·script-runtime·test-code·mechanical-audit·docs-planning·docs-wording도 입력 가능한 entry로 유지하고 새 호출이 목적별 항목으로 이동할 이유를 설명한다. alias나 자동 키 번역을 추가하지 않는다.
- schema는 entry의 description을 정보성 문자열로 기술하고 값·용도 설명의 독립 복제본을 만들지 않는다. description이 없는 기존 custom entry도 계속 수용하며 모든 항목을 같은 safe floor로 출하한다는 기존 설명을 목표 상태에 맞춘다.
- skill은 중요 영향과 명시 요청을 우선하고, 범용 최고 요청을 일반 default 또는 다른 모델 계열의 최고 effort로 대신하지 않도록 설명한다. 운영·전문 대안은 해당 entry의 description을 읽어 선택하며, 검증 목적의 category를 유지한 채 선택한 대안의 모델·effort를 기존 `-Model`·`-Effort`로 명시한다. 대안의 한 축이 category 기본값과 의도치 않게 섞이지 않도록 선택한 조합의 두 값을 전달한다.
- 사용자 명시 축은 대안으로 덮어쓰지 않는다. 사용자가 한 축만 지정한 경우 대안을 적용하더라도 그 축을 유지하고 나머지 축만 선택한 대안에서 채운다. 대안을 선택하지 않았다면 사용자가 지정한 축만 명시하고 나머지는 기존 category/scalar 해소에 둔다. description이나 적용 가능한 대안이 없는 custom entry도 기존 기본 선택을 유지한다.
- runner는 description을 읽어 조합을 고르거나 파싱하지 않고 기존 명시 인자와 category 해소만 수행한다. 선택 이유와 사용자 명시값의 반영은 caller가 설명한다. run-fact의 `explicit`은 실제 CLI 인자에서 해소됐다는 뜻이며 사용자 원문에서 직접 지정했다는 뜻으로 확대하지 않는다.

검증은 기존 category·custom entry·default와 soft miss·matched malformed·축별 explicit override 계약에 맞춘다. 기존 키의 제거로 fallback이 생기지 않는지, description 자체가 runner의 실행값 해소를 바꾸지 않는지 확인한다. 같은 category에 대안의 양축 override를 전달하는 경우, 사용자 한 축을 유지하며 대안을 적용하는 경우, 대안 없이 기존 부분 명시 해소를 사용하는 경우가 의도한 값으로 이어져야 한다. description 부재도 기존 custom entry를 실패시키지 않는다. 이는 입력 해소·전달의 기능 확인이며 description의 의미를 자동 판정하는 테스트는 아니다.

용도별 기본값뿐 아니라 속도·사용량·유휴·전문 대안의 조합과 조건도 해당 config entry에 반영됐는지 대조한다. 실제 적용은 같은 목적 category와 명시 인자로 이어져야 하고, 선택 이유는 배포 skill만으로 설명할 수 있어야 한다. 목적별 추천이 실제 실전 근거인지 적용 가설인지도 구별한다.

### 2. effort 전달과 위임 관측

대상은 `scripts/review-run.ps1`, schema의 effort enum, `templates/review-result.md` 및 직접 관련 tests다.

- 기존 입력을 보존하면서 max·ultra를 허용하고 같은 invocation에서 관측하는 applied effort 인식도 함께 확장한다. 요청한 값과 실제 관측값을 구별하고 관측하지 못한 상태를 숨기지 않는다.
- config와 명시 입력에서 결정한 조합을 기존 codex exec 호출에 전달한다. model/category 단일행 검증, matched malformed의 fail-fast, 축별 해소, reviewer-safe posture는 유지한다.
- runner preamble과 result template의 기존 Notes에 관측한 자식 역할·모델·effort·깊이를 아는 만큼 보고하도록 안내한다. 새 필수 heading·shape/parser gate·sidecar·collector·추가 세션 조회를 만들지 않는다. 자식이 없거나 값을 모르면 그 상태를 표현한다.
- ultra의 자율 위임을 제한하지 않는다. 단일 reviewer unit 내부의 자율 위임과 toolset이 여러 canonical reviewer를 자동 구성하는 기능을 구별한다.

검증은 허용값 전달과 banner 관측, 기존 실패·provenance 계약에 집중한다. Notes의 정보성 안내를 새로운 기계적 결과 완성 조건으로 테스트하지 않는다.

### 3. 통합 검증과 검토

변경된 기능의 관련 테스트와 요구되는 전체 suite, `.ps1` 변경 시 `scripts/verify-ps1.ps1`을 수행한다. 반복 실행의 범위는 새로운 변경·실패·미해결 질문에 비례하며, 문서만 작성한 상태를 구현 검증 완료로 보고하지 않는다.

목적 선택의 근거는 실제 프로젝트 전체와 연결 문맥을 가진 분석으로 대조한다. C# 소켓 서버 프레임워크의 기존 실전 결과를 우선 활용하고, 새 비교가 필요할 때는 선택을 바꿀 질문과 실제 대상·범위·조합을 구체화한다. 대상 없는 단문 분류 스모크를 리뷰 품질의 증거로 사용하거나 모든 조합 재시험을 기본 절차로 만들지 않는다. 입력 해소·전달의 기능 테스트는 모델의 실전 리뷰 품질 비교와 구별한다.

canonical review는 상황별 선택·모델/effort·관측이 함께 갖춰진 통합 후보를 대상으로 한다. review 도메인의 기존 적격 engine·coverage·artifact 계약을 따른다. verdict는 별도 사용자 결정이 필요한 후속 실행을 승인하지 않는다.

## Work Packet과 문서 반영

별도 Work Packet은 만들지 않는다. Spec에 선정 기준·목표 행동·소유 관계를 반영하고, Design에는 방향과 근거의 적용 범위를 남긴다. 회차별 조사·실행·검증 결과는 runtime 연구/보고 영역의 역할이며 이 계획이나 Spec에 원문·개인 식별자·실험별 수치를 복제하지 않는다.

active owner의 구현과 문서 의미를 최종 검토 전에 맞추고 실제로 stale해지는 orientation·queue만 조정한다. 카탈로그 구성·값 조정은 이 계획의 현재 범위이며 별도 future-work로 중복 관리하지 않는다. Design·Plan의 retirement는 구현과 검증이 갖춰진 뒤 기존 closeout 절차를 따른다.

## 의미 변경과 단계 되돌림

검증 목적·기본 선택 이유·중요 영향·호환 처분을 바꾸는 발견은 구현 세부로 숨기지 않고 Design/Spec과 함께 재검토한다. 특정 모델의 지원 실패나 관측 불가는 자동 fallback·재시도·제약 추가로 해결하지 않는다.

기존 근거만으로 특정 목적의 추천을 확정할 수 없으면 그 적용 가설을 그대로 설명한다. 새 근거 없이 “검증 완료”로 올리지 않고, 구현 범위 밖 문제를 해결하기 위해 새 규칙·registry·collector를 추가하지 않는다.
