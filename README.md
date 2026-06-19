<div align="center">

<img src="https://img.shields.io/badge/🚧-RoadCare-2563EB?style=for-the-badge&labelColor=0a0a0a&color=00C9A7" height="40"/>

# RoadCare

### AI-Assisted Smart Road Damage Reporting System

<p>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=flat-square&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/PostgreSQL-Database-4169E1?style=flat-square&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/Google-Gemini%202.5%20Flash-4285F4?style=flat-square&logo=google&logoColor=white" />
  <img src="https://img.shields.io/badge/Mapbox-Maps-00C6AE?style=flat-square&logo=mapbox&logoColor=white" />
  <img src="https://img.shields.io/badge/Riverpod-State%20Management-6C63FF?style=flat-square" />
</p>

</div>

---

## 📖 Overview

**RoadCare** is a premium, community-driven road hazard and pothole reporting application built with **Flutter**, **Supabase**, and **Google Gemini 2.5 Flash**. The app allows users to quickly report potholes, capture GPS location and photos, upvote nearby active issues to prevent duplicate reports, and view reports live on Mapbox. 

With an integrated **Gemini 2.5 Flash Assistant**, the app analyzes uploaded road images to generate professional road inspection reports and populate reporting forms automatically. An offline synchronization queue guarantees that reports created without active internet are cached locally and synchronized silently in the background when connectivity returns.

---

## ⚡ Core Features

* **🤖 AI Road Inspection Assistant**: Capture or upload road images, analyze them using Google Gemini 2.5 Flash, and automatically estimate pothole dimensions (diameter & depth), severity, priority, suggested actions, and safety warnings.
* **📶 Offline Sync Queue**: Submitted reports are serialized locally via `SharedPreferences` when offline. The app listens to connectivity changes and automatically uploads queued reports in the background when internet is restored.
* **🗺️ Realtime Mapbox Maps**: Reports are rendered on Mapbox with status-coded colors and size-scaled markers (severity-based).
* **👍 Upvote & Confirm Issues**: Confirm active issues with upvotes to draw maintenance attention and prevent redundant reports.
* **🗑️ Creator Deletion**: Users can delete their own reported potholes directly from the details page.
* **📊 Admin Dashboard**: Authority users can search, filter, sort, update report status (Reported, In Progress, Fixed), and modify risk levels.

---

## 🛠️ Performance Optimizations & Resilience

1. **Database Indexing**: Composite and spatial indexes are created on sorted and filtered columns (`created_at`, `status`, `severity`, `user_id`, and `latitude`/`longitude`) to accelerate queries and coordinate scans.
2. **PostgREST Select Optimization**: Reduced network and serialization overhead by fetching only required columns (`id`, `latitude`, `longitude`, `status`) during nearby duplicate scans.
3. **Resilient Network Client**: Wrapped Supabase database reads/writes in an exponential backoff retry handler with randomized jitter (+/- 20%) to gracefully survive temporary connection drops.
4. **Startup Latency Tuning**: Parallelized initialization steps (loading `.env`, configuring Mapbox token, initializing Supabase, and caching states) to complete startup initializations in **under 80ms**.
5. **Pre-Upload Compression**: Picks and compresses images down to **70% quality** and a max dimension of **1024px** prior to upload to optimize storage usage and minimize transfer times.

---

## 🏗️ Folder Structure (Clean Architecture)

```text
lib/
├── app_shell.dart                     # Main app navigation wrapper (tabs)
├── main.dart                          # Application entry point & parallelized startup
├── core/                              # Shared core blocks
│   ├── constants/                     # Shared constants (Table/Bucket names)
│   ├── errors/                        # Custom Exceptions
│   ├── theme/                         # Curated app dark theme configuration
│   └── utils/                         # Geolocation, extension, and retry utilities
└── features/                          # Feature-specific modules (Feature-First)
    ├── admin/                         # Admin dashboard features
    ├── auth/                          # User Auth services, providers, and screens
    └── report/                        # Pothole report creation, detail views, and offline sync
```

---

## 🚀 Setup & Running Locally

### 1. Supabase Initialization
1. Create a new Supabase Project.
2. Run the database migration script [supabase/migrations/schema.sql](file:///c:/Users/abdul/Downloads/RoadCare/supabase/migrations/schema.sql) in your Supabase SQL Editor.
3. Run the database performance indexes migration [supabase/migrations/add_performance_indexes.sql](file:///c:/Users/abdul/Downloads/RoadCare/supabase/migrations/add_performance_indexes.sql) to set up optimal indexes.
4. Create a public storage bucket named `road-images` to store upload photos.

### 2. Local Environment Setup
Create a `.env` file in the project root containing your credentials (see [.env.example](file:///c:/Users/abdul/Downloads/RoadCare/.env.example)):
```env
MAPBOX_ACCESS_TOKEN=pk.your_mapbox_token_here
SUPABASE_URL=https://your_project_id.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
GEMINI_API_KEY=your_gemini_api_key_here
```

### 3. Launching the App
Run the following commands in your shell:
```bash
# Get flutter dependencies
flutter pub get

# Format code
dart format .

# Run static checks and unit tests
flutter analyze
flutter test

# Run app on connected device
flutter run
```

---

## 📄 License

This project was developed for educational, research, and portfolio purposes.
