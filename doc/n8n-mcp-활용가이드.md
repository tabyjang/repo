# n8n MCP 활용 가이드

> 작성일: 2026-01-10
> 다른 작업자가 쉽게 n8n MCP와 Skills를 활용할 수 있도록 정리한 문서입니다.

---

## 1. 설정 파일 위치

### MCP 설정 파일
- **경로**: `C:\NewProject\2026-01\n8n-claude\.mcp.json`
- Claude Code가 이 폴더에서 실행되면 자동으로 n8n-mcp 서버에 연결됩니다.

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": ["n8n-mcp"],
      "env": {
        "MCP_MODE": "stdio",
        "LOG_LEVEL": "error",
        "DISABLE_CONSOLE_OUTPUT": "true",
        "N8N_API_URL": "http://localhost:5678",
        "N8N_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

### n8n-mcp 소스 코드
- **경로**: `C:\NewProject\2026-01\n8n-claude\n8n-mcp\`
- GitHub: https://github.com/leonardsellem/n8n-mcp

### n8n-skills 소스 코드
- **경로**: `C:\NewProject\2026-01\n8n-claude\n8n-skills\`
- Claude Code의 n8n 관련 스킬이 정의된 플러그인

---

## 2. 현재 연결 상태 (2026-01-10 확인)

| 항목 | 값 |
|------|-----|
| n8n 버전 | 1.121.3 |
| n8n-mcp 버전 | 2.31.6 (최신: 2.33.0) |
| API URL | http://localhost:5678 |
| 연결 상태 | 정상 |
| 사용 가능 도구 | 20개 |

---

## 3. n8n MCP 도구 목록 (20개)

### 검색/조회 도구

| 도구명 | 설명 | 사용 예시 |
|--------|------|----------|
| `search_nodes` | 노드 키워드 검색 | `search_nodes({query: "slack"})` |
| `get_node` | 노드 상세 정보 조회 | `get_node({nodeType: "nodes-base.slack", detail: "standard"})` |
| `get_template` | 템플릿 ID로 조회 | `get_template({templateId: 123})` |
| `search_templates` | 템플릿 검색 | `search_templates({query: "chatbot"})` |

### 검증 도구

| 도구명 | 설명 | 사용 예시 |
|--------|------|----------|
| `validate_node` | 단일 노드 설정 검증 | `validate_node({nodeType: "nodes-base.slack", config: {...}})` |
| `validate_workflow` | 전체 워크플로우 검증 | `validate_workflow({workflow: {...}})` |

### 워크플로우 관리 도구 (n8n 인스턴스 연동)

| 도구명 | 설명 |
|--------|------|
| `n8n_list_workflows` | 워크플로우 목록 조회 |
| `n8n_get_workflow` | 특정 워크플로우 상세 조회 |
| `n8n_create_workflow` | 새 워크플로우 생성 |
| `n8n_update_full_workflow` | 워크플로우 전체 업데이트 |
| `n8n_update_partial_workflow` | 워크플로우 부분 수정 (diff 방식) |
| `n8n_delete_workflow` | 워크플로우 삭제 |
| `n8n_validate_workflow` | ID로 워크플로우 검증 |
| `n8n_autofix_workflow` | 자동 오류 수정 |
| `n8n_test_workflow` | 워크플로우 테스트 실행 |
| `n8n_executions` | 실행 이력 조회/관리 |
| `n8n_health_check` | n8n 연결 상태 확인 |
| `n8n_workflow_versions` | 버전 관리/롤백 |
| `n8n_deploy_template` | 템플릿을 인스턴스에 배포 |
| `tools_documentation` | MCP 도구 문서 조회 |

---

## 4. n8n Skills 목록 (7개)

Claude Code에서 `/skill-name` 형태로 호출하거나, 자동으로 적용됩니다.

| Skill | 용도 | 언제 사용? |
|-------|------|-----------|
| `n8n-code-javascript` | JavaScript 코드 노드 작성 | Code 노드에서 JS 작성 시 |
| `n8n-code-python` | Python 코드 노드 작성 | Code 노드에서 Python 작성 시 |
| `n8n-expression-syntax` | n8n 표현식 문법 검증 | `{{ }}` 표현식 작성/오류 해결 시 |
| `n8n-mcp-tools-expert` | MCP 도구 활용 가이드 | 어떤 MCP 도구를 사용할지 모를 때 |
| `n8n-node-configuration` | 노드 설정 가이드 | 노드별 필수 설정 확인 시 |
| `n8n-validation-expert` | 검증 오류 해석/수정 | 검증 에러 메시지 이해/해결 시 |
| `n8n-workflow-patterns` | 워크플로우 아키텍처 패턴 | 워크플로우 구조 설계 시 |

### Skills 상세 문서 위치
```
n8n-skills/skills/
├── n8n-code-javascript/   # JS 코드 노드 관련
├── n8n-code-python/       # Python 코드 노드 관련
├── n8n-expression-syntax/ # 표현식 문법
├── n8n-mcp-tools-expert/  # MCP 도구 활용
├── n8n-node-configuration/# 노드 설정
├── n8n-validation-expert/ # 검증 전문가
└── n8n-workflow-patterns/ # 워크플로우 패턴
```

---

## 5. 기본 워크플로우 작업 흐름

### 새 워크플로우 생성

```
1. 노드 검색: search_nodes({query: "webhook"})
2. 노드 정보 확인: get_node({nodeType: "nodes-base.webhook", detail: "standard"})
3. 워크플로우 생성: n8n_create_workflow({name: "My Workflow", nodes: [...], connections: {}})
4. 검증: n8n_validate_workflow({id: "workflow-id"})
5. 테스트: n8n_test_workflow({workflowId: "workflow-id"})
```

### 기존 워크플로우 수정

```
1. 목록 조회: n8n_list_workflows()
2. 상세 조회: n8n_get_workflow({id: "workflow-id", mode: "full"})
3. 부분 수정: n8n_update_partial_workflow({id: "...", operations: [...]})
4. 검증: n8n_validate_workflow({id: "workflow-id"})
```

### 템플릿 활용

```
1. 템플릿 검색: search_templates({query: "slack notification"})
2. 템플릿 조회: get_template({templateId: 123, mode: "full"})
3. 템플릿 배포: n8n_deploy_template({templateId: 123, name: "My Slack Bot"})
```

---

## 6. 자주 사용하는 명령어 예시

### 워크플로우 목록 보기
```
n8n_list_workflows()
```

### 특정 노드 검색
```
search_nodes({query: "HTTP Request"})
search_nodes({query: "Slack", includeExamples: true})
```

### 노드 설정 방법 확인
```
get_node({nodeType: "nodes-base.httpRequest", detail: "standard"})
get_node({nodeType: "nodes-base.slack", mode: "docs"})  // 마크다운 문서
```

### 워크플로우 검증
```
n8n_validate_workflow({id: "workflow-id"})
```

### 자동 오류 수정
```
n8n_autofix_workflow({id: "workflow-id", applyFixes: true})
```

### 연결 상태 확인
```
n8n_health_check({mode: "diagnostic"})
```

---

## 7. 트러블슈팅

### MCP 연결 안됨
1. n8n이 실행 중인지 확인 (http://localhost:5678)
2. `.mcp.json`의 API_KEY가 유효한지 확인
3. `n8n_health_check({mode: "diagnostic"})` 실행

### 노드 검색 안됨
- `search_nodes`는 OR/AND/FUZZY 모드 지원
- 예: `search_nodes({query: "slack", mode: "FUZZY"})` - 오타 허용

### 검증 오류 이해 안됨
- `n8n-validation-expert` 스킬 참조
- 경로: `n8n-skills/skills/n8n-validation-expert/`

---

## 8. 관련 문서

| 문서 | 위치 |
|------|------|
| n8n-mcp README | `n8n-mcp/README.md` |
| n8n-mcp 설치 가이드 | `n8n-mcp/docs/INSTALLATION.md` |
| Claude Code 설정 | `n8n-mcp/docs/CLAUDE_CODE_SETUP.md` |
| n8n-skills README | `n8n-skills/README.md` |
| Skills 사용법 | `n8n-skills/docs/USAGE.md` |

---

## 9. 버전 업데이트

현재 n8n-mcp 2.31.6 → 2.33.0 업데이트 가능

```bash
npm install -g n8n-mcp@2.33.0
```

---

## 10. 연락처/이슈

- n8n-mcp GitHub Issues: https://github.com/leonardsellem/n8n-mcp/issues
- n8n 공식 문서: https://docs.n8n.io/
