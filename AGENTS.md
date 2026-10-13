# Workspace Guidelines & Agent Context

## System & Host Environment
* **OS:** Linux (Pop!_OS 24.04 LTS)
* **Hardware Note:** Host system resources are constrained. Running Android Studio and the Android Studio AVD (QEMU emulator) causes severe performance degradation and freezing.

## End-to-End Simulation & Testing Policy
When asked to test, simulate, run, or diagnose the ecosystem:
1. **Never recommend or start Android Studio or the standard Android AVD.**
2. **Backend & Portals Backbone:**
   * Always rely on the existing Docker Compose stack (`docker compose up -d`).
   * Services: PostgreSQL (5432), FastAPI (`http://localhost:8000`), Nginx (`http://localhost:80`).
   * Total backend footprint is ~350 MB RAM.
3. **Web Portals Testing:**
   * Access directly via standard browser (Chrome/Firefox):
     * Admin Portal: `http://localhost/admin/`
     * Vendor Portal: `http://localhost/vendor/`
     * Consumer Web: `http://localhost/consumer/`
4. **Mobile App Simulation (`mobile_app`):**
   * **Primary / Recommended:** Flutter Web in Google Chrome (`cd mobile_app && flutter run -d chrome`). Emulate mobile screens via Chrome DevTools (`Ctrl+Shift+M`). Base URL connects to `http://127.0.0.1:8000/api/v1`.
   * **Physical Device Alternative:** Physical Android phone via USB + `scrcpy` (`adb reverse tcp:8000 tcp:8000`). Zero PC emulation load.
   * **Linux Desktop Alternative:** `cd mobile_app && flutter run -d linux` for native desktop execution.

## Platform Isolation & Modification Policy
* **Targeted Platform Scope:**
  * When a request specifically specifies the **Flutter app** (`mobile_app`), only inspect and modify files within `mobile_app/`. Do NOT modify Web Portals (`web_portal/`).
  * When a request specifically specifies the **Desktop Web or Mobile View** (`web_portal/consumer/index.html` or other web portals), only inspect and modify web portal files. Do NOT modify `mobile_app/`.
  * **Strict Isolation Rule:** Never touch or alter an unspecified platform or view. Only make cross-platform changes when explicitly asked to update both.
