# 시니어 RAG 시스템 구축 - 실행 체크리스트

**프로젝트**: SMA (Senior Memory Archive) Data Pipeline
**목표**: 1970-80년대 생활사 데이터 수집 → RAG 기반 고품질 시니어 대본 제작
**작성일**: 2026-01-06
**진행 원칙**: 각 단계 완료 후 반드시 결과 확인 → 승인 → 다음 단계

---

## ✅ Phase 1: 인프라 및 데이터베이스 환경 구축

### 1-1. Supabase 프로젝트 설정
- [x] Supabase 대시보드 접속 (https://supabase.com)
- [x] 프로젝트 확인 (기존) 또는 신규 프로젝트 생성
- [x] Database Settings → Extensions 메뉴 이동
- [x] `pgvector` extension 활성화 확인
- [x] **검증**: Extensions 목록에서 pgvector 상태 'enabled' 확인

### 1-2. 메인 테이블 생성 (senior_memory_bank)
- [x] Supabase SQL Editor 열기
- [x] 아래 스키마 SQL 실행 (supabase_setup.sql 사용):

```sql
CREATE TABLE IF NOT EXISTS senior_memory_bank (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  source_type VARCHAR(50) NOT NULL,
  source_url TEXT,
  original_title TEXT,
  content_body TEXT NOT NULL,
  original_content TEXT,
  event_date DATE,
  era_decade VARCHAR(10),
  location_info TEXT,
  sentiment_tags TEXT[],
  category VARCHAR(50),
  keywords TEXT[],
  embedding VECTOR(768),  -- Google Gemini embedding dimension
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

- [x] **검증**: Table Editor에서 `senior_memory_bank` 테이블 확인
- [x] 컬럼 15개 모두 존재 확인 (UNRESTRICTED 상태)

### 1-3. 인덱싱 적용
- [x] 검색 최적화용 인덱스 생성 (supabase_setup.sql에 포함):

```sql
CREATE INDEX idx_source_type ON senior_memory_bank(source_type);
CREATE INDEX idx_era_decade ON senior_memory_bank(era_decade);
CREATE INDEX idx_event_date ON senior_memory_bank(event_date);
CREATE INDEX idx_category ON senior_memory_bank(category);
CREATE INDEX idx_sentiment_tags ON senior_memory_bank USING GIN(sentiment_tags);
CREATE INDEX idx_keywords ON senior_memory_bank USING GIN(keywords);
CREATE INDEX idx_embedding_hnsw ON senior_memory_bank USING hnsw(embedding vector_cosine_ops);
```

- [x] **검증**: Indexes 탭에서 7개 인덱스 확인 (HNSW 방식 벡터 인덱스 포함)

### 1-4. Google Gemini API 키 점검
- [x] Google AI Studio 접속 (https://aistudio.google.com)
- [x] API Keys 메뉴에서 키 확인 또는 신규 생성
- [x] API 키 복사
- [x] **검증**: API 키 저장 완료 (사용자가 이미 연결 완료)

---

## ✅ Phase 2: n8n 기본 설정 및 연결

### 2-1. Supabase Credentials 등록
- [x] n8n UI → Settings → Credentials 이동
- [x] "Create New Credential" 클릭
- [x] "Supabase" 검색 및 선택
- [x] 입력 정보:
  - Host: `https://[your-project].supabase.co`
  - Service Role Key: `[your-service-role-key]`
- [x] "Test Connection" 클릭
- [x] **검증**: "Connection successful" 메시지 확인 (사용자가 이미 연결 완료)

### 2-2. Google Gemini Credentials 등록
- [x] Credentials → "Create New Credential"
- [x] "Google PaLM / Gemini" 검색 및 선택
- [x] API Key 입력
- [x] "Test Connection" 클릭
- [x] **검증**: "Connection successful" 메시지 확인 (사용자가 이미 연결 완료)

### 2-3. 워크플로우 초기 세팅
- [x] n8n → Workflows → "Create New Workflow"
- [x] 워크플로우 이름: `[SMA v2] 브런치 크롤링 파이프라인`
- [x] 저장 버튼 클릭
- [x] **검증**: 워크플로우 목록에 나타남
- [x] **워크플로우 ID**: Ae9aL2SJ0y8k0nj3
- [x] **URL**: http://localhost:5678/workflow/Ae9aL2SJ0y8k0nj3

---

## ✅ Phase 3: AI 메타데이터 추출 스키마 설계

### 3-1. 백과사전식 정보수집 프롬프트 작성
- [x] 1970-80년대 한국 뉴스/자료 아카이브 전문가 역할 정의
- [x] 5W1H 기반 구조화된 정보 추출 방식 설계
- [x] 다음 9개 필수 카테고리 포함:
  1. **시간 정보** (WHEN): article_date, event_date, event_time, time_period, season
  2. **장소 정보** (WHERE): region → city → district → dong → specific_location → address
  3. **인물 정보** (WHO): 배열 형태 [name, age, gender, occupation, organization, role, quote]
  4. **사건 정보** (WHAT): event_type, event_category, headline, event_summary
  5. **맥락** (WHY/HOW): cause, result, social_context, historical_significance
  6. **숫자 데이터**: 정확한 수치 [category, item, value, unit, comparison]
  7. **배경 묘사**: weather, atmosphere, visual_description, sounds, smells, crowd_size
  8. **출처/신뢰도**: source, reporter, credibility
  9. **검색 메타데이터**: keywords (15-20개), tags, sentiment
- [x] **검증**: 워크플로우 ID Ae9aL2SJ0y8k0nj3에 적용 완료

### 3-2. JSON 출력 스키마 정의 (백과사전식)
- [x] 뉴스/신문 자료용 상세 스키마 준비 완료:

```json
{
  "article_date": "1980-05-18",
  "event_date": "1980-05-18",
  "event_time": "10:00",
  "time_period": "오전",
  "season": "봄",
  "region": "서울특별시",
  "city": "서울",
  "district": "중구",
  "dong": "명동",
  "specific_location": "명동성당 앞",
  "address": "서울특별시 중구 명동길 74",
  "people": [{
    "name": "김영삼",
    "age": 52,
    "gender": "남성",
    "occupation": "국회의원",
    "organization": "신민당",
    "role_in_event": "집회 연설자",
    "quote": "민주주의는 피를 먹고 자란다"
  }],
  "event_type": "정치집회",
  "event_category": "민주화운동",
  "headline": "명동 민주화 집회 1만명 운집",
  "event_summary": "...",
  "cause": "계엄령 반대",
  "result": "경찰 저지, 평화 해산",
  "social_context": "1980년 서울의 봄",
  "historical_significance": "민주화운동의 중요 전환점",
  "numbers": [{
    "category": "count",
    "item": "참가인원",
    "value": 10000,
    "unit": "명",
    "comparison": "전주 대비 3배 증가"
  }],
  "weather": "맑음, 기온 18도",
  "atmosphere": "긴장감 속 평화로운 분위기",
  "visual_description": "흰색 셔츠 입은 대학생들이 플래카드 들고",
  "sounds": "구호 소리, 찬송가",
  "crowd_size": "약 1만명",
  "source": "동아일보",
  "reporter": "김기자",
  "credibility": "high",
  "keywords": ["1980년", "5월", "명동", "김영삼", "신민당", "집회", "민주화", "계엄령", "서울의봄"],
  "tags": ["정치", "민주화", "집회", "1980년대"],
  "sentiment": "hopeful",
  "era_decade": "1980s",
  "category": "society"
}
```

- [x] 스키마 Structured Output Parser에 적용 완료
- [x] **검증**: 워크플로우에 반영됨

---

## ✅ Phase 4: 파이프라인 A - 정형 데이터 (BigKinds/Excel)

### 4-1. 샘플 데이터 준비
- [ ] BigKinds에서 샘플 기사 5건 다운로드 (1970-80년대)
- [ ] Excel 파일 저장: `sample_bigkinds_5.xlsx`
- [ ] 컬럼 확인: `일자`, `제목`, `본문`, `출처`
- [ ] **검증**: 파일 확인, 5건 데이터 존재

### 4-2. Google Sheets 연동 (옵션)
- [ ] Google Drive에 Excel 파일 업로드
- [ ] Google Sheets로 변환
- [ ] 공유 설정 → "링크가 있는 모든 사용자" 읽기 권한
- [ ] **검증**: 브라우저에서 시트 열림 확인

### 4-3. n8n에서 Google Sheets Read 노드 설정
- [ ] 워크플로우에 "Google Sheets" 노드 추가
- [ ] Operation: "Read Rows"
- [ ] Sheet URL 입력
- [ ] Range: "A1:Z1000"
- [ ] **검증**: "Execute Node" 클릭 → 데이터 5건 조회 확인

### 4-4. 데이터 매핑 및 AI 처리
- [ ] "Set" 노드 추가
- [ ] 매핑:
  - `event_date` ← Excel의 `일자`
  - `original_title` ← Excel의 `제목`
  - `source_type` ← "bigkinds_news"
- [ ] "OpenAI Chat Model" 노드 추가
- [ ] Prompt에 시스템 프롬프트 + 제목/본문 입력
- [ ] JSON Mode 활성화
- [ ] **검증**: 1건 테스트 실행 → JSON 출력 확인

---

## ✅ Phase 5: 파이프라인 B - 웹 크롤링 (다양한 소스)

### 5-1. 크롤링 대상 URL 리스트 작성 (다양한 소스)
- [ ] **뉴스 아카이브**: 경향신문, 동아일보, 한겨레 등 1970-80년대 기사 URL
- [ ] **브런치**: 1970-80년대 회고 에세이 URL
- [ ] **디지털 아카이브**: 국사편찬위원회, 국립중앙도서관 디지털컬렉션
- [ ] **블로그**: 네이버, 티스토리 등 개인 회고록
- [ ] **공공데이터**: 서울역사박물관, 대한민국역사박물관 아카이브
- [ ] 최소 20개 URL 수집 (소스당 3-5개)
- [ ] `crawl_urls.txt` 파일에 저장 (형식: URL, 소스타입)
- [ ] **검증**: 파일 확인, URL 20개 이상, 다양한 소스 포함

### 5-2. HTTP Request 노드 설정 (범용)
- [x] 워크플로우에 "HTTP Request" 노드 추가
- [x] Method: GET
- [x] URL: 동적으로 변경 가능하도록 설정
- [x] Timeout: 10000ms
- [x] Headers: User-Agent 추가 (일부 사이트 차단 방지)
- [x] **검증**: 다양한 소스에서 HTML 응답 수신 확인

### 5-3. HTML Extract 노드 설정 (범용 CSS 셀렉터)
- [x] "HTML" 노드 추가
- [x] Operation: "Extract HTML Content"
- [x] Extraction Values (범용):
  - `title`: `h1, .article-title, .news-title, .post-title`
  - `content`: `article, .wrap_body, .article-body, .news-content, .post-content, main`
- [x] **검증**: 다양한 사이트에서 본문 추출 테스트

### 5-4. AI 메타데이터 추출 설정 (백과사전식)
- [x] "Basic LLM Chain" 노드 추가 (LangChain)
- [x] "Google Gemini Chat Model" 노드 추가
- [x] Model: gemini-2.0-flash-exp
- [x] System Prompt: 1970-80년대 한국 뉴스 아카이브 전문가 역할
- [x] Extraction Instructions: 5W1H 기반 9개 카테고리 추출
  - 시간 정보 (article_date, event_date, event_time, season)
  - 장소 정보 계층 구조 (region → city → district → dong → specific_location)
  - 인물 정보 배열 (name, age, occupation, quote 등)
  - 사건 정보 (event_type, headline, summary)
  - 맥락 (cause, result, social_context, historical_significance)
  - 숫자 데이터 (정확한 수치, 단위, 비교)
  - 배경 묘사 (weather, atmosphere, sounds, visual details)
  - 출처/신뢰도 (source, reporter, credibility)
  - 검색 메타데이터 (15-20개 keywords, tags)
- [x] "Structured Output Parser" 노드 연결
- [x] JSON Schema 입력 (백과사전식 상세 스키마)
- [ ] **검증**: 상세 메타데이터 JSON 출력 확인 (credential 연결 후 테스트 필요)

### 5-5. Google Gemini Embeddings 생성
- [x] "HTTP Request" 노드로 Gemini Embeddings API 직접 호출
- [x] URL: text-embedding-004 모델 엔드포인트
- [x] Input: `{{ $json.original_content }}` (원본 본문으로 임베딩 생성)
- [x] "Code" 노드로 임베딩 벡터 추출 및 Supabase 형식 변환
- [ ] **검증**: 768차원 벡터 배열 출력 확인 (credential 연결 후 테스트 필요)

### 5-6. Supabase Insert 설정 (백과사전식 메타데이터)
- [x] "Supabase" 노드 추가
- [x] Operation: "Insert"
- [x] Table: `senior_memory_bank`
- [x] Columns 매핑 완료 (Code 노드에서 자동 처리):
  - `source_type`: 소스별 구분 ("news_archive", "brunch_article", "blog_post", "public_archive")
  - `source_url`: 웹페이지 URL
  - `original_title`: 원본 제목
  - `content_body`: **원본 본문** (재작성 없음, 정확한 자료 보존)
  - `original_content`: 원본 본문 (동일)
  - `event_date`: 백과사전식 추출된 사건 날짜
  - `era_decade`: "1970s" 또는 "1980s"
  - `location_info`: 계층 구조 장소 정보 (예: "서울특별시 > 중구 > 명동 > 명동성당 앞")
  - `sentiment_tags`: [sentiment 값] 배열
  - `category`: "society", "culture", "economy", "politics", "education" 등
  - `keywords`: 15-20개 키워드 배열 (인명, 지명, 사건명, 시대적 키워드)
  - `embedding`: 768차원 벡터 (JSON 문자열, 원본 본문 기반)
- [ ] **검증**: 1건 실행 → Supabase에서 백과사전식 메타데이터 확인 (credential 연결 후 테스트 필요)

---

## ✅ Phase 6: 파이프라인 C - 유튜브 자막 처리

### 6-1. 유튜브 샘플 영상 선정
- [ ] 1970-80년대 관련 유튜브 영상 3개 선정
- [ ] 영상 ID 추출 (예: `dQw4w9WgXcQ`)
- [ ] `youtube_ids.txt` 파일에 저장
- [ ] **검증**: 파일 확인, ID 3개 존재

### 6-2. YouTube Transcript 노드 설정
- [ ] n8n에 "HTTP Request" 노드 추가
- [ ] URL: YouTube Transcript API 또는 직접 파싱
- [ ] (또는) Code 노드로 `youtube-transcript` npm 패키지 사용
- [ ] **검증**: 자막 텍스트 추출 확인

### 6-3. 자막 병합 (Code Node)
- [ ] "Code" 노드 추가 (JavaScript)
- [ ] 코드 예시:
  ```javascript
  const items = $input.all();
  const transcript = items.map(item => item.json.text).join(' ');

  // 중복 공백 제거
  const cleaned = transcript.replace(/\s+/g, ' ').trim();

  return [{json: {mergedTranscript: cleaned}}];
  ```
- [ ] **검증**: 하나의 연속된 텍스트로 병합 확인

### 6-4. 자막 정제 및 백과사전식 메타데이터 추출
- [ ] "Google Gemini Chat Model" 노드 추가
- [ ] Step 1: 자막 정제
  ```
  아래 유튜브 자막을 읽을 수 있는 글로 정제하세요.
  - 추임새 제거 (아, 음, 그, 이제 등)
  - 반복 표현 정리
  - 문어체로 자연스럽게 변환
  - 원본 의미 보존 (내용 왜곡 금지)

  자막: {{ $json.mergedTranscript }}
  ```
- [ ] Step 2: 백과사전식 메타데이터 추출
  - 5W1H 기반 9개 카테고리 추출 (Phase 3 스키마 사용)
  - 영상에서 언급된 시간, 장소, 인물, 사건 정보 구조화
  - 영상 출처, 업로드 날짜, 채널 정보 포함
- [ ] **검증**: 정제된 텍스트 + 상세 메타데이터 JSON 출력 확인

---

## ✅ Phase 7: 통합 테스트 및 검증

### 7-1. End-to-End 테스트
- [ ] 파이프라인 A: BigKinds 데이터 1건 전체 실행
- [ ] 파이프라인 B: 웹 크롤링 1건 전체 실행
- [ ] 파이프라인 C: 유튜브 1건 전체 실행
- [ ] **검증**: 3건 모두 Supabase에 저장 확인

### 7-2. 데이터 품질 검증 (백과사전식)
- [ ] Supabase Table Editor에서 데이터 확인
- [ ] `content_body` 원본 보존 확인 (재작성 없이 정확한 원문)
- [ ] 메타데이터 완성도 체크:
  - [ ] 시간 정보: event_date, event_time 정확성
  - [ ] 장소 정보: location_info 계층 구조 완성도
  - [ ] 인물 정보: 이름, 직함, 인용문 포함 여부
  - [ ] 사건 맥락: cause, result, historical_significance 서술 품질
  - [ ] 숫자 데이터: 정확한 수치, 단위 포함 여부
  - [ ] 배경 묘사: weather, atmosphere, visual details 상세도
- [ ] `keywords` 15-20개 포함 여부 (인명, 지명, 사건명, 시대 키워드)
- [ ] `sentiment`, `era_decade`, `category` 분류 정확성
- [ ] **검증**: 백과사전식 품질 점검표 작성 (5W1H 모두 충족)

### 7-3. RAG 검색 시뮬레이션
- [ ] Supabase SQL Editor에서 벡터 검색 테스트:

```sql
SELECT
  original_title,
  content_body,
  era_decade,
  location_info,
  1 - (embedding <=> '[검색 쿼리 embedding]') AS similarity
FROM senior_memory_bank
ORDER BY embedding <=> '[검색 쿼리 embedding]'
LIMIT 5;
```

- [ ] 질문 예시: "1980년 부산의 슬픈 이야기"
- [ ] **검증**: 관련성 높은 결과 5개 조회

### 7-4. 에러 로그 점검
- [ ] n8n Executions 탭에서 모든 실행 기록 확인
- [ ] 에러 발생 건수 확인
- [ ] 주요 에러 패턴 분석 및 문서화
- [ ] **검증**: 에러율 10% 미만

---

## 📊 체크리스트 진행 현황

**현재 위치**: Phase 5 거의 완료 (백과사전식 정보수집 파이프라인 - Credential 연결 및 테스트 대기)

### 완료된 Phase:
1. **Phase 1 완료**: 인프라 구축 (Supabase + Google Gemini)
   - Supabase 프로젝트 설정 완료
   - senior_memory_bank 테이블 생성 완료 (15 컬럼, 7 인덱스)
   - Google Gemini API 키 연결 완료
2. **Phase 2 완료**: n8n Credentials 연결
   - Supabase credential 연결 완료
   - Google Gemini credential 연결 완료
   - 워크플로우 생성 완료 (ID: Ae9aL2SJ0y8k0nj3)
3. **Phase 3 완료**: 백과사전식 메타데이터 추출 스키마 설계
   - 5W1H 기반 9개 카테고리 정의 완료
   - 뉴스/신문 자료용 상세 JSON 스키마 작성 완료
   - 워크플로우에 프롬프트 및 스키마 적용 완료

### 현재 진행 중:
4. **Phase 5 (95% 완료)**: 웹 크롤링 파이프라인 (백과사전식 정보수집)
   - 완료: 전체 10개 노드 구성 완료
     1. 시작 (Manual Trigger)
     2. 웹페이지 가져오기 (HTTP Request) - 다양한 소스 지원
     3. 본문 추출 (HTML Extract) - 범용 CSS 셀렉터
     4. **백과사전식 메타데이터 추출** (LLM Chain) - 5W1H 기반
     5. Google Gemini Chat Model (gemini-2.0-flash-exp)
     6. Structured Output Parser (9개 카테고리 JSON 스키마)
     7. Gemini 결과 매핑 (Set node)
     8. Gemini Embeddings API 호출 (HTTP Request) - 원본 기반
     9. Supabase 데이터 준비 (Code node) - 원본 보존
     10. Supabase 저장 (Insert) - 백과사전식 메타데이터
   - 완료: 뉴스 아카이브 최적화 프롬프트 적용 (API 업데이트 성공)
   - 대기: Credential 연결 (3개 노드)
   - 대기: 다양한 소스 테스트 (뉴스, 브런치, 블로그, 공공아카이브)
   - 대기: 테스트 실행 및 백과사전식 메타데이터 품질 검증

### 우선순위:
1. **Phase 5 완료**: Credential 연결 및 테스트 (현재 작업)
2. **Phase 4**: BigKinds 데이터 처리
3. **Phase 6**: 유튜브 자막 처리
4. **Phase 7**: 통합 테스트

### 현재 워크플로우 상태:
- 이름: [SMA v2] 브런치 크롤링 파이프라인
- ID: Ae9aL2SJ0y8k0nj3
- URL: http://localhost:5678/workflow/Ae9aL2SJ0y8k0nj3
- 노드 개수: 10개 (API를 통해 업데이트 완료)
- 상태: 구조 완성, credential 연결 필요

### 다음 액션:
- [대기 중] 브라우저에서 워크플로우 확인 (F5로 새로고침)
- [대기 중] 3개 노드에 Credential 연결:
  1. Google Gemini Chat Model → Google PaLM/Gemini credential
  2. Gemini Embeddings API 호출 → Google PaLM API credential (이미 URL에 직접 키 포함됨)
  3. Supabase 저장 → Supabase credential
- [대기 중] "Test workflow" 버튼으로 전체 파이프라인 테스트 (현재 브런치 샘플 URL)
- [대기 중] 백과사전식 메타데이터 품질 확인:
  - 5W1H 9개 카테고리 모두 추출되었는가?
  - keywords 15-20개 포함되었는가?
  - 숫자 데이터 정확한 수치 포함되었는가?
  - 인물 정보에 이름, 직함, 인용문 포함되었는가?
- [대기 중] 다양한 소스 URL로 테스트:
  - 뉴스 아카이브 (경향신문, 동아일보)
  - 브런치 에세이
  - 블로그 회고록
  - 공공 아카이브 (국사편찬위원회)
- [대기 중] Supabase에서 저장된 데이터 확인 (원본 보존 + 백과사전식 메타데이터)

---

**작성자**: Claude Code
**최종 수정**: 2026-01-06
**버전**: 1.3 (백과사전식 정보수집으로 전면 개편 + 다양한 소스 지원)
