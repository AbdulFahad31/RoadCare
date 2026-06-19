-- Create profiles table to link user metadata and roles
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    display_name TEXT,
    is_admin BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profile Policies
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Trigger to automatically create a profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name, is_admin)
    VALUES (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'displayName', new.raw_user_meta_data->>'name', ''),
        false
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create reports table to store pothole information
CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL DEFAULT '',
    description TEXT,
    image_url TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    status TEXT DEFAULT 'reported' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    -- Columns to support existing model parameters
    upvotes INTEGER DEFAULT 0 NOT NULL,
    severity TEXT DEFAULT 'low' NOT NULL,
    upvoted_by TEXT[] DEFAULT '{}'::TEXT[] NOT NULL,
    address TEXT,
    user_name TEXT,
    user_phone TEXT
);

-- Enable Row Level Security on reports
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Report Policies
-- 1. Anyone authenticated can select reports to display them on the Map or Reports list
CREATE POLICY "Authenticated users can view reports" ON public.reports
    FOR SELECT TO authenticated USING (true);

-- 2. Authenticated users can insert their own reports
CREATE POLICY "Authenticated users can insert reports" ON public.reports
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- 3. Authenticated users can update reports (to upvote/increment, or update status/severity if admin)
CREATE POLICY "Authenticated users can update reports" ON public.reports
    FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

-- 4. Users can delete their own reports
CREATE POLICY "Authenticated users can delete their own reports" ON public.reports
    FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Enable Realtime replication for reports
ALTER PUBLICATION supabase_realtime ADD TABLE public.reports;

-- Create Storage policies for the 'road-images' bucket
-- Note: storage.objects is the table where Supabase stores file metadata
CREATE POLICY "Public read access for road-images" ON storage.objects
    FOR SELECT USING (bucket_id = 'road-images');

CREATE POLICY "Authenticated users can upload road-images" ON storage.objects
    FOR INSERT TO authenticated WITH CHECK (bucket_id = 'road-images');

CREATE POLICY "Users can delete their own road-images" ON storage.objects
    FOR DELETE TO authenticated USING (bucket_id = 'road-images' AND auth.uid()::text = owner);
