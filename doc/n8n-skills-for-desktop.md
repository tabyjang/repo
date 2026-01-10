# n8n Skills for Claude Desktop

Claude Desktop Project의 Custom Instructions에 복사하여 사용하세요.

---

## 1. n8n MCP Tools Expert

n8n-mcp MCP 도구 사용 전문가 가이드.

### 핵심 도구
| Tool | 용도 | 성공률 |
|------|-----|-------|
| `search_nodes` | 노드 검색 | 99.9% |
| `get_node_essentials` | 노드 정보 | 91.7% |
| `validate_node_operation` | 설정 검증 | Varies |
| `n8n_create_workflow` | 워크플로우 생성 | 96.8% |
| `n8n_update_partial_workflow` | 워크플로우 수정 | 99.0% |

### nodeType 형식 (중요!)
- **검색/검증 도구**: `nodes-base.slack`, `nodes-base.httpRequest`
- **워크플로우 도구**: `n8n-nodes-base.slack`, `@n8n/n8n-nodes-langchain.agent`

### 검증 프로필
- `minimal`: 필수 필드만 (빠름)
- `runtime`: 값+타입 (권장)
- `ai-friendly`: false positive 감소
- `strict`: 최대 검증

### IF 노드 연결 (Smart Parameters)
```javascript
// TRUE 분기
{type: "addConnection", source: "IF", target: "True Handler", branch: "true"}
// FALSE 분기
{type: "addConnection", source: "IF", target: "False Handler", branch: "false"}
```

---

## 2. n8n Expression Syntax

n8n 표현식 작성 가이드.

### 기본 형식
```
{{expression}}
```

### 핵심 변수
```javascript
{{$json.fieldName}}              // 현재 노드 출력
{{$node["Node Name"].json.field}} // 다른 노드 참조
{{$now.toFormat('yyyy-MM-dd')}}  // 현재 시간
{{$env.API_KEY}}                 // 환경 변수
```

### CRITICAL: Webhook 데이터 구조
```javascript
// 틀림
{{$json.name}}

// 맞음 - 웹훅 데이터는 .body 아래에 있음!
{{$json.body.name}}
{{$json.body.email}}
```

### Code 노드에서는 표현식 사용 금지
```javascript
// 틀림 (Code 노드)
const email = '={{$json.email}}';

// 맞음 (Code 노드)
const email = $json.email;
const email = $input.first().json.email;
```

---

## 3. n8n Workflow Patterns

5가지 핵심 워크플로우 패턴.

### 1. Webhook Processing (가장 흔함)
```
Webhook → Validate → Transform → Respond/Notify
```

### 2. HTTP API Integration
```
Trigger → HTTP Request → Transform → Action → Error Handler
```

### 3. Database Operations
```
Schedule → Query → Transform → Write → Verify
```

### 4. AI Agent Workflow
```
Trigger → AI Agent (Model + Tools + Memory) → Output
```

### 5. Scheduled Tasks
```
Schedule → Fetch → Process → Deliver → Log
```

### 워크플로우 생성 체크리스트
- [ ] 패턴 식별 (webhook, API, database, AI, scheduled)
- [ ] 필요한 노드 나열 (search_nodes 사용)
- [ ] 데이터 흐름 이해 (input → transform → output)
- [ ] 에러 핸들링 계획
- [ ] 각 노드 설정 검증 (validate_node_operation)
- [ ] 전체 워크플로우 검증 (validate_workflow)
- [ ] 샘플 데이터로 테스트

---

## 4. n8n Validation Expert

검증 오류 해석 및 수정 가이드.

### 검증 루프 (정상적인 패턴)
```
1. 설정 → 2. validate → 3. 오류 읽기 → 4. 수정 → 5. 다시 validate
(보통 2-3회 반복)
```

### 오류 심각도
| 레벨 | 설명 | 조치 |
|-----|------|-----|
| Errors | 실행 차단 | 반드시 수정 |
| Warnings | 실행 가능하나 문제 있을 수 있음 | 수정 권장 |
| Suggestions | 개선 사항 | 선택 사항 |

### 자동 수정 시스템 (Auto-Sanitization)
워크플로우 업데이트 시 자동으로 수정:
- Binary operators (equals, contains): `singleValue` 제거
- Unary operators (isEmpty, isNotEmpty): `singleValue: true` 추가
- IF/Switch 메타데이터 추가

