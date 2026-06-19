<div align="center">

<img src="https://img.shields.io/badge/🚧-RoadCare-2563EB?style=for-the-badge&labelColor=0a0a0a&color=00C9A7" height="40"/>

# RoadCare

### AI-Assisted Smart Road Damage Reporting System

<p>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=flat-square&logo=supabase&logoColor=white" />
  <img src="https://img.shields.io/badge/PostgreSQL-Database-4169E1?style=flat-square&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/Google-Gemini%202.5%20Flash-4285F4?style=flat-square&logo=google&logoColor=white" />
  <img src="https://img.shields.io/badge/Google%20Maps-Location-34A853?style=flat-square&logo=googlemaps&logoColor=white" />
  <img src="https://img.shields.io/badge/Riverpod-State%20Management-6C63FF?style=flat-square" />
</p>

</div>

---

# Overview

RoadCare is an **AI-assisted mobile application** built using **Flutter**, **Supabase**, and **Google Gemini 2.5 Flash** to modernize road damage reporting.

Users can capture or upload road images, automatically analyze the damage using AI, generate professional inspection reports, and submit geo-tagged reports for efficient road maintenance.

The application combines **mobile development**, **cloud backend**, **computer vision**, and **Generative AI** into a scalable production-ready solution.

---

# Features

| Feature | Description |
|---------|-------------|
| 🤖 AI Road Analysis | Analyze uploaded road images using Google Gemini 2.5 Flash |
| 🧠 AI Report Generation | Automatically generate structured road inspection reports |
| ⚠ Damage Classification | Detect damage type and classify severity |
| 🚧 Repair Recommendation | AI suggests repair priority and safety warning |
| 📍 GPS Location | Automatically capture user's location |
| 🗺 Google Maps | Display reported road damages on an interactive map |
| 📷 Image Upload | Upload and securely store road damage images |
| ☁ Supabase Storage | Cloud storage for uploaded images |
| 🔐 Authentication | Secure login using Supabase Authentication |
| 🗄 PostgreSQL Database | Store reports using Supabase PostgreSQL |
| ⚡ Fast Performance | Optimized image uploads, API calls, and caching |
| 🛡 Secure Backend | Row Level Security (RLS) enabled for data protection |

---

# AI Workflow

```text
Capture Image
       │
       ▼
 Google Gemini 2.5 Flash
       │
       ▼
Analyze Road Damage
       │
       ├── Damage Type
       ├── Severity
       ├── Repair Priority
       ├── Estimated Dimensions
       ├── Safety Warning
       └── Professional Report
       │
       ▼
User Review
       │
       ▼
Submit Report
       │
       ▼
Supabase Database
```

---

# Tech Stack

| Layer | Technology |
|--------|------------|
| Mobile App | Flutter |
| Language | Dart |
| Backend | Supabase |
| Database | PostgreSQL |
| Authentication | Supabase Auth |
| Cloud Storage | Supabase Storage |
| AI | Google Gemini 2.5 Flash |
| Maps | Google Maps |
| State Management | Riverpod |
| Architecture | Clean Architecture |
| API Communication | REST API |

---

# Architecture

```
lib/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── auth/
│   ├── report/
│   ├── map/
│   ├── profile/
│   └── notifications/
│
├── services/
│
├── widgets/
│
└── main.dart
```

---

# AI Report Example

```json
{
  "damage_type": "Pothole",
  "severity": "High",
  "repair_priority": "Immediate",
  "confidence": 95,
  "estimated_diameter_cm": 68,
  "estimated_depth_cm": 12,
  "description": "Large pothole located near the center lane with surrounding pavement cracks.",
  "safety_warning": "High accident risk for two-wheelers.",
  "suggested_action": "Immediate Repair"
}
```

---

# Performance Optimizations

- Image compression before upload
- Cached network images
- Lazy loading
- Optimized Riverpod providers
- Retry mechanism for API requests
- Timeout handling
- Production-level exception handling
- Database query optimization
- Supabase indexes
- Optimized Google Maps rendering
- AI request caching

---

# Security

- Supabase Row Level Security (RLS)
- Environment variable configuration
- Secure authentication
- API key protection
- Input validation
- JSON response validation
- Secure database access

---

# Getting Started

## Prerequisites

- Flutter 3.x
- Supabase Project
- Google AI Studio API Key
- Google Maps API Key

---

## Installation

```bash
git clone https://github.com/AbdulFahad31/RoadCare.git

cd RoadCare

flutter pub get

flutter run
```

---

## Environment Variables

Create a `.env` file:

```env
SUPABASE_URL=YOUR_SUPABASE_URL

SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY

GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

---

# Production Features

```
✅ Flutter
✅ Supabase Authentication
✅ PostgreSQL
✅ Supabase Storage
✅ Google Maps
✅ GPS Tracking
✅ AI Report Generation
✅ Damage Classification
✅ Repair Priority Prediction
✅ Security (RLS)
✅ Repository Pattern
✅ Clean Architecture
✅ Riverpod
✅ Performance Optimizations
```

---

# Future Enhancements

- [ ] Government Admin Dashboard
- [ ] Push Notifications
- [ ] Offline Synchronization
- [ ] Duplicate Report Detection using AI
- [ ] Road Condition Heatmap
- [ ] Video-based Road Inspection
- [ ] Multi-language Support
- [ ] Analytics Dashboard

---

# License

This project was developed for educational, research, and portfolio purposes.

---

<div align="center">

### Built with ❤️ using Flutter • Supabase • Google Gemini AI

If you found this project interesting, consider giving it a ⭐

</div>
