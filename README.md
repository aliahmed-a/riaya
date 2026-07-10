# 🏥 RIAYA Healthcare Management Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev/)
[![Riverpod](https://img.shields.io/badge/State_Management-Riverpod-blue.svg)](https://riverpod.dev/)
[![Routing](https://img.shields.io/badge/Routing-GoRouter-lightgrey.svg)](https://pub.dev/packages/go_router)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A robust, multi-role healthcare management application built with Flutter. **RIAYA** is designed to streamline operations for medical complexes, handling everything from receptionist workflows to doctor-specific clinical dashboards. The project places a strong emphasis on clean architecture, secure networking, and strict separation of concerns.

---

## 📑 Table of Contents
1. [Screenshots](#-screenshots)
2. [Key Features](#-key-features)
3. [Tech Stack](#-tech-stack)
4. [Architecture & Folder Structure](#-architecture--folder-structure)
5. [Project Status & Roadmap](#-project-status--roadmap)
6. [Getting Started](#-getting-started)
7. [Environment Configuration](#-environment-configuration)
8. [License](#-license)
9. [Contact](#-contact)

---

## 📸 Screenshots

*(Replace these placeholders with actual screenshots or GIFs of your app once ready)*

| Receptionist Portal | Doctor Dashboard | Login / Auth | Dark Mode |
| :---: | :---: | :---: | :---: |
| <img src="https://via.placeholder.com/200x400.png?text=Receptionist" width="200"/> | <img src="https://via.placeholder.com/200x400.png?text=Doctor" width="200"/> | <img src="https://via.placeholder.com/200x400.png?text=Login" width="200"/> | <img src="https://via.placeholder.com/200x400.png?text=Dark+Mode" width="200"/> |

---

## ✨ Key Features

### 🔐 Core & Security
*   **Role-Based Access Control (RBAC):** Distinct routing and UI experiences tailored for different staff roles (Receptionist vs. Doctor) powered by GoRouter.
*   **Advanced Authentication Flow:** 
    *   Custom Dio interceptors for seamless JWT token management.
    *   Automatic interception of `401 Unauthorized` errors.
    *   Isolated networking instances to securely refresh tokens and seamlessly retry failed requests without interrupting the user experience.
*   **Synchronous Storage Access:** Data access built on top of asynchronous `SharedPreferences` using Riverpod dependency injection during app initialization.
*   **Dynamic Theming:** Smooth Light and Dark mode integration managed globally via Riverpod.

### 👩‍💻 Receptionist Portal (Completed)
*   Dedicated dashboard for front-desk staff.
*   Patient registration and intake processing.
*   Appointment scheduling and queue management.

### 🩺 Doctor Dashboard (In Progress)
*   Secure portal for viewing assigned daily schedules.
*   Workflows for marking appointments as "Complete".
*   Digital submission of patient diagnosis notes.

---

## 🛠 Tech Stack

| Technology | Purpose |
| :--- | :--- |
| **Flutter** | Core UI framework for cross-platform deployment. |
| **Dart** | Programming language. |
| **Riverpod** | Reactive state management and dependency injection. |
| **GoRouter** | Declarative, URL-based routing and deep linking. |
| **Dio** | Powerful HTTP networking and interceptor handling. |
| **SharedPreferences** | Persistent, local key-value storage. |

---

## 🏗 Architecture & Folder Structure

This project strictly adheres to the **Separation of Concerns** principle to ensure high scalability and testability.

*   **`main.dart` (The Engine Room):** Strictly handles native engine bindings, asynchronous disk reading, and Riverpod dependency injection. It guarantees the environment is fully prepared before the UI ever attempts to render.
*   **`app.dart` (The Presentation Layer):** Strictly handles the visual shell (`MaterialApp.router`), routing configurations, and theming. It remains completely decoupled from startup logic.

### 📂 Directory Layout
```text
lib/
├── core/                   # Shared app-wide resources
│   ├── network/            # Dio client, interceptors, API config
│   ├── router/             # GoRouter configuration & routes
│   ├── theme/              # AppTheme, Light/Dark mode settings
│   └── utils/              # Storage services, formatters, helpers
├── features/               # Feature-based architecture
│   ├── auth/               # Login, JWT management, Session handling
│   ├── doctor/             # Doctor dashboard, diagnosis notes
│   └── receptionist/       # Receptionist portal, appointment queue
├── shared/                 # Reusable UI widgets (buttons, dialogs, inputs)
├── app.dart                # Visual shell and MaterialApp setup
└── main.dart               # App initialization and dependency injection
