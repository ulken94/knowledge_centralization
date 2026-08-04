---
description: "vault 큐레이션 — inbox 정리, 링크·인덱스 정비, topic 승격, 중복 정리"
---

vault의 사서 역할. 주 1회 정도 아무나 실행하면 된다. 사용자 대면 텍스트는 한국어.
환경변수 `KC_DIR`가 설정돼 있으면 아래의 `~/.claude/kc`를 그 경로로 대체한다 (훅과 동일 규칙).

1. `~/.claude/kc/config` 없으면 "/kc:init 먼저" 안내 후 중단. `VAULT_PATH` 읽기,
   `$VAULT_PATH/_meta/conventions.md` 읽기
2. 최신화: `reference/vault-git-flow.md`의 1·2단계(밀린 push 처리, pull --rebase) 먼저 수행
3. **변경을 바로 적용하지 말고, 전부 "제안 목록"으로 모은다**:

   a. **Inbox 처리**: `inbox/`의 각 파일(README.md 제외)을 읽고 conventions.md 스키마의
      구조화 노트로 변환 + 배치 제안(프로젝트 vs topics — 어느 프로젝트인지 내용으로 추정하고
      애매하면 표시). 변환되면 원본 메모는 삭제 대상
   b. **링크 정비**: 모든 컨텍스트 노트에서 frontmatter `topics:` ↔ `## 연관` 위키링크
      불일치 수정안, 존재하지 않는 노트를 가리키는 깨진 위키링크 수정안,
      각 `_index.md`의 "주요 결정"·topic 노트의 "관련 프로젝트·노트" 목록 갱신안
   c. **topic 승격**: 같은 topic이 2개 이상 프로젝트의 노트에 등장하면, 그 topic 노트의
      `## 정리된 지식`에 여러 프로젝트의 결론을 증류해 넣는 안 (원본 노트를 출처로 링크)
   d. **정리**: 내용이 크게 겹치는 노트 병합안, 30일 넘게 `status: draft`인 노트의
      승인(approved) 또는 삭제안

4. 제안 목록을 카테고리별로 요약해 보여주고 **항목별로 승인/제외를 받는다**
5. 승인된 변경만 적용 → 커밋 메시지 `kc: 큐레이션: <요약>`으로 커밋 & push
   (vault-git-flow.md 절차)
