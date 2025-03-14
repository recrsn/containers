# Containers

![Containers logo](assets/icon_64.png)
A native macOS application for managing containers across multiple runtimes.

## Supported Runtimes

- Docker Desktop
- Podman
- Colima
- Remote Docker hosts

## Features

- Native SwiftUI interface designed for macOS
- Connect to multiple container runtimes simultaneously
- Monitor container status, logs, and resource usage
- Start, stop, and manage containers
- View container details and configuration
- Support for both local and remote container hosts

## Development

Containers is built with Swift and SwiftUI

### Requirements

- macOS 15.0 or later
- Xcode 16.0 or later
- One or more container runtimes (Docker, Podman, Colima, etc.)

### Building

```bash
xcodebuild -project Containers.xcodeproj -scheme Containers build
```

### Running Tests

```bash
xcodebuild -project Containers.xcodeproj -scheme Containers test
```

## License

MIT License
