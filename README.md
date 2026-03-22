# SUCHAK

SUCHAK is a complaint management system with a Flutter client and a Node.js + Express + MongoDB backend.

It supports three roles:
- `user` (citizen): create and track complaints
- `admin`: verify complaints, assign engineers, view analytics
- `engineer`: view assigned complaints and resolve them with location check

## Tech Stack

### Frontend (`frontend`)
- Flutter (Dart)
- State management: `provider`
- HTTP client: `http`
- Secure token storage: `flutter_secure_storage`
- Geolocation and map: `geolocator`, `flutter_map`, `latlong2`
- Media: `camera`, `image_picker`

### Backend (`backend`)
- Node.js (CommonJS)
- Express
- MongoDB + Mongoose
- Authentication: JWT (`jsonwebtoken`)
- Password hashing: `bcryptjs`
- Config: `dotenv`
- CORS: `cors`
- Upload helper dependency: `multer`

## Project Structure

- `frontend/` Flutter app
- `backend/` Node API server
  - `server.js` app entry point
  - `routes/` auth and complaint APIs
  - `models/` Mongoose models
  - `middleware/` JWT/role middleware

## Prerequisites

- Git
- Node.js 18+ and npm
- Flutter SDK (stable channel)
- Android Studio / Android SDK (for APK build)
- MongoDB Atlas cluster (for cloud deployment)

## Local Setup

### 1) Clone and install backend dependencies

```bash
git clone <repo-url>
cd SUCHAK/backend
npm install
```

### 2) Configure backend environment

Create `backend/.env`:

```env
JWT_SECRET=your_long_random_secret
MONGO_URI=mongodb://localhost:27017/suchak
PORT=5000
```

For cloud DB use Atlas URI in `MONGO_URI`.

### 3) Start backend

```bash
cd backend
npm start
```

Backend API base path: `http://localhost:5000/api`

### 4) Install frontend dependencies

```bash
cd frontend
flutter pub get
```

### 5) Configure frontend API URL

Edit `frontend/lib/services/api_service.dart` and set `baseUrl` to your backend:
- Local: `http://<your-local-ip>:5000/api`
- Railway: `https://suchak-production.up.railway.app/api`

### 6) Run Flutter app

```bash
cd frontend
flutter run
```

## Backend Environment Variables

- `MONGO_URI` (required in production)
- `JWT_SECRET` (required in production)
- `PORT` (optional in cloud; Railway/Render injects it)

## Railway Deployment (Backend)

1. Push backend code to GitHub.
2. In Railway: `New Project` -> `Deploy from GitHub Repo`.
3. Set service `Root Directory` to `backend`.
4. Add variables:
   - `MONGO_URI=<atlas-uri>`
   - `JWT_SECRET=<long-random-secret>`
   - `NODE_ENV=production`
5. Deploy and verify logs show DB connected and server started.
6. Use public URL as frontend API base URL with `/api` suffix.

## Build Release APK

```bash
cd frontend
flutter pub get
flutter build apk --release
```

Output APK:
- `frontend/build/app/outputs/flutter-apk/app-release.apk`

## API Overview

Auth routes:
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `GET /api/auth/engineers` (admin)

Complaint routes:
- `POST /api/complaints`
- `POST /api/complaints/:id/confirm-duplicate`
- `GET /api/complaints`
- `PUT /api/complaints/:id/verify` (admin)
- `PUT /api/complaints/:id/assign` (admin)
- `PUT /api/complaints/:id/resolve` (engineer)
- `GET /api/complaints/analytics` (admin)

## Notes

- Do not commit secrets (`.env`, private keys, service credentials).
- `backend/node_modules` should not be committed.
- Update API `baseUrl` whenever backend domain changes.
