# Conversa - Project Structure Documentation

## Overview
This document outlines the organized file structure for the Conversa chat application, designed to maintain clean architecture and separation of concerns.

## Directory Structure

```
Conversa/
├── ChatoraApp.swift                    # Main app entry point
├── ContentView.swift                   # Root view controller
├── AuthenticationManager.swift         # Authentication logic
├── GoogleService-Info.plist           # Firebase configuration
├── Assets.xcassets/                    # App assets and images
├── Preview Content/                    # Preview assets for SwiftUI
├── Models/                             # Data models
│   └── User.swift                      # User data model
└── Views/                              # All UI views organized by feature
    ├── Authentication/                 # Authentication-related views
    │   ├── LoginView.swift            # User login interface
    │   └── RegisterView.swift         # User registration interface
    ├── Components/                     # Reusable UI components
    │   ├── LoadingView.swift          # Loading screen component
    │   ├── WelcomeHeaderView.swift    # Welcome header component
    │   └── SharedComponents.swift     # Other shared UI components
    └── Home/                          # Home screen views
        └── HomeView.swift             # Main home interface
```

## File Descriptions

### Core Files
- **ChatoraApp.swift**: Main application entry point, handles Firebase configuration
- **ContentView.swift**: Root view that manages authentication state and navigation
- **AuthenticationManager.swift**: Handles user authentication logic and state management

### Models
- **User.swift**: User data model with Firebase integration, includes convenience methods and sample data

### Views

#### Authentication Views
- **LoginView.swift**: User login interface with email/password authentication
- **RegisterView.swift**: User registration interface for new accounts

#### Components (Reusable UI)
- **LoadingView.swift**: Animated loading screen with app branding
- **WelcomeHeaderView.swift**: Reusable welcome header with user greeting
- **SharedComponents.swift**: Collection of other shared UI components

#### Home Views
- **HomeView.swift**: Main authenticated user interface with chat placeholder and user actions

## Architecture Principles

### Separation of Concerns
- **Models**: Data structures and business logic
- **Views**: UI presentation and user interaction
- **Components**: Reusable UI elements
- **Authentication**: Centralized auth management

### File Organization Benefits
1. **Maintainability**: Easy to locate and modify specific features
2. **Scalability**: Clear structure for adding new features
3. **Reusability**: Components can be easily shared across views
4. **Testing**: Isolated components are easier to test
5. **Collaboration**: Team members can work on different areas without conflicts

## Future Expansion

### Planned Directories
```
Views/
├── Chat/                              # Chat-related views
│   ├── ChatListView.swift            # List of user chats
│   ├── ChatView.swift                # Individual chat interface
│   └── MessageBubbleView.swift       # Message display component
├── Profile/                          # User profile views
│   ├── ProfileView.swift             # User profile display
│   └── EditProfileView.swift         # Profile editing interface
└── Settings/                         # App settings views
    ├── SettingsView.swift            # Main settings interface
    └── NotificationSettingsView.swift # Notification preferences
```

### Additional Models
```
Models/
├── Chat.swift                        # Chat room data model
├── Message.swift                     # Individual message model
└── ChatManager.swift                 # Chat business logic
```

## Development Guidelines

### Adding New Views
1. Place views in appropriate feature directories
2. Create reusable components in the Components folder
3. Follow the established naming conventions
4. Include preview providers for SwiftUI previews

### Component Design
- Keep components small and focused
- Make components configurable through parameters
- Include sample data for previews
- Document component usage and parameters

### Model Design
- Include proper data validation
- Provide convenience initializers
- Add computed properties for common operations
- Include sample data for testing and previews

## Best Practices

1. **Consistent Naming**: Use descriptive names that clearly indicate purpose
2. **Single Responsibility**: Each file should have one clear purpose
3. **Reusability**: Design components to be reused across different views
4. **Documentation**: Include comments for complex logic and public interfaces
5. **Preview Support**: Always include SwiftUI previews for visual components

This structure provides a solid foundation for the Conversa chat application while remaining flexible for future enhancements and features.
