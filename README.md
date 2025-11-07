# 🎮 Tic-Tac-Toe Multiplayer Game

A real-time multiplayer tic-tac-toe game built with Flutter (frontend) and Go/Nakama (backend). Supports multiple concurrent games, matchmaking, leaderboards, and WebSocket communication.

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue.svg)](https://flutter.dev/)
[![Go](https://img.shields.io/badge/Go-1.22.4-blue.svg)](https://golang.org/)
[![Nakama](https://img.shields.io/badge/Nakama-3.22.0-orange.svg)](https://heroiclabs.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-12.2-blue.svg)](https://www.postgresql.org/)

## 📋 Table of Contents

- [🎯 Features](#-features)
- [🏗️ Architecture](#️-architecture)
- [🛠️ Prerequisites](#️-prerequisites)
- [🚀 Quick Start](#-quick-start)
- [📦 Detailed Setup](#-detailed-setup)
- [🧪 Testing](#-testing)
- [🚀 Deployment](#-deployment)
- [🐛 Troubleshooting](#-troubleshooting)
- [📡 API Reference](#-api-reference)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

## 🎯 Features

### ✅ Core Features

- **Real-time Multiplayer**: WebSocket-powered live gameplay
- **Matchmaking**: Create/join games with match codes
- **Multiple Game Modes**: Classic & Timed modes
- **Leaderboards**: Global wins & win streaks tracking
- **Concurrent Games**: Multiple matches running simultaneously
- **Cross-platform**: Android, iOS, Web support
- **Player Stats**: Wins/losses/streaks per player

### 🎨 User Experience

- Beautiful Material Design UI
- Smooth animations and transitions
- Responsive layout for all screen sizes
- Intuitive matchmaking flow
- Real-time game state updates

## 🏗️ Architecture

### Tech Stack

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| **Frontend** | Flutter | 3.9.2+ | Cross-platform mobile app |
| **Backend** | Go + Nakama | 1.22.4 / 3.22.0 | Real-time game server |
| **Database** | PostgreSQL | 12.2 | Player stats & leaderboards |
| **Real-time** | WebSocket | - | Live game updates |
| **Auth** | Device Authentication | - | Simple player identification |
| **State Management** | Flutter BLoC | 9.0.0 | Frontend state management |

### System Architecture

```text
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Nakama Server  │    │  PostgreSQL DB  │
│                 │◄──►│                 │◄──►│                 │
│ • UI/UX         │    │ • Game Logic    │    │ • Player Stats  │
│ • WebSocket     │    │ • Matchmaking   │    │ • Leaderboards  │
│ • BLoC State    │    │ • Real-time     │    │ • Game History  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┘───────────────────────┘
                        Docker Compose Network
```

## 🛠️ Prerequisites

### System Requirements

- **Operating System**: Linux, macOS, or Windows
- **RAM**: Minimum 4GB (8GB recommended)
- **Storage**: 2GB free space
- **Network**: Stable internet connection

### Required Software

#### 1. Docker & Docker Compose

```bash
# Install Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 2. Go (1.22.4+)

```bash
# Download and install Go
wget https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz

# Add to PATH
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
```

#### 3. Flutter (3.9.2+)

```bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

#### 4. Android Studio (for Android development)

```bash
# Download from: https://developer.android.com/studio
# Install Android SDK, Android Emulator, and required packages
```

#### 5. Make (build tool)

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y make

# macOS
# Already installed

# Windows: Install via Chocolatey or download from GNU
```

### Environment Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/prasanth-33460/tic-tac-toe.git
   cd tic-tac-toe
   ```

2. **Verify installations**

   ```bash
   # Docker
   docker --version
   docker-compose --version

   # Go
   go version

   # Flutter
   flutter --version
   flutter doctor

   # Make
   make --version
   ```

## 🚀 Quick Start

### One-Command Setup (Recommended)

```bash
# Clone and setup everything
git clone https://github.com/prasanth-33460/tic-tac-toe.git
cd tic-tac-toe

# Start backend
cd backend && make run

# In another terminal, start frontend
cd ../frontend && flutter pub get && flutter run
```

### Manual Setup

1. **Backend Setup**

   ```bash
   cd backend
   make dev  # This builds, updates deps, and starts services
   ```

2. **Frontend Setup**

   ```bash
   cd frontend
   flutter pub get
   flutter run -d chrome  # For web testing
   # OR
   flutter run -d android  # For Android device/emulator
   ```

3. **Verify Setup**

   ```bash
   # Check backend containers
   docker ps

   # Should see: postgres, nakama containers running
   ```

## 📦 Detailed Setup

### Backend Setup

#### 1. Environment Configuration

The backend uses Docker Compose with the following services:

- **PostgreSQL** (Port 5432): Database for player stats and leaderboards
- **Nakama** (Ports 7349, 7350, 7351): Game server for matchmaking and real-time communication

#### 2. Build Process

```bash
cd backend

# Clean previous builds
make clean

# Update dependencies
make deps

# Build the Go plugin
make build

# Start all services
make run
```

#### 3. Service Ports

| Service | Port | Purpose |
|---------|------|---------|
| PostgreSQL | 5432 | Database connections |
| Nakama HTTP | 7350 | REST API calls |
| Nakama WebSocket | 7351 | Real-time communication |
| Nakama gRPC | 7349 | Internal communications |

#### 4. Database Schema

The application automatically creates the following tables:
- Player profiles and statistics
- Match history and results
- Leaderboard rankings
- Game state persistence

### Frontend Setup

#### 1. Flutter Configuration

```bash
cd frontend

# Install dependencies
flutter pub get

# Clean build (if needed)
flutter clean && flutter pub get
```

#### 2. Platform-Specific Setup

##### Android Setup

```bash
# Enable Android development
flutter config --enable-android

# Accept Android licenses
flutter doctor --android-licenses

# Create Android emulator (optional)
flutter emulators --create android_emulator
flutter emulators --launch android_emulator
```

##### iOS Setup (macOS only)

```bash
# Enable iOS development
flutter config --enable-ios

# Install CocoaPods
sudo gem install cocoapods

# Setup iOS project
cd ios && pod install
```

##### Web Setup

```bash
# Enable web development
flutter config --enable-web

# Build for web
flutter build web
```

#### 3. Configuration

The app connects to the backend using settings in `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String nakamaHost = 'localhost'; // Change for production
  static const int nakamaPort = 7350;
  static const String nakamaServerKey = 'defaultkey';
  static const bool useSsl = false; // Set to true for HTTPS
}
```

### Development Environment

#### VS Code Setup (Recommended)

1. **Install Extensions**
   - Flutter
   - Dart
   - Docker
   - Go

2. **Workspace Settings**

   ```json
   {
     "dart.flutterSdkPath": "path/to/flutter",
     "go.gopath": "path/to/go/workspace"
   }
   ```

#### Android Studio Setup

1. **Import Project**
   - Open Android Studio
   - File → Open → Select `frontend/android` folder
   - Wait for Gradle sync

2. **Flutter Plugin**
   - File → Settings → Plugins → Install Flutter plugin

### Manual Testing Scenarios

#### 1. Single Player Game

1. Launch app → Enter username → Tap "Quick Match"
2. Play against yourself by tapping positions
3. Verify game ends with winner/draw

#### 2. Multiplayer Game

1. **Player 1**: Create match → Get code
2. **Player 2**: Join with code
3. Take turns → Verify real-time updates
4. Check winner determination

#### 3. Leaderboard Testing

1. Play multiple games
2. Navigate to Leaderboard
3. Verify player names and scores
4. Check ranking accuracy

#### 4. Network Testing

1. Test on different devices
2. Test with poor network conditions
3. Verify reconnection after disconnect

## 🚀 Deployment

### Local Development

```bash
# Backend
cd backend && make run

# Frontend
cd frontend && flutter run -d chrome
```

### Production Deployment

#### Option 1: Docker Deployment

```bash
# Build production images
cd backend
docker build -t tic-tac-toe-backend .
docker-compose -f docker-compose.prod.yml up -d
```

#### Option 2: Cloud Deployment

##### AWS Deployment

```bash
# Deploy to EC2
# 1. Launch EC2 instance with Docker
# 2. Clone repository
# 3. Run docker-compose up -d
# 4. Configure security groups (ports 7350, 7351)
# 5. Update frontend config with EC2 IP
```

##### Heroku Deployment

```bash
# Backend
heroku create tic-tac-toe-backend
heroku container:push web
heroku container:release web

# Frontend (Web)
flutter build web
# Deploy to Firebase/Netlify/Vercel
```

#### Option 3: Kubernetes Deployment

```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tic-tac-toe-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: tic-tac-toe
  template:
    spec:
      containers:
      - name: nakama
        image: registry.heroiclabs.com/heroiclabs/nakama:3.22.0
        ports:
        - containerPort: 7350
```

### Mobile App Deployment

#### Android APK

```bash
cd frontend

# Build APK
flutter build apk --release

# Install on device
flutter install
```

#### iOS App Store

```bash
# Build for iOS
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace

# Archive and upload to App Store Connect
```

#### Web Deployment

```bash
# Build web app
flutter build web

# Deploy to hosting service
# Firebase: firebase deploy
# Netlify: netlify deploy
# Vercel: vercel --prod
```

## 🐛 Troubleshooting

### Common Issues

#### Backend Won't Start

```bash
# Check Docker containers
docker ps -a

# View container logs
docker logs nakama
docker logs postgres

# Restart services
cd backend && make restart

# Check port conflicts
netstat -tulpn | grep :7350
```

#### Frontend Connection Fails

```bash
# Check backend connectivity
curl http://localhost:7350/healthcheck

# For Android emulator, use:
# nakamaHost = '10.0.2.2'

# For physical device, use computer IP:
# nakamaHost = '192.168.1.100'  # Your computer's IP
```

#### Flutter Issues

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check device connection
flutter devices

# Update Flutter
flutter upgrade
```

#### Database Issues

```bash
# Reset database
cd backend
make clean
docker volume rm tic-tac-toe_data
make run

# Check database logs
docker logs postgres
```

#### WebSocket Connection Drops

```bash
# Check network connectivity
ping localhost

# Verify Nakama WebSocket port
netstat -tulpn | grep :7351

# Check browser console for errors
# Look for CORS or certificate issues
```

### Debug Commands

```bash
# Backend debug
docker-compose logs -f nakama
docker-compose logs -f postgres

# Frontend debug
flutter logs
flutter run --debug

# Network debug
telnet localhost 7350
curl -v http://localhost:7350
```

## 📡 API Reference

### RPC Endpoints

| Endpoint | Method | Parameters | Response |
|----------|--------|------------|----------|
| `create_quick_match` | POST | `{}` | Match details |
| `find_match` | POST | `{"mode": "classic"}` | Match code |
| `get_match_by_code` | POST | `{"code": "ABC123"}` | Match details |
| `get_leaderboard` | GET | `{}` | Top players |
| `request_rematch` | POST | `{"match_id": "..."}` | New match |

### WebSocket Events

| OpCode | Direction | Payload | Description |
|--------|-----------|---------|-------------|
| `1` | Client→Server | `{"position": 5}` | Player move |
| `2` | Server→Client | Game state | State update |
| `3` | Server→Client | Result | Game end |

### Configuration

```dart
// Frontend Configuration
class AppConfig {
  static const String nakamaHost = 'localhost';
  static const int nakamaPort = 7350;
  static const String nakamaServerKey = 'defaultkey';
  static const bool useSsl = false;
}
```

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/new-feature`
3. **Make changes** and test thoroughly
4. **Run tests**: `flutter test && go test ./...`
5. **Commit changes**: `git commit -m "Add new feature"`
6. **Push to branch**: `git push origin feature/new-feature`
7. **Create Pull Request**

### Code Standards

- **Flutter**: Follow [Flutter style guide](https://flutter.dev/docs/development/tools/formatting)
- **Go**: Follow [Go formatting](https://golang.org/doc/effective_go.html)
- **Git**: Use conventional commits
- **Testing**: Maintain >80% test coverage

### Project Structure

```text
tic-tac-toe/
├── backend/                 # Go/Nakama backend
│   ├── db/                 # Database initialization
│   ├── match/              # Game logic
│   ├── rpc/                # API endpoints
│   ├── utils/              # Utilities
│   ├── main.go             # Entry point
│   ├── Makefile            # Build scripts
│   └── docker-compose.yml  # Services
├── frontend/               # Flutter app
│   ├── lib/
│   │   ├── bloc/          # State management
│   │   ├── config/        # Configuration
│   │   ├── models/        # Data models
│   │   ├── screens/       # UI screens
│   │   ├── services/      # API services
│   │   └── widgets/       # UI components
│   ├── android/           # Android config
│   ├── ios/               # iOS config
│   └── pubspec.yaml       # Dependencies
└── README.md              # This file
```

## 🙏 Acknowledgments

- [Nakama](https://heroiclabs.com/) - Real-time game server
- [Flutter](https://flutter.dev/) - Cross-platform framework
- [Heroic Labs](https://heroiclabs.com/) - Nakama documentation and support

---

**Ready to play?** Follow the Quick Start guide and you'll have a fully functional multiplayer tic-tac-toe game running in minutes! 🎮✨

For questions or issues, please check the [Troubleshooting](#-troubleshooting) section or create an issue in the repository.
