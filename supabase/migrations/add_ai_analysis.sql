-- Migration to add AI analysis fields to the reports table
ALTER TABLE public.reports 
    ADD COLUMN IF NOT EXISTS damage_type TEXT,
    ADD COLUMN IF NOT EXISTS repair_priority TEXT,
    ADD COLUMN IF NOT EXISTS estimated_diameter_cm DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS estimated_depth_cm DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS confidence INTEGER,
    ADD COLUMN IF NOT EXISTS safety_warning TEXT,
    ADD COLUMN IF NOT EXISTS suggested_action TEXT,
    ADD COLUMN IF NOT EXISTS ai_generated BOOLEAN DEFAULT false NOT NULL,
    ADD COLUMN IF NOT EXISTS generated_at TIMESTAMP WITH TIME ZONE;
