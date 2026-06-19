-- Performance Optimization Indexes for public.reports table
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports (status);
CREATE INDEX IF NOT EXISTS idx_reports_severity ON public.reports (severity);
CREATE INDEX IF NOT EXISTS idx_reports_upvotes ON public.reports (upvotes DESC);
CREATE INDEX IF NOT EXISTS idx_reports_location ON public.reports (latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_reports_user_id ON public.reports (user_id);
