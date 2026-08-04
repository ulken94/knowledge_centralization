# kc — 팀 지식 중앙화 플러그인

작업(코드·PPT·문서)의 **사고의 흐름**을 git 기반 Obsidian vault에 중앙화합니다.
코드는 Claude Code로 읽으면 되지만, "왜 이렇게 했는지"는 기록하지 않으면 사라집니다.
kc는 그 맥락을 캡처해서 새 팀원이 프로젝트에 **soft landing** 하게 돕습니다.

## 요구사항

- Claude Code, git, python3 (macOS/Linux 기본 포함)
- 팀 vault git repo 접근 권한 (self-hosted git)

## 설치 (팀원)

```
/plugin marketplace add <이 repo의 self-hosted git URL>
/plugin install kc@bogonet-tools
```

설치 후 최초 1회:

```
/kc:init <vault git URL>
```

끝. 이후로는 평소처럼 일하면 됩니다.

## 무엇이 자동으로 일어나나

- **커밋하면**: 의미 있는 작업 일단락이면 Claude가 사고의 흐름 기록을 제안합니다.
  승인하면 vault에 반영되고, "나중에"라고 하면 대기열에 쌓입니다. 사소한 커밋은 조용히 넘어갑니다
- **세션이 끝나면**: 커밋 없이 끝난 의미 있는 세션이 대기열에 등록됩니다 (`/kc:review`로 처리)
- **git은 신경 쓸 필요 없음**: pull/commit/push·충돌 처리를 플러그인이 알아서 합니다

## 명령

| 명령 | 역할 |
|---|---|
| `/kc:init` | 머신당 1회 — vault clone + 로컬 설정 |
| `/kc:commit` | 코드 밖 작업(PPT·문서)의 컨텍스트를 인터뷰식으로 기록 |
| `/kc:status` | 대기열·동기화 상태 확인 (읽기 전용) |
| `/kc:review` | 대기열에 쌓인 세션 검토 → vault 반영 |
| `/kc:pull` | 최신 vault 받아오기 + 새 컨텍스트 브리핑 |
| `/kc:curate` | 큐레이션 — inbox 정리, 링크 정비, topic 승격 (주 1회 권장) |
| `/kc:onboard <프로젝트>` | 온보딩 브리핑 — 배경·결정·현재 상태·읽기 순서 |
| `/kc:ask <질문>` | vault에 묻기 (답변에 출처 노트 링크 포함) |

## 비개발자 팀원

Obsidian으로 vault를 열고 `inbox/`에 자유 형식 메모를 남기면 됩니다.
형식 규칙 없음 — 주기적 큐레이션이 정리해서 정식 위치로 옮깁니다.
Claude 앱에서 작업한 내용은 대화를 복사해 개발자에게 전달하거나 inbox에 붙여넣으세요.

## vault 규칙

vault의 구조·노트 스키마·링크 규칙은 `vault/_meta/conventions.md`가 단일 기준(SSOT)입니다.
규칙을 바꾸려면 그 파일만 수정하세요 — 플러그인 업데이트는 필요 없습니다.

## 개발

- 훅 테스트: `bash tests/hooks/test-lib.sh && bash tests/hooks/test-commit-capture.sh && bash tests/hooks/test-session-capture.sh`
- E2E: `tests/scenarios.md` 체크리스트 (`tests/make-sample-vault.sh`로 샘플 vault 생성)
- 설계: `docs/superpowers/specs/2026-07-22-team-knowledge-plugin-design.md`
