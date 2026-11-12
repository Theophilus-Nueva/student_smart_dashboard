# Smart Campus Tour Guide and Information System

One Flutter mobile app, built up across 7 weekly labs (BSIT, LPU Cavite, App Development). Each week extends the same app.
Repo state: Week 3 committed. Design lives in Figma; lab notes live in Obsidian.

## Sources of truth
- **Figma:** file key `mTtIO9cEL89zu0q0KJuppI` ("Untitled", Page 1). Sections: Shared · Both roles, Student, Faculty, Components. Frames are iPhone 390x844.
- **Obsidian vault:** `Documents/Obsidian Vault/LPU App Dev Lab - Smart Campus Dashboard/` (00 Index, Course Overview, Week 1-7 notes, Figma Prototype, Decisions, Session Log). Read Decisions and the relevant Week note before building a feature.
- **Lab PDFs:** Week 1-7 handouts (not in repo).

## Rules
- **Conflict rule: the later lab week wins** when two labs disagree.
- App name: **Smart Campus Tour Guide** (Week 7).
- Programmes: BS Information Technology (BSIT) / BS Computer Science (BSCS) / BS Library and Information Science (BSLIS).
- Registration form becomes **Add/Edit Student** (Week 4).
- Fingerprint login via `local_auth` (Week 6).
- Network status shown as green / amber / red (Week 7).
- Current-location card with an Open Map button (Week 6).
- Week 7 optional AR guide is included (since 2026-11-08) as a simulated AR view: live camera via `mobile_scanner`, compass-placed location labels, QR checkpoints UC001-UC005, guided route. `ar_flutter_plugin` (named in the lab) only supports Dart 2, so it is not used. Launched from the floating "AR Guide" button on Home.

## Roles and access control
Two dashboards, separate access: **Student** and **Faculty**. Shared core plus role extras.
- Both roles share the same bottom nav: **Home, Analytics, Device, Settings**. Tab content depends on the role.
- Role comes from the signed-in LPU account (password or fingerprint).
- Faculty-only screens: Student Records, Add/Edit Student, Student Details, Online Directory (+ loading/error states), Class Analytics, sync controls and resets. A student opening one is redirected to **Access Denied**.
- Students can view and export only their own record; their data syncs automatically.
- Shared screens: Login, Biometric Login, Recent Activity (empty and with data), File Saved, About LPU, Campus Tour, Location Detail, Map, Device, Cloud Tasks, Notifications, Emergency Contacts, Faculty Directory.

## Packages named in the labs
http, shared_preferences, path_provider, geolocator, google_maps_flutter, url_launcher, firebase_core, cloud_firestore, flutter_local_notifications, local_auth, connectivity_plus.
All of the above are in pubspec except `google_maps_flutter`, removed on 2026-11-12: the Map screen uses OpenStreetMap tiles through `flutter_map` + `latlong2`. Also added: `mobile_scanner` (AR guide camera and QR checkpoints), `share_plus`, `geocoding`. Not used: `ar_flutter_plugin` (Dart 2 only).

## Existing code (lib/)
screens: dashboard_screen, dashboard_body, dashboard_cards, activity_feed, file_storage_screen, registration_form_screen, summary_page_screen. widgets: notification_badge, profile_card, dashboard_tile. services: api.dart. Home currently has a profile (ID) card, world clock, and Logged in Devices.

## Design notes (Figma)
- Brand red `#B71C1C`, white surfaces, black icons with no tinted badge behind them (bottom nav icons are white; the circle marks selection).
- Home order: header, tabs (Dashboard / Recent Activity), network status, current location, ID card, Logged in Devices (e.g. iPhone 13, iOS 27, Online), dashboard actions, tour progress, world clock (Manila, Tokyo, New York), bottom nav.
- Map screen (app) shows live OpenStreetMap tiles; the Figma frame uses an OpenStreetMap screenshot of the LPU Cavite campus (Governor's Drive, COECSA) with School/Home/Workplace markers and a live current-location dot.

## Known gaps (design side)
- Login title still reads "Student Information System" (font could not be edited).
- About LPU has placeholder text; Login has a Cloudflare widget screenshot.
- Map image crop may need a manual tweak.
- 7 open questions for the instructor are in the vault's Course Overview.

## Working style
- Check the Figma frame and the vault Decisions note before changing UI.
- Keep Student and Faculty code paths separate; gate Faculty screens with the role check.
