# Bluetooth PDF Printer

A Flutter application for printing PDF invoices through Bluetooth thermal printers.

## Features

- **PDF File Selection**: Pick PDF files from device storage
- **PDF Preview**: View selected PDF files before printing
- **Bluetooth Connectivity**: Discover and connect to paired Bluetooth printers
- **Thermal Printing**: Print PDFs using ESC/POS commands for thermal printers
- **Permission Management**: Handles file access and Bluetooth permissions

## How to Use

1. **Select PDF Invoice**: Tap "Select PDF Invoice" to choose a PDF file from your device
2. **Preview**: The selected PDF will be displayed in the preview area
3. **Connect to Printer**: Select a paired Bluetooth printer from the list
4. **Print**: Tap "Print PDF" to send the document to the connected printer

## Requirements

- Android 6.0+ (API level 23)
- iOS 12.0+
- Bluetooth-enabled thermal printer with ESC/POS support
- Storage permissions for file access
- Bluetooth permissions for printer connectivity

## Permissions

### Android
- Bluetooth and Bluetooth Admin
- Location (required for Bluetooth scanning)
- External Storage (read/write)

### iOS
- Bluetooth usage
- Document access

## Supported Printers

This app works with ESC/POS compatible thermal printers that support Bluetooth connectivity.

## Getting Started

This project is a Flutter application for Bluetooth PDF printing.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Dependencies

- `file_picker`: PDF file selection
- `flutter_pdfview`: PDF viewing
- `native_pdf_renderer`: PDF processing
- `flutter_bluetooth_serial`: Bluetooth connectivity
- `esc_pos_bluetooth`: Bluetooth thermal printing
- `permission_handler`: Runtime permissions
