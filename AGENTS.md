# ModelWatch - Agent Instructions

## Project Overview

ModelWatch is a native macOS menu bar application designed to help users monitor and understand their AI-related activity across different tools and platforms.

The application provides visibility into AI tool usage, subscription costs, productivity metrics, and future API consumption analytics.

ModelWatch prioritizes privacy, performance, and a seamless native Apple experience.

---

## Target Users

* Developers
* Students
* Researchers
* AI enthusiasts
* Freelancers
* Technical professionals

---

## Core Principles

1. Native macOS experience first.
2. Privacy-first architecture.
3. Local storage by default.
4. Minimal resource consumption.
5. Simple and intuitive user experience.
6. Modular and maintainable codebase.
7. Follow Apple Human Interface Guidelines.

---

## Technology Stack

* Swift
* SwiftUI
* MenuBarExtra
* SwiftData
* Charts Framework
* UserNotifications
* AppKit (when necessary)

---

## Design Philosophy

ModelWatch should feel like a built-in macOS utility.

Inspiration:

* Activity Monitor
* Control Center
* System Settings
* Battery Usage Dashboard

Avoid:

* Electron-style interfaces
* Web-based design patterns
* Excessive animations
* Complex workflows

---

## Architecture Requirements

Use MVVM architecture.

Prefer:

* Small reusable views
* Dependency injection
* Protocol-driven services
* Testable business logic

Avoid:

* Massive ViewModels
* Global state where possible
* Tight coupling between modules

---

## MVP Features

* Menu bar application
* AI application activity tracking
* Daily usage analytics
* Weekly usage analytics
* Monthly usage analytics
* Subscription tracking
* Dashboard view
* Local data persistence

---

## Future Features

* OpenAI API integration
* Anthropic API integration
* Token usage tracking
* Cost monitoring
* Spending forecasts
* AI workflow analytics
* Team dashboards
* Cross-device sync

---

## Definition of Done

A feature is complete only when:

* It compiles successfully.
* It follows SwiftUI best practices.
* It supports Dark Mode.
* It supports Light Mode.
* It has basic tests.
* It follows project architecture guidelines.
* It does not significantly impact performance.
