-- ==========================================
-- Senior Memory Archive (SMA) Database Setup
-- Google AI (Gemini) Version
-- ==========================================

-- Step 1: Enable pgvector extension (벡터 검색용)
CREATE EXTENSION IF NOT EXISTS vector;

-- Step 2: Create main table
CREATE TABLE IF NOT EXISTS senior_memory_bank (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,

  -- 출처 정보
  source_type VARCHAR(50) NOT NULL,  -- 'brunch_article', 'bigkinds_news', 'youtube_transcript'
  original_title TEXT,
  source_url TEXT,

  -- 본문 데이터
  content_body TEXT NOT NULL,        -- 원본 본문 (재작성 없음, 정확한 자료 보존)
  original_content TEXT,             -- 원본 텍스트 백업

  -- 백과사전식 상세 메타데이터 (JSONB로 유연하게 저장)
  metadata JSONB,                    -- 5W1H 기반 상세 정보 (30+ 필드)

  -- 메타데이터
  event_date DATE,                   -- 사건 날짜
  era_decade VARCHAR(10),            -- '1970s', '1980s', 'unknown'
  location_info TEXT,                -- 장소 정보 (예: 서울 종로구)

  -- 감성/분류 태그
  sentiment_tags TEXT[],             -- ['nostalgic', 'hopeful']
  category VARCHAR(50),              -- 'family', 'society', 'culture'
  keywords TEXT[],                   -- ['키워드1', '키워드2']

  -- 벡터 임베딩 (Gemini Embeddings)
  embedding VECTOR(768),             -- Gemini embedding dimension: 768

  -- 시스템 정보
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Step 2-1: Add metadata column (if table already exists)
ALTER TABLE senior_memory_bank ADD COLUMN IF NOT EXISTS metadata JSONB;

-- Step 3: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_source_type ON senior_memory_bank(source_type);
CREATE INDEX IF NOT EXISTS idx_era_decade ON senior_memory_bank(era_decade);
CREATE INDEX IF NOT EXISTS idx_event_date ON senior_memory_bank(event_date);
CREATE INDEX IF NOT EXISTS idx_category ON senior_memory_bank(category);
CREATE INDEX IF NOT EXISTS idx_sentiment_tags ON senior_memory_bank USING GIN(sentiment_tags);
CREATE INDEX IF NOT EXISTS idx_keywords ON senior_memory_bank USING GIN(keywords);
CREATE INDEX IF NOT EXISTS idx_metadata ON senior_memory_bank USING GIN(metadata jsonb_path_ops);

-- Step 4: Create vector index (HNSW for better performance)
CREATE INDEX IF NOT EXISTS idx_embedding_hnsw ON senior_memory_bank
USING hnsw(embedding vector_cosine_ops);

-- Step 5: Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_senior_memory_bank_updated_at BEFORE UPDATE
ON senior_memory_bank FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Step 6: Verify table creation
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'senior_memory_bank'
ORDER BY ordinal_position;

-- ==========================================
-- 테스트용 샘플 데이터 (선택사항)
-- ==========================================
/*
INSERT INTO senior_memory_bank (
  source_type,
  original_title,
  source_url,
  content_body,
  original_content,
  event_date,
  era_decade,
  location_info,
  sentiment_tags,
  category,
  keywords,
  metadata
) VALUES (
  'test_data',
  '1980년 서울의 봄',
  'https://example.com/test',
  '그때 우리는 희망을 품고 있었습니다...',  -- 원본 본문 보존
  '그때 우리는 희망을 품고 있었습니다...',
  '1980-05-18',
  '1980s',
  '서울특별시 > 중구 > 광화문',
  ARRAY['nostalgic', 'hopeful'],
  'society',
  ARRAY['민주화', '서울', '봄', '1980년'],
  '{"article_date": "1980-05-18", "event_time": "10:00", "region": "서울특별시", "city": "서울", "district": "중구", "dong": "광화문", "people": [{"name": "학생대표", "age": 23, "occupation": "대학생"}], "event_type": "정치집회", "headline": "서울의 봄 집회", "cause": "민주화 요구", "result": "평화 시위"}'::jsonb
);
*/

-- ==========================================
-- 벡터 검색 쿼리 예시
-- ==========================================
/*
-- 유사도 검색 (embedding이 있을 때)
SELECT
  id,
  original_title,
  content_body,
  era_decade,
  location_info,
  1 - (embedding <=> '[query_embedding_vector]'::vector) AS similarity
FROM senior_memory_bank
WHERE embedding IS NOT NULL
ORDER BY embedding <=> '[query_embedding_vector]'::vector
LIMIT 10;
*/

-- ==========================================
-- 완료!
-- ==========================================
-- 다음 단계:
-- 1. Supabase Dashboard > SQL Editor에서 위 SQL 실행
-- 2. Table Editor에서 senior_memory_bank 테이블 확인
-- 3. Indexes 탭에서 인덱스 7개 확인
-- ==========================================
