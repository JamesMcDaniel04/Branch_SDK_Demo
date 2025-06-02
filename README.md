# Flutter Creature Creator with Branch SDK

A cross-platform Flutter application that demonstrates Branch SDK integration through a fun creature creation and sharing experience.

## Features

### 🎨 Creature Creation
- Customizable creature bodies, eyes, mouths, and accessories
- Color selection for personalization
- Random creature generator
- Real-time preview

### 🔗 Branch SDK Integration
- **Deep Linking**: Share creatures via Branch links
- **Analytics Tracking**: Track user interactions and sharing
- **Cross-Platform**: Works on iOS, Android, macOS, and Web
- **Fallback URLs**: Graceful handling when Branch services are unavailable

### 📱 Core Features
- Creature gallery and collection management
- Rewards system with points for sharing and creating
- Battle arena (coming soon)
- Real-time share URL generation and display
- Tap-to-copy functionality for easy sharing

## Branch SDK Implementation

This app uses the **Branch REST API** approach, which provides:
- ✅ Full cross-platform compatibility
- ✅ No SDK compatibility issues
- ✅ Direct HTTP API integration
- ✅ Custom fallback handling
- ✅ Real-time link generation

### Key Branch Features Demonstrated
- Link creation with custom data
- Event tracking (standard and custom events)
- Deep link routing and handling
- Social sharing optimization

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- A Branch.io account and test key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/flutter-creature-creator.git
   cd flutter-creature-creator
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Branch**
    - Update the Branch key in `lib/main.dart`:
   ```dart
   static const String _branchKey = 'your_branch_key_here';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### macOS
Network permissions are already configured in the entitlements files:
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

#### iOS/Android
Add your Branch configuration to the respective platform files as per Branch documentation.

## Project Structure

```
lib/
├── main.dart                 # Main app entry point and Branch integration
├── models/
│   └── creature.dart        # Creature data model
├── screens/
│   ├── splash_screen.dart   # App initialization
│   ├── home_screen.dart     # Main dashboard
│   ├── creator_screen.dart  # Creature creation
│   ├── gallery_screen.dart  # Creature collection
│   └── save_screen.dart     # Monster saving and sharing
└── services/
    └── branch_api.dart      # Branch REST API integration
```

## Branch Integration Details

### Link Creation
```dart
final shareUrl = await BranchRestAPI.createBranchLink(
  title: 'Check out my monster: ${creature.name}!',
  description: 'I just created ${creature.name} in Monster Factory!',
  customData: {
    'monster_id': creature.id,
    'monster_data': jsonEncode(creature.toJson()),
    'route': '/monster/${creature.id}',
    // ... additional custom data
  },
);
```

### Event Tracking
```dart
await BranchRestAPI.trackStandardEvent(
  eventName: 'SHARE',
  eventData: {'description': 'Monster shared successfully'},
  customData: {'monster_id': creature.id, 'share_method': 'clipboard'},
);
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with Flutter and Dart
- Branch.io for deep linking and analytics
- Emoji graphics for creature components

## Demo

The app demonstrates a complete Branch SDK integration with:
- Real monster creation and sharing
- Live Branch link generation
- Deep link handling
- Analytics tracking
- Cross-platform compatibility

Perfect for learning Branch SDK integration patterns in Flutter applications!