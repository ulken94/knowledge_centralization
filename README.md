# kc — 팀 지식 중앙화 플러그인

작업의 **사고의 흐름**을 git 기반 Obsidian vault에 중앙화하는 Claude Code 플러그인입니다.

코드와 문서는 Claude Code로 읽으면 됩니다. 하지만 "왜 그렇게 했는지" — 어떤 대안을
검토했고 왜 버렸는지, 무엇이 아직 미해결인지 — 는 기록하지 않으면 사라집니다.
팀원이 각자 다른 프로젝트를 맡을수록 그 맥락이 개인에게 갇힙니다.

kc는 그 맥락을 **일하는 흐름을 끊지 않고** 캡처해서, 새 팀원이 프로젝트에
soft landing 하도록 돕습니다.

---

## 어떻게 동작하나

```
        작업 중                          검토·승인                    vault
  ┌──────────────────┐            ┌─────────────────┐        ┌──────────────┐
  │ git commit       │──신호──▶   │ Claude가 사고의  │──승인─▶│ markdown 노트 │
  │ 세션 종료        │──대기열─▶  │ 흐름을 요약·초안 │        │ + git push   │
  │ /kc:commit       │──인터뷰─▶  │                 │        └──────────────┘
  └──────────────────┘            └─────────────────┘
```

- **훅은 신호만 보냅니다.** API를 부르지도, vault에 쓰지도, 세션을 막지도 않습니다(항상 exit 0)
- **기록은 항상 사용자 승인을 거칩니다.** 초안 전문을 보여주고, 거절하면 아무것도 쓰지 않습니다
- **세션을 통째로 덤프하지 않습니다.** 정제된 요약만 남깁니다 — vault가 무거워지면 아무도 안 읽습니다
- **git은 신경 쓸 필요 없습니다.** pull·commit·push·충돌 처리를 플러그인이 합니다

### 구성

| 구성요소 | 성격 | 역할 |
|---|---|---|
| `hooks/*.sh` | 셸 스크립트 | 커밋 감지, 세션 종료 대기열. 신호만 보냄 |
| `commands/*.md` | 지시문 | 슬래시 명령의 절차. Claude가 읽고 수행 |
| `reference/*.md` | 지시문 | 여러 명령이 공유하는 절차(vault git flow, 캡처 플로우) |
| `templates/*.md` | vault 씨앗 | 새 vault를 부트스트랩할 규칙·노트 템플릿 |

**대부분이 마크다운 지시문입니다.** 동작을 바꾸려면 코드가 아니라 이 문서들을 고칩니다.

---

## 설치

**요구사항** — Claude Code, git, python3 (macOS/Linux 기본 포함), 팀 vault git repo 접근 권한

```
/plugin marketplace add ulken94/knowledge_centralization
/plugin install kc@ulken94-tools
```

설치 후 머신당 **최초 1회**:

```
/kc:init <vault git URL>
```

vault를 clone하고 `~/.claude/kc/config`를 만듭니다. 빈 vault면 스켈레톤도 부트스트랩합니다.
끝입니다. 이후로는 평소처럼 일하면 됩니다.

---

## 명령

| 명령 | 역할 |
|---|---|
| `/kc:init` | 머신당 1회 — vault clone + 로컬 설정 |
| `/kc:commit` | 코드 밖 작업(PPT·문서·회의)의 컨텍스트를 인터뷰식으로 기록 |
| `/kc:status` | 대기열·동기화 상태 확인 (읽기 전용, 네트워크 접근 없음) |
| `/kc:review` | 대기열에 쌓인 세션 검토 → vault 반영 |
| `/kc:pull` | 최신 vault 받아오기 + 새 컨텍스트 브리핑 + 꼬인 상태 복구 |
| `/kc:curate` | 큐레이션 — inbox 정리, 링크·폴더 구조 정비, topic 승격 (주 1회 권장) |
| `/kc:onboard <프로젝트>` | 온보딩 브리핑 — 배경·결정 타임라인·현재 상태·읽기 순서 |
| `/kc:ask <질문>` | vault에 묻기 (답변에 출처 노트 링크 포함) |

### 자동으로 일어나는 것

- **커밋하면** — 의미 있는 일단락이면 기록을 제안합니다. 미등록 repo면 프로젝트 등록부터
  제안합니다. 오타·포맷 같은 사소한 커밋은 조용히 넘어갑니다
- **세션이 끝나면** — 커밋 없이 끝난 세션이 대기열에 등록됩니다 (`/kc:review`로 처리).
  등록된 프로젝트만 대상입니다

---

## vault 구조

```
team-vault/
├── projects/
│   ├── kc-plugin/                        단독 프로젝트
│   │   ├── kc-plugin.md                  type: project-index
│   │   └── context/
│   │       ├── 플러그인-설계-결정.md
│   │       └── dogfood-실사용-검증.md
│   └── seah-2nd-forge/                   같은 시스템의 프로젝트 묶음
│       ├── seah-2nd-forge.md             type: group-index
│       ├── error-case/
│       │   ├── error-case.md
│       │   └── context/…
│       └── postech-refactor/
│           ├── postech-refactor.md
│           └── context/…
├── topics/                               프로젝트를 가로지르는 주제 허브
│   └── 소재-추적.md
├── inbox/                                자유 형식 투입 (비개발자·임시 메모)
└── _meta/                                규칙(SSOT)과 노트 템플릿
    ├── conventions.md
    └── templates/
```

