# Task
Use omx team to translate all user-visible app pages into Chinese while preserving the TodayFocus brand.

# Desired outcome
- All visible macOS and shared iOS UI strings are Chinese, except brand/system-required terms.
- Focus battle / PK pages remain warm wood style, not card-room style.
- Existing PK fallback, session linking, and supervision flows keep working.

# Known facts
- The repo already has a zh-Hans localization file and AppText helper.
- Main navigation, some runtime strings, and part of PK are already localized.
- Many SwiftUI views still contain hard-coded English text, especially Plan, Tasks, Blocker, WhiteNoise, Settings, Trash, CurrentSession, Account, Mobile shell, and some PK support sheets.
- Current branch contains local in-progress localization changes and should not be reset.

# Constraints
- Preserve TodayFocus brand name.
- Use team mode, with disjoint write scopes.
- Avoid touching build artifact deletions, LocalSigning.xcconfig, tmp/screens, default.profraw.
- Keep translations in Chinese, with PK concept rendered as 专注对战 / 对战桌 / 对战房间.

# Unknowns
- Whether any remaining runtime strings outside the searched UI/views still surface English in edge flows.
- Whether some tests assert old English literals and need coordinated updates.

# Likely touchpoints
- Apps/FocusSessionApp/UI/**
- Apps/FocusSessionMobileApp/UI/**
- Apps/FocusSessionApp/ViewModels/**
- Apps/FocusSessionApp/Plan/PlanGoal.swift
- Apps/FocusSessionApp/Tasks/FocusTask.swift
- Apps/FocusSessionApp/Resources/zh-Hans.lproj/Localizable.strings
- Tests/FocusSessionAppTests/**
