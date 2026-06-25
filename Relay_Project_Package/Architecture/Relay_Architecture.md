# Relay Architecture

## Module Layout

```text
RelayApp
├── UI
│   ├── CommandPalette
│   ├── MenuBar
│   ├── Settings
│   └── Logs
│
RelayCore
├── Models
│   ├── RelayCommand
│   ├── RelayTask
│   ├── TaskStep
│   └── CommandPack
│
├── Search
│   └── FuzzySearchEngine
│
├── Storage
│   ├── JSONStore
│   └── FutureSQLiteStore
│
RelayTasks
├── TaskRunner
├── StepExecutor
├── RetryPolicy
└── HealthChecks
│
RelaySecurity
├── SudoDetector
├── TouchIDStatus
├── PrivilegedHelperClient
└── PermissionPrompts
```

## Execution Flow

```text
User opens palette
        ↓
Search command library
        ↓
Select command/task
        ↓
Resolve variables
        ↓
Check confirmation/elevation
        ↓
Execute command or workflow
        ↓
Capture output / logs
        ↓
Show notification/result
```

## Recommended Stack

- Swift
- SwiftUI
- AppKit
- Combine or Observation
- Structured Concurrency
- Actors for execution safety
- JSON persistence initially
- SQLite later if needed
- ServiceManagement for privileged helper
