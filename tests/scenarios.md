# kc 플러그인 E2E 시나리오

준비: `bash tests/make-sample-vault.sh tests/tmp/e2e` 실행 후,
`claude --plugin-dir "$PWD"`로 세션을 시작한다.
`KC_DIR`을 격리하려면 세션 시작 전 `export KC_DIR=$PWD/tests/tmp/kc-home`.

## 1. init
- [ ] `/kc:init tests/tmp/e2e/vault-remote.git` → clone 위치·이름을 물은 뒤 config 생성
- [ ] 이미 스켈레톤이 있는 vault라 부트스트랩을 건너뛴다
- [ ] 빈 remote로 한 번 더 (새 bare repo 생성 후) → 스켈레톤 부트스트랩·push 확인

## 2. 커밋 트리거 캡처
- [ ] 임시 git repo를 만들어 파일 수정 후 Claude에게 커밋을 시키면, 훅 신호에 따라
      프로젝트 등록 제안 → 승인 시 projects.tsv 추가 + vault에 _index.md 생성
- [ ] 이어서 사고의 흐름 초안 제안 → 승인 → vault에 노트가 커밋·push 됨
- [ ] 같은 repo에서 오타 수정 커밋 → 아무 제안도 하지 않음
- [ ] "나중에" 응답 → queue.tsv에 항목 추가만 됨

## 3. status / review / pull
- [ ] `/kc:status` → 대기열 항목·vault 상태를 표로 보여주고 아무것도 수정하지 않음
- [ ] `/kc:review` → 대기열 항목 초안 제안 → 승인 시 vault 반영 + queue.tsv에서 제거
- [ ] 다른 clone에서 노트를 추가·push한 뒤 `/kc:pull` → 새 컨텍스트 브리핑이 나옴

## 4. commit (수동 기록)
- [ ] `/kc:commit PPT 초안 작업` → 인터뷰 4문항 → 초안 검토 → 승인 시 반영
- [ ] 범용 지식성 답변을 주면 topics/ 배치를 제안하는지 확인

## 5. curate
- [ ] `/kc:curate` → inbox의 회의메모-0722.md를 구조화 노트로 변환 제안,
      영상-스트리밍 topic이 2개 프로젝트에 걸쳐 있으므로 "정리된 지식" 증류 제안
- [ ] 항목별 승인/제외 후 승인분만 커밋·push, 처리된 inbox 원본은 삭제됨

## 6. onboard / ask
- [ ] `/kc:onboard video-pipeline` → 배경·결정 타임라인·현재 상태·연관·읽기 순서 브리핑
- [ ] `/kc:onboard` (인자 없이) → 프로젝트 목록을 보여주고 고르게 함
- [ ] `/kc:ask 스트리밍 프로토콜 왜 LL-HLS로 했어?` → 근거 답변 + 출처 노트 경로 명시

## 7. 충돌 시나리오
- [ ] `git clone tests/tmp/e2e/vault-remote.git tests/tmp/e2e/vault2` 후
      양쪽 clone에서 `projects/video-pipeline/_index.md`의 같은 줄을 다르게 수정·커밋,
      한쪽만 push
- [ ] push 못 한 쪽 clone을 VAULT_PATH로 두고 `/kc:pull` → 충돌을 감지하고
      양쪽 내용을 보존하는 병합을 제안(애매하면 사용자에게 물음), 조용히 한쪽을 버리지 않음
- [ ] 해결 후 push까지 완료되고 `git ls-files -u` 출력이 비어 있음
