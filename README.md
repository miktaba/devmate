# DevMate - My Learning Project for Flutter Development

## Introduction

DevMate was born from my desire to immerse myself in the Flutter ecosystem and modern approaches to mobile development. Working on this project, I actively studied not only the framework itself but also integration with external authentication systems and APIs.

## Features

- GitHub integration
- Task management
- Skills tracking
- Project organization
- Secure authentication

## Project Setup

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (included with Flutter)
- Android Studio or Visual Studio Code with Flutter extensions
- iOS development setup (if developing for iOS)
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/devmate.git
cd devmate
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up environment variables:
```bash
# Create the environment file
cp lib/core/config/env.example.dart lib/core/config/env.dart
```

4. Update the environment variables in `lib/core/config/env.dart` with your GitHub OAuth credentials.

5. Run the application:
```bash
flutter run
```

### Security Note

The application uses GitHub OAuth for authentication. For security purposes:

- Environment variables containing sensitive data are stored in `lib/core/config/env.dart`
- This file is excluded from version control (.gitignore)
- Before publishing your app, make sure to create your own GitHub OAuth application and update the credentials

### GitHub OAuth Setup

1. Go to GitHub Developer Settings (https://github.com/settings/developers)
2. Create a new OAuth App
3. Set the Authorization callback URL to `devmate://callback`
4. Copy your Client ID and Client Secret to the `env.dart` file

## Authentication Experiments

One of the key challenges was implementing two authentication systems:

- **Firebase Auth**: Although this is redundant for this application, I deliberately included Firebase to understand the capabilities of this platform. I set up work with both an emulator for testing and a production environment.
- **GitHub OAuth**: The main authorization system, which also provides access to the GitHub API for working with repositories and other data.

## What I Learned in the Process

- **Riverpod and Reactivity**: I figured out a modern approach to application state management, which is significantly different from the classic StatefulWidget
- **Offline-first Approach**: Implemented local storage on Hive for working without an internet connection
- **Clean Architecture in Flutter**: Applied Domain-Driven Design principles, dividing the code into layers
- **Working with REST API**: Integrated with GitHub API via OAuth, learned to process various responses and errors
- **Apple-style UI/UX**: Built an interface in Cupertino style, while maintaining a native feel on both platforms

## A Continuing Journey

This project is my first serious experience with Flutter, and I continue to improve it every day. I actively study best practices and apply new knowledge in practice.

With the help of AI, I was able to overcome many technical obstacles in unfamiliar areas, which allowed me to focus on understanding architectural principles and business logic.

## Technologies I Worked With

- **Flutter & Dart**: Project foundation
- **Firebase**: Authentication and Firestore (planned)
- **Riverpod**: State management
- **Hive**: Local storage
- **Go Router**: Navigation
- **GitHub API**: Repository integration

## Resources That Helped Me Learn

- Official Flutter documentation
- Courses on clean architecture in mobile development
- Articles about Riverpod and reactive programming
- Flutter developer community
- AI assistants for solving specific problems

---

The project is open to code review and improvement suggestions! I would be happy to discuss technical solutions and share experiences.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
