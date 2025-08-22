import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'package:image/image.dart' as img;
import 'dart:ui' as ui;

class BluetoothPdfService {
  static BluetoothConnection? _connection;
  static List<BluetoothDevice> _devices = [];
  static BluetoothDevice? _selectedDevice;
  static File? _selectedPdfFile;
  static PdfDocument? _pdfDocument;

  // Request necessary permissions
  static Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    
    return statuses.values.every((status) => status == PermissionStatus.granted);
  }

  // Get list of paired Bluetooth devices
  static Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      _devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return _devices;
    } catch (e) {
      log('Error getting paired devices: $e');
      return [];
    }
  }

  // Connect to selected Bluetooth device
  static Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _selectedDevice = device;
      _connection = await BluetoothConnection.toAddress(device.address);
      log('Connected to ${device.name}');
      return true;
    } catch (e) {
      log('Error connecting to device: $e');
      return false;
    }
  }

  // Disconnect from Bluetooth device
  static Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection = null;
      _selectedDevice = null;
      log('Disconnected from Bluetooth device');
    } catch (e) {
      log('Error disconnecting: $e');
    }
  }

  // Pick PDF file from device
  static Future<File?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        _selectedPdfFile = File(result.files.single.path!);
        return _selectedPdfFile;
      }
      return null;
    } catch (e) {
      log('Error picking PDF file: $e');
      return null;
    }
  }

  // Load and parse PDF document
  static Future<PdfDocument?> loadPdfDocument(File pdfFile) async {
    try {
      _pdfDocument = await PdfDocument.openFile(pdfFile.path);
      return _pdfDocument;
    } catch (e) {
      log('Error loading PDF document: $e');
      return null;
    }
  }

  // Convert PDF page to image
  static Future<Uint8List?> convertPdfPageToImage(PdfDocument document, int pageIndex) async {
    try {
      final page = await document.getPage(pageIndex + 1);
      final pageImage = await page.render(width: 576, height: 800); // 576px = 72mm at 203dpi
      await page.close();
      return pageImage.bytes;
    } catch (e) {
      log('Error converting PDF page to image: $e');
      return null;
    }
  }

  // Print PDF via Bluetooth
  static Future<bool> printPdf() async {
    if (_connection == null || _pdfDocument == null) {
      log('No Bluetooth connection or PDF document');
      return false;
    }

    try {
      // Create printer instance for Bluetooth
      const PaperSize paper = PaperSize.mm80;
      final profile = await CapabilityProfile.load();
      final printer = PrinterBluetooth(_connection!, paper, profile);

      // Get PDF page count
      final pageCount = _pdfDocument!.pagesCount;
      
      for (int i = 0; i < pageCount; i++) {
        // Convert each page to image
        final pageImageBytes = await convertPdfPageToImage(_pdfDocument!, i);
        if (pageImageBytes != null) {
          // Convert to format suitable for ESC/POS printing
          final image = img.decodeImage(pageImageBytes);
          if (image != null) {
            // Print the image
            printer.imageRaster(image);
            printer.feed(1);
          }
        }
      }

      // Cut the paper and finish
      printer.cut();
      
      log('PDF printed successfully');
      return true;
    } catch (e) {
      log('Error printing PDF: $e');
      return false;
    }
  }

  // Get current selected device
  static BluetoothDevice? get selectedDevice => _selectedDevice;

  // Get current selected PDF file
  static File? get selectedPdfFile => _selectedPdfFile;

  // Get current PDF document
  static PdfDocument? get pdfDocument => _pdfDocument;

  // Check if connected
  static bool get isConnected => _connection != null && _connection!.isConnected;

  // Cleanup resources
  static Future<void> cleanup() async {
    try {
      await _pdfDocument?.close();
      await disconnect();
      _selectedPdfFile = null;
      _pdfDocument = null;
    } catch (e) {
      log('Error during cleanup: $e');
    }
  }
}

// Custom Bluetooth printer class extending from esc_pos_bluetooth
class PrinterBluetooth {
  final BluetoothConnection _connection;
  final PaperSize _paperSize;
  final CapabilityProfile _profile;

  PrinterBluetooth(this._connection, this._paperSize, this._profile);

  void imageRaster(img.Image image) {
    // Convert image to ESC/POS raster format and send via Bluetooth
    final resized = img.copyResize(image, width: 576); // Resize to printer width
    final bytes = _imageToRasterBytes(resized);
    _connection.output.add(bytes);
  }

  void feed(int lines) {
    final List<int> bytes = [];
    for (int i = 0; i < lines; i++) {
      bytes.addAll([0x0A]); // Line feed command
    }
    _connection.output.add(Uint8List.fromList(bytes));
  }

  void cut() {
    final List<int> cutCommand = [0x1D, 0x56, 0x42, 0x00]; // Full cut command
    _connection.output.add(Uint8List.fromList(cutCommand));
  }

  // Convert image to ESC/POS raster bytes
  Uint8List _imageToRasterBytes(img.Image image) {
    final int width = image.width;
    final int height = image.height;
    
    // Convert to monochrome and create raster data
    List<int> bytes = [];
    
    // Add raster graphics command
    bytes.addAll([0x1D, 0x76, 0x30, 0x00]); // GS v 0
    bytes.addAll(_intToBytes(width ~/ 8, 2)); // Width in bytes
    bytes.addAll(_intToBytes(height, 2)); // Height
    
    // Convert image to monochrome bitmap
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x += 8) {
        int byte = 0;
        for (int bit = 0; bit < 8; bit++) {
          if (x + bit < width) {
            final pixel = image.getPixel(x + bit, y);
            final red = img.getRed(pixel);
            final green = img.getGreen(pixel);
            final blue = img.getBlue(pixel);
            final gray = (red + green + blue) / 3;
            if (gray < 128) { // Black pixel
              byte |= (1 << (7 - bit));
            }
          }
        }
        bytes.add(byte);
      }
    }
    
    return Uint8List.fromList(bytes);
  }

  // Convert integer to byte array
  List<int> _intToBytes(int value, int length) {
    List<int> bytes = [];
    for (int i = 0; i < length; i++) {
      bytes.add((value >> (i * 8)) & 0xFF);
    }
    return bytes;
  }
}