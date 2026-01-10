# [Tasks] Senior Memory Archive (SMA) Implementation Checklist

**Project:** SMA Data Pipeline v2.0
**Owner:** Park Soon-hwa
**Last Updated:** 2026-01-06

---

> **⚠️ [중요: 진행 원칙 - STOP & CONFIRM]**
>
> 각 항목의 체크박스(`[x]`)를 체크하기 전, **반드시 현재 단계의 완료 결과(스크린샷, 로그, 데이터 등)를 파트너(AI)에게 공유하고 확인(허락)을 받은 후**에만 다음 단계로 넘어가십시오.
> *검증 없이 진행 시 데이터 구조가 꼬일 수 있습니다.*

---

## Phase 1. 인프라 및 데이터베이스 환경 구축 (Foundation)
> **목표:** 데이터가 저장될 Supabase DB와 테이블을 완벽하게 세팅합니다.

- [ ] **1-1. Supabase 프로젝트 설정**
    - [ ] Supabase 대시보드 접속 및 프로젝트 확인 (기존 또는 신규).
    - [ ] Database Settings > Extensions 메뉴에서 `pgvector` 활성화 확인.
- [ ] **1-2. 메인 테이블(`senior_memory_bank`) 생성**
    - [ ] PRD에 명시된 SQL 스키마를 SQL Editor에 입력.
    - [ ] 테이블 생성 실행 (Run).
    - [ ] 컬럼 확인: `id`, `source_type`, `original_title`, `content_body`, `event_date`, `era_decade`, `location_info`, `sentiment_tags`, `keywords`, `embedding`, `created_at`.
- [ ] **1-3. 인덱싱(Indexing) 적용**
    - [ ] 검색 속도 최적화를 위한 Index 생성 쿼리 실행.
    - [ ] Index 생성 완료 확인.
- [ ] **1-4. OpenAI API 키 점검**
    - [ ] OpenAI Platform 접속 -> API Key 확인/발급 (`sk-...`).
    - [ ] Billing(결제) 상태 Active 확인.

---

## Phase 2. n8n 기본 설정 및 연결 (Connectivity)
> **목표:** n8n이 DB와 AI를 제어할 수 있도록 권한을 연결합니다.

- [ ] **2-1. n8n Credentials 등록**
    - [ ] **Supabase:** Project URL 및 Service Role Key (Admin 권한) 등록 및 Connection Test.
    - [ ] **OpenAI:** API Key 등록 및 Connection Test.
- [ ] **2-2. 워크플로우 초기 세팅**
    - [ ] 새 워크플로우 생성 (`[SMA] Master Pipeline v1`).
    - [ ] Error Trigger 노드 추가 (에러 발생 시 알림용).

---

## Phase 3. AI 에이전트(Editor) 프롬프트 설계 (Brain Setup)
> **목표:** 데이터를 정제하고 분류할 AI의 '지능'을 정의합니다.

- [ ] **3-1. 시스템 프롬프트(System Prompt) 작성**
    - [ ] 페르소나 정의 ("1970~80년대 생활사 전문 작가").
    - [ ] 톤앤매너 정의 ("라디오 사연풍", "구어체/문어체 조화").
- [ ] **3-2. 구조화 출력(Structured Output) 설정**
    - [ ] JSON 스키마 정의 (`date`, `sentiment`, `location`, `category`, `rewritten_content`).
    - [ ] n8n `OpenAI Chat Model` 노드에서 'JSON Mode' 설정 테스트.

---

## Phase 4. [파이프라인 A] 정형 데이터 처리 (BigKinds/Excel)
> **목표:** 엑셀 파일(팩트, 사건)을 자동으로 DB에 넣는 라인을 구축합니다.

- [ ] **4-1. Google Sheets / File Trigger 설정**
    - [ ] 구글 시트 연동 및 빅카인즈 샘플 파일 업로드.
    - [ ] `Read Binary File` 또는 `Google Sheets Read` 노드 배치 및 데이터 로드 확인.
- [ ] **4-2. 데이터 매핑 (Data Mapping)**
    - [ ] 엑셀 컬럼(`일자`, `제목`) -> DB 컬럼(`event_date`, `original_title`) 매핑 로직 구성.
- [ ] **4-3. AI 메타데이터 추출 테스트**
    - [ ] 기사 제목/요약을 AI 노드에 입력.
    - [ ] `sentiment`, `category` 태그가 JSON으로 잘 나오는지 로그 확인.
- [ ] **4-4. Supabase Insert 연결**
    - [ ] `embedding` 벡터 생성 노드 연결.
    - [ ] `senior_memory_bank` 테이블 Insert 노드 연결 및 실행 테스트.

---

## Phase 5. [파이프라인 B] 비정형 텍스트 처리 (Web/Brunch)
> **목표:** 웹상의 글(브런치, 뉴스)을 긁어와서 '세탁'하는 라인을 구축합니다.

- [ ] **5-1. HTTP Request (크롤링) 설정**
    - [ ] 타겟 URL (뉴스 라이브러리/브런치) 입력.
    - [ ] HTML 응답 수신 확인 (Status 200).
- [ ] **5-2. HTML Parsing (청소)**
    - [ ] `HTML Extract` 노드 배치.
    - [ ] CSS Selector로 본문 텍스트만 추출 성공 확인.
- [ ] **5-3. AI Rewriting (재작성) 검증**
    - [ ] 추출된 텍스트를 프롬프트에 입력.
    - [ ] "라디오 대본풍 에세이"로 변환된 결과물 텍스트 확인.
- [ ] **5-4. DB 적재 확인**
    - [ ] 변환 데이터 DB Insert 및 저장된 데이터 확인.

---

## Phase 6. [파이프라인 C] 영상 자막 처리 (Youtube)
> **목표:** 유튜브 자막을 '읽을 수 있는 글'로 바꾸는 심화 라인을 구축합니다.

- [ ] **6-1. Youtube Transcript 추출**
    - [ ] 영상 ID 입력 시 자막 텍스트 리턴 확인.
- [ ] **6-2. 텍스트 병합 (Code Node)**
    - [ ] 파편화된 자막 라인을 하나의 문단으로 합치는 Javascript 코드 작성.
- [ ] **6-3. 구어체 정제 테스트**
    - [ ] AI 노드를 통해 추임새 제거 및 문어체 변환 확인.

---

## Phase 7. 통합 테스트 및 검증 (QA)
> **목표:** 실제 데이터를 넣고 검색이 잘 되는지 최종 확인합니다.

- [ ] **7-1. 샘플 데이터 주입 (End-to-End)**
    - [ ] 파이프라인 A, B, C 각각 실제 데이터 1건씩 실행.
    - [ ] 에러 로그(Execution Log) 확인.
- [ ] **7-2. Supabase 적재 데이터 육안 검증**
    - [ ] `processed_content` 퀄리티 확인.
    - [ ] `event_date`, `location` 태그 정확도 확인.
- [ ] **7-3. RAG 검색 시뮬레이션**
    - [ ] SQL Editor에서 벡터 검색 쿼리 실행.
    - [ ] 질문("1980년 부산 슬픈 이야기")에 맞는 데이터가 조회되는지 확인.