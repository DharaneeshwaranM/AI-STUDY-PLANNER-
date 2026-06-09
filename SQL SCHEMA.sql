-- ==========================================
-- AI STUDY PLANNER FULL DATABASE SETUP
-- ==========================================

-- Enable UUID extension for secure, non-sequential IDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop tables if they exist (For clean resets during development)
DROP TABLE IF EXISTS ai_generation_logs CASCADE;
DROP TABLE IF EXISTS schedule_slots CASCADE;
DROP TABLE IF EXISTS topics CASCADE;
DROP TABLE IF EXISTS study_plans CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ------------------------------------------
-- 1. TABLES CREATION
-- ------------------------------------------

-- USERS TABLE
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- STUDY PLANS TABLE (Macro-level goals and user constraints)
CREATE TABLE study_plans (
    plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    difficulty_level VARCHAR(50) DEFAULT 'Intermediate', 
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    daily_hours_allocated NUMERIC(3, 1) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_dates CHECK (end_date >= start_date)
);

-- TOPICS TABLE (AI-generated syllabus/modules)
CREATE TABLE topics (
    topic_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES study_plans(plan_id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    estimated_hours_required INT NOT NULL,
    sequence_order INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- SCHEDULE SLOTS TABLE (Micro-level calendar breakdown)
CREATE TABLE schedule_slots (
    slot_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    topic_id UUID NOT NULL REFERENCES topics(topic_id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    hours_allocated NUMERIC(3, 1) NOT NULL,
    status VARCHAR(20) DEFAULT 'Pending', -- Pending, Completed, Skipped, Overdue
    completed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- AI ENGINE LOGS TABLE (Tracks prompt contexts and performance metrics)
CREATE TABLE ai_generation_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    plan_id UUID REFERENCES study_plans(plan_id) ON DELETE CASCADE,
    prompt_used TEXT NOT NULL,
    ai_raw_response TEXT,
    status VARCHAR(20) DEFAULT 'Success', -- Success, Failed
    error_message TEXT,
    tokens_used INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------
-- 2. PERFORMANCE INDEXES
-- ------------------------------------------

-- Fast lookup for a user's active study plans
CREATE INDEX idx_study_plans_user ON study_plans(user_id) WHERE is_active = TRUE;

-- Speeds up rendering chronological topic lists within a single plan
CREATE INDEX idx_topics_plan_sequence ON topics(plan_id, sequence_order);

-- Performance booster for dashboard calendar queries (fetching active/pending tasks)
CREATE INDEX idx_schedule_slots_date ON schedule_slots(scheduled_date, status);


-- ------------------------------------------
-- 3. MOCK DATA (For testing your queries)
-- ------------------------------------------

-- Insert a test user
INSERT INTO users (user_id, name, email, password_hash)
VALUES ('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'Alex Dev', 'alex@example.com', 'hashed_secure_password');

-- Insert a study plan
INSERT INTO study_plans (plan_id, user_id, title, difficulty_level, start_date, end_date, daily_hours_allocated)
VALUES ('b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'Mastering SQL & PostgreSQL Architecture', 'Advanced', '2026-06-10', '2026-06-25', 2.0);

-- Insert AI-generated topics
INSERT INTO topics (topic_id, plan_id, title, description, estimated_hours_required, sequence_order)
VALUES 
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'Indexes & Query Optimization', 'Deep dive into B-Trees, Hash indexes, and analyzing EXPLAIN plans.', 4, 1),
('d4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'Concurrency & MVCC', 'Understanding multi-version concurrency control, isolation levels, and row locking mechanics.', 4, 2);

-- Insert daily schedule slots mapped to the topics
INSERT INTO schedule_slots (topic_id, scheduled_date, hours_allocated, status)
VALUES 
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', '2026-06-10', 2.0, 'Pending'),
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', '2026-06-11', 2.0, 'Pending'),
('d4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a', '2026-06-12', 2.0, 'Pending');

-- Insert a simulated AI log record
INSERT INTO ai_generation_logs (user_id, plan_id, prompt_used, ai_raw_response, tokens_used)
VALUES ('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'Generate an advanced 15-day SQL roadmap with 2 hours daily limit...', '{"status": "success", "topics": [...]}', 850);