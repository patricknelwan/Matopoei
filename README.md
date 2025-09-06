# Matopoei

A beautiful comic book reader for iPhone and iPad, offering an immersive reading experience with smart layout switching.

## Features

### 📚 Smart Reading Modes
- **iPhone**: Optimized single page view for comfortable mobile reading
- **iPad Portrait**: Single page view for detailed panel reading
- **iPad Landscape**: Double page spread view, just like opening a real comic book
- **Automatic Layout**: Seamlessly adapts to your device and orientation

### 🎨 Immersive Experience
- **Unified Zoom**: Smooth zooming across entire double-page spreads (iPad)
- **Tap Navigation**: Tap left/right edges to turn pages, center to toggle controls
- **Auto-Hide Controls**: Distraction-free reading with auto-hiding interface
- **Full-Screen Reading**: Immersive edge-to-edge comic display

### 📖 Reading Features
- **Reading Progress**: Automatically saves where you left off
- **Page Counter**: Track your progress through each comic
- **Zoom & Pan**: Pinch to zoom and examine comic details
- **Go to Page**: Jump to any specific page instantly

### 📁 File Management
- **CBZ Support**: Full support for CBZ (Comic Book ZIP) files
- **Easy Import**: Import comics directly from Files app or other sources
- **Automatic Organization**: Comics are automatically organized in your library

## Supported Formats

- ✅ **CBZ** (Comic Book ZIP)
- 🔜 **CBR** (Comic Book RAR) - Coming Soon

## Requirements

- iPhone running iOS 13.0 or later
- iPad running iOS 13.0 or later
- Xcode 12.0+ (for development)

## Installation

1. Clone the repository: `git clone https://github.com/patricknelwan/matopoei.git`
   
2. Open `Matopoei.xcodeproj` in Xcode

3. Build and run the project on your iPhone or iPad

## Usage

1. **Import Comics**: Tap the "+" button to import CBZ files
2. **Browse Library**: Your imported comics appear in a clean grid layout
3. **Start Reading**: Tap any comic to open the full-screen reader
4. **Navigate Pages**: 
   - Tap left/right edges to turn pages
   - Tap center to show/hide controls
   - Pinch to zoom and pan around pages
5. **Reading Progress**: Your progress is automatically saved

## Device-Specific Features

### iPhone
- Single page optimized layout for mobile reading
- Vertical scrolling support for long panels
- Portrait orientation focus

### iPad
- Single page in portrait mode for detailed reading
- Double page spread in landscape mode for authentic comic book experience
- Enhanced zoom and pan capabilities for large screen

## Architecture

The app follows a clean MVVM architecture with these key components:

- **Models**: `ComicBook`, `ComicStorage` for data management
- **Views**: Custom table cells and UI components
- **Controllers**: File browser, comic reader, and navigation logic
- **Utilities**: Archive processing and file management

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- Designed for both iPhone and iPad reading experiences
- Optimized for the best comic reading experience on iOS
