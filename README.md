# QR Code Generator

A Flutter app that generates QR codes from text input, similar to Google Chrome's QR code generator.

## Features

- Enter any text to generate a QR code
- Real-time QR code generation as you type
- Clean, modern UI with Material Design 3
- Clear button to reset input and QR code

## How to Run

### Prerequisites
- Flutter SDK installed
- Android Studio/VS Code with Flutter extensions

### Running the App

1. **Using VS Code Tasks:**
   - Press `Ctrl+Shift+P` and select "Tasks: Run Task"
   - Choose "Flutter Run" for mobile/desktop
   - Choose "Flutter Run Web" for web browser

2. **Using Terminal:**
   ```bash
   flutter run
   ```

3. **For Web:**
   ```bash
   flutter run -d web-server
   ```

## Usage

1. Open the app
2. Type any text in the input field
3. QR code generates automatically as you type
4. Use the "Generate QR" button to manually refresh
5. Use "Clear" to reset everything

## Dependencies

- `qr_flutter: ^4.1.0` - QR code generation widget