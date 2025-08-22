import 'package:flutter/material.dart';
import 'package:printer/bluetooth_pdf_service.dart';
import 'dart:io';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth PDF Printer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Bluetooth PDF Printer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  File? _selectedPdfFile;
  PdfDocument? _pdfDocument;
  bool _isLoading = false;
  bool _isConnected = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePermissionsAndBluetooth();
  }

  Future<void> _initializePermissionsAndBluetooth() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Requesting permissions...';
    });

    try {
      bool permissionsGranted = await BluetoothPdfService.requestPermissions();
      if (permissionsGranted) {
        await _getPairedDevices();
      } else {
        setState(() {
          _statusMessage = 'Some permissions not granted. The app may not work fully. Please check app settings.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing app: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getPairedDevices() async {
    setState(() {
      _statusMessage = 'Getting paired devices...';
    });

    try {
      _devices = await BluetoothPdfService.getPairedDevices();
      setState(() {
        _statusMessage = _devices.isEmpty 
          ? 'No paired Bluetooth devices found'
          : '${_devices.length} paired devices found';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error getting devices: $e';
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to ${device.name}...';
    });

    bool connected = await BluetoothPdfService.connectToDevice(device);
    setState(() {
      _isLoading = false;
      _selectedDevice = connected ? device : null;
      _isConnected = connected;
      _statusMessage = connected 
        ? 'Connected to ${device.name}'
        : 'Failed to connect to ${device.name}';
    });
  }

  Future<void> _pickPdfFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Selecting PDF file...';
    });

    try {
      File? file = await BluetoothPdfService.pickPdfFile();
      if (file != null) {
        _selectedPdfFile = file;
        _pdfDocument = await BluetoothPdfService.loadPdfDocument(file);
        setState(() {
          _statusMessage = 'PDF loaded: ${file.path.split('/').last}';
        });
      } else {
        setState(() {
          _statusMessage = 'No file selected';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading PDF: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _printPdf() async {
    if (!_isConnected || _selectedPdfFile == null) {
      setState(() {
        _statusMessage = 'Please select a PDF and connect to a printer first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Printing PDF...';
    });

    bool success = await BluetoothPdfService.printPdf();
    setState(() {
      _isLoading = false;
      _statusMessage = success ? 'PDF printed successfully!' : 'Failed to print PDF';
    });
  }

  @override
  void dispose() {
    BluetoothPdfService.cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status message
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: _isConnected ? Colors.green : Colors.black87,
                  fontWeight: _isConnected ? FontWeight.w500 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Bluetooth devices section
            Text('Bluetooth Printers', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: _devices.isEmpty
                  ? const Center(child: Text('No paired devices'))
                  : ListView.builder(
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final isSelected = _selectedDevice?.address == device.address;
                        return ListTile(
                          title: Text(device.name ?? 'Unknown Device'),
                          subtitle: Text(device.address),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                          tileColor: isSelected ? Colors.green[50] : null,
                          onTap: () => _connectToDevice(device),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // PDF file section
            Text('PDF File', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickPdfFile,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Select PDF Invoice'),
            ),
            
            if (_selectedPdfFile != null) ...[
              const SizedBox(height: 10),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: _pdfDocument != null
                  ? PDFView(
                      filePath: _selectedPdfFile!.path,
                      autoSpacing: false,
                      swipeHorizontal: true,
                      pageSnap: false,
                      pageFling: false,
                      onError: (error) {
                        print('PDF View Error: $error');
                      },
                      onPageError: (page, error) {
                        print('PDF Page Error: $page: $error');
                      },
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('PDF Preview', style: TextStyle(color: Colors.grey)),
                          Text('(File loaded and ready for printing)', 
                               style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'File: ${_selectedPdfFile!.path.split('/').last}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (_pdfDocument != null)
                Text(
                  'Pages: ${_pdfDocument!.pagesCount}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],

            const Spacer(),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _getPairedDevices,
                    child: const Text('Refresh Devices'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_isConnected && _selectedPdfFile != null && !_isLoading) 
                        ? _printPdf 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Print PDF'),
                  ),
                ),
              ],
            ),

            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