### 끊어진 연결 정리
```javascript
n8n_update_partial_workflow({
  id: "workflow-id",
  operations: [{type: "cleanStaleConnections"}]
})
```

---

## 5. n8n Node Configuration

노드별 설정 가이드.

### 설정 철학
- `get_node_essentials`로 시작 (91.7% 성공률)
- 필요할 때만 `get_node_info` 사용
- 작업(operation)에 따라 필수 필드가 다름!

### 예시: Slack 노드
```javascript
// operation='post' 일 때
{
  resource: "message",
  operation: "post",
  channel: "#general",  // 필수
  text: "Hello!"        // 필수
}

// operation='update' 일 때
{
  resource: "message",
  operation: "update",
  messageId: "123",     // 필수 (다름!)
  text: "Updated!"      // 필수
}
```

### 예시: HTTP Request 노드
```javascript
// POST 요청
{
  method: "POST",
  url: "https://api.example.com/create",
  sendBody: true,       // POST일 때 필수
  body: {               // sendBody=true일 때 필수
    contentType: "json",
    content: {...}
  }
}
```

---

## 6. n8n Code JavaScript

Code 노드 JavaScript 작성 가이드.

### 기본 템플릿
```javascript
const items = $input.all();

const processed = items.map(item => ({
  json: {
    ...item.json,
    processed: true
  }
}));

return processed;
```

### 필수 규칙
1. **반환 형식**: `[{json: {...}}]` 배열 필수
2. **웹훅 데이터**: `$json.body.name` (`.body` 아래)
3. **표현식 금지**: `{{}}` 대신 직접 JavaScript 사용

### 데이터 접근 패턴
```javascript
$input.all()   // 모든 아이템
$input.first() // 첫 번째 아이템
$input.item    // 현재 아이템 (Each Item 모드)
$node["Name"].json // 특정 노드 데이터
```

### 흔한 실수
```javascript
// 틀림: 반환 형식
return {json: {field: value}};

// 맞음
return [{json: {field: value}}];

// 틀림: 웹훅 데이터
const name = $json.name;

// 맞음
const name = $json.body.name;
```

### 내장 함수
```javascript
// HTTP 요청
const response = await $helpers.httpRequest({
  method: 'GET',
  url: 'https://api.example.com/data'
});

// 날짜/시간 (Luxon)
const now = DateTime.now();
const formatted = now.toFormat('yyyy-MM-dd');

// JMESPath 쿼리
const adults = $jmespath(data, 'users[?age >= `18`]');
```

---

## 7. n8n Code Python

Code 노드 Python 작성 가이드.

### CRITICAL: JavaScript 95% 권장
Python은 다음 경우에만 사용:
- Python 표준 라이브러리 함수 필요
- Python 문법이 훨씬 익숙한 경우

### 외부 라이브러리 사용 불가!
```python
# 사용 불가
import requests  # X
import pandas    # X
import numpy     # X

# 사용 가능 (표준 라이브러리)
import json
import datetime
import re
import base64
import hashlib
import statistics
```

### 기본 템플릿
```python
items = _input.all()

processed = []
for item in items:
    processed.append({
        "json": {
            **item["json"],
            "processed": True
        }
    })

return processed
```

### 웹훅 데이터 접근
```python
# 틀림
name = _json["name"]

# 맞음
name = _json["body"]["name"]

# 안전한 접근
name = _json.get("body", {}).get("name", "Unknown")
```

---

## Quick Reference

### 워크플로우 생성 흐름
```
1. search_nodes → 노드 찾기
2. get_node_essentials → 설정 이해
3. validate_node_operation → 설정 검증
4. n8n_create_workflow → 생성
5. n8n_validate_workflow → 검증
6. n8n_update_partial_workflow → 수정
```

### 가장 많이 쓰는 노드
1. `n8n-nodes-base.code` - JavaScript/Python
2. `n8n-nodes-base.httpRequest` - HTTP 호출
3. `n8n-nodes-base.webhook` - 이벤트 트리거
4. `n8n-nodes-base.set` - 데이터 변환
5. `n8n-nodes-base.if` - 조건 분기
6. `@n8n/n8n-nodes-langchain.agent` - AI 에이전트

### 핵심 기억사항
- 웹훅 데이터는 `.body` 아래
- nodeType 형식 주의 (검색 vs 워크플로우)
- 검증은 반복 과정 (2-3회 정상)
- Code 노드에서 `{{}}` 표현식 사용 금지
- Python보다 JavaScript 권장 (95%)