**프로젝트는 frontmatter `type: project-index`인 노트가 있는 디렉토리입니다.**
깊이에 의존하지 않으므로 그룹으로 묶여도 그대로 인식됩니다.
인덱스 파일명은 디렉토리명과 같게 짓습니다 — Obsidian 그래프가 파일명을 라벨로 쓰기 때문입니다.

### 왜 묶음을 세 곳에 나타내나

같은 vault를 보는 화면마다 인식하는 수단이 다릅니다.

| 화면 | 묶는 수단 |
|---|---|
| GitHub·GitLab 웹 | **디렉토리** — 거기엔 그래프도 질의도 없고 폴더가 곧 탐색 |
| Obsidian 검색·필터 | **frontmatter `system:` 키** |
| Obsidian 그래프 | **그룹 노트의 위키링크** — 폴더도 frontmatter도 그래프에 안 나타남 |

하나만 쓰면 어느 한 화면에서는 반드시 묶이지 않습니다.

### 노트 스키마

```yaml
---
project: seah-2nd-forge/error-case   # projects/ 기준 상대경로
system: seah-2nd-forge               # 그룹 (없으면 생략)
created: 2026-07-31
updated: 2026-07-31
author: Haneol Kim
type: decision                       # decision | exploration | work-log | meeting
topics: [소재-추적, 센서-데이터-신뢰성]
status: approved                     # draft | approved
---
```

본문은 `# 제목` / `## 배경` / `## 사고의 흐름` / `## 결론` / `## 다음 단계 · 미해결` / `## 연관`.

- **파일명에 날짜를 넣지 않습니다** — 사람은 제목으로 찾습니다. 시간 정보는 frontmatter가 갖습니다
- **근거가 된 대화가 언제였는지는 `## 배경` 첫머리에 적습니다** — `created`는 노트를 쓴 날일 뿐,
  한 달짜리 논의를 요약한 노트가 하루로만 남으면 "언제 논의됐나"에 답할 수 없습니다
- **`topics:`와 `## 연관`의 위키링크는 항상 쌍으로** — 그래프는 위키링크로만 그려집니다

---

## vault 규칙은 vault가 갖습니다

구조·스키마·링크 규칙의 단일 기준(SSOT)은 **vault 안의** `_meta/conventions.md`입니다.
규칙을 바꾸려면 그 파일만 고치면 되고 **플러그인 업데이트는 필요 없습니다.**

플러그인이 업데이트되면서 새 규칙이 생기면 `/kc:pull`이 차이를 보여주고 항목별 승인을 받아
vault 사본에 더합니다. 팀이 직접 고친 규칙은 덮어쓰지 않습니다.

---

## 비개발자 팀원

Obsidian으로 vault를 열고 `inbox/`에 자유 형식 메모를 남기면 됩니다. 형식 규칙 없음 —
`/kc:curate`가 정리해서 정식 위치로 옮깁니다. Claude 앱에서 작업한 내용은 대화를 복사해
`inbox/`에 붙여넣거나 개발자에게 전달하세요.

### Obsidian 설정 권장

- **그래프 필터**에 `-path:_meta -path:inbox` — 규칙·템플릿 노드가 그래프를 어지럽히지 않게
- **새 노트 만들 위치**를 `topics/`로 — 미해결 링크를 클릭했을 때 빈 파일이 vault 루트에 떨어지지 않게

---

## 개발

```bash
# 전체 테스트 (62건)
for t in tests/hooks/*.sh tests/test-curate-*.sh; do bash "$t"; done
```

| 테스트 | 대상 |
|---|---|
| `tests/hooks/test-lib.sh` | 공통 라이브러리 — 설정 읽기, 경로 정규화, 프로젝트 매핑 |
| `tests/hooks/test-commit-capture.sh` | 커밋 감지 — 대상 repo 판정, vault 커밋 억제, 오탐 방지 |
| `tests/hooks/test-session-capture.sh` | 세션 종료 대기열 |
| `tests/test-curate-move.sh` | 폴더 구조 정리 — 이동·링크 수정·구조 디렉토리 보호 |
| `tests/test-curate-group.sh` | 그룹 묶음 — 감지·이동·키 부여·단독 프로젝트 제외 |

- E2E 체크리스트: `tests/scenarios.md` (`tests/make-sample-vault.sh`로 샘플 vault 생성)
- 설계 문서: `docs/superpowers/specs/2026-07-22-team-knowledge-plugin-design.md`
- 테스트 픽스처는 `tests/tmp/` 아래에 매번 새로 만들고 `.gitignore` 대상입니다

### 격리 실행

환경변수 `KC_DIR`를 설정하면 `~/.claude/kc` 대신 그 경로를 씁니다. 실제 설정을 건드리지 않고
E2E를 돌릴 때 사용합니다 — 훅과 모든 명령이 같은 규칙을 따릅니다.

```bash
KC_DIR=/tmp/kc-test bash tests/hooks/test-commit-capture.sh
```
