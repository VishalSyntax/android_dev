import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'bags_page_complete.dart';
import 'place_bin.dart';
import 'saved_qr.dart';
import 'settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zepto QR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  List<String> savedQRs = [];
  Map<String, String> qrTitles = {};
  Map<String, String> placeBinQRs = {};
  Map<String, String> bagQRs = {};
  Map<String, List<String>> qrFolders = {'Default': []};
  List<String> folderOrder = ['Saved QRs', 'Default'];
  bool _isTrialExpired = false;
  bool _isActivated = false;

  @override
  void initState() {
    super.initState();
    _checkTrialStatus();
    _loadData();
  }
  
  Future<void> _checkTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if app is already activated
    _isActivated = prefs.getBool('isActivated') ?? false;
    if (_isActivated) {
      setState(() {
        _isTrialExpired = false;
      });
      return;
    }
    
    // Get installation date
    String? installDateStr = prefs.getString('installDate');
    DateTime installDate;
    
    if (installDateStr == null) {
      // First time installation
      installDate = DateTime.now();
      await prefs.setString('installDate', installDate.toIso8601String());
    } else {
      installDate = DateTime.parse(installDateStr);
    }
    
    // Check if trial period (40 hours) has expired
    DateTime now = DateTime.now();
    int hoursDifference = now.difference(installDate).inHours;
    
    setState(() {
      _isTrialExpired = hoursDifference >= 40;
    });
    
    if (_isTrialExpired) {
      _showActivationDialog();
    }
  }
  
  void _showActivationDialog() {
    final TextEditingController keyController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Trial Expired'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your 40-hour trial has expired. Please enter activation key to continue.'),
            const SizedBox(height: 10),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Activation Key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _validateActivationKey(keyController.text),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _validateActivationKey(String key) async {
    if (key.length < 4) {
      _showError('Invalid activation key');
      return;
    }
    
    // Extract last 4 digits
    String timeCode = key.substring(key.length - 4);
    
    // Get current time in HHMM format (24-hour)
    DateTime now = DateTime.now();
    String currentTime = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    
    // Check if key starts with 'vishal0x' and time matches
    if (key.startsWith('vishal0x') && timeCode == currentTime) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isActivated', true);
      
      setState(() {
        _isActivated = true;
        _isTrialExpired = false;
      });
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App activated successfully!')),
      );
    } else {
      _showError('Invalid activation key contact the app developer');
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  
  void _showManualActivationDialog() {
    if (_isActivated) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Activation Status'),
          content: const Text('You are already activated!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    final TextEditingController keyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Activation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter activation key:'),
            const SizedBox(height: 10),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Activation Key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _validateActivationKey(keyController.text);
            },
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        savedQRs = prefs.getStringList('savedQRs') ?? [];
        
        String titleData = prefs.getString('qrTitles') ?? '{}';
        qrTitles = Map<String, String>.from(json.decode(titleData));
        
        String placeBinData = prefs.getString('placeBinQRs') ?? '{}';
        placeBinQRs = Map<String, String>.from(json.decode(placeBinData));
        
        String bagData = prefs.getString('bagQRs') ?? '{}';
        bagQRs = Map<String, String>.from(json.decode(bagData));
        
        String folderData = prefs.getString('qrFolders') ?? '{"Default":[]}';
        Map<String, dynamic> decodedFolders = json.decode(folderData);
        qrFolders = decodedFolders.map((key, value) => MapEntry(key, List<String>.from(value)));
        
        String orderData = prefs.getString('folderOrder') ?? '["Saved QRs","Default"]';
        folderOrder = List<String>.from(json.decode(orderData));
      });
    } catch (e) {
      setState(() {
        savedQRs = [];
        qrTitles = {};
        placeBinQRs = {};
        bagQRs = {};
        qrFolders = {'Default': []};
        folderOrder = ['Saved QRs', 'Default'];
      });
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('savedQRs', savedQRs);
      await prefs.setString('qrTitles', json.encode(qrTitles));
      await prefs.setString('placeBinQRs', json.encode(placeBinQRs));
      await prefs.setString('bagQRs', json.encode(bagQRs));
      await prefs.setString('qrFolders', json.encode(qrFolders));
      await prefs.setString('folderOrder', json.encode(folderOrder));
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  void _saveQR(String qrData) {
    if (qrData.isNotEmpty && !savedQRs.contains(qrData)) {
      setState(() {
        savedQRs.add(qrData);
      });
      _saveData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code saved!')),
      );
    }
  }

  void _deleteQR(int index) {
    setState(() {
      String qrData = savedQRs.removeAt(index);
      qrTitles.remove(qrData);
    });
    _saveData();
  }

  void _deleteQRFromFolder(String qrData, String folderName) {
    setState(() {
      if (folderName == 'Saved QRs') {
        savedQRs.remove(qrData);
      } else {
        qrFolders[folderName]?.remove(qrData);
      }
      qrTitles.remove(qrData);
    });
    _saveData();
  }

  void _updateQR(String oldQR, String newQR, String title) {
    setState(() {
      int index = savedQRs.indexOf(oldQR);
      if (index != -1) {
        savedQRs[index] = newQR;
        qrTitles.remove(oldQR);
      }
      if (title.isNotEmpty) {
        qrTitles[newQR] = title;
      }
    });
    _saveData();
  }

  void _updateQRInFolder(String oldQR, String newQR, String title, String folderName) {
    setState(() {
      if (folderName == 'Saved QRs') {
        int index = savedQRs.indexOf(oldQR);
        if (index != -1) {
          savedQRs[index] = newQR;
        }
      } else {
        List<String>? folderQRs = qrFolders[folderName];
        if (folderQRs != null) {
          int index = folderQRs.indexOf(oldQR);
          if (index != -1) {
            folderQRs[index] = newQR;
          }
        }
      }
      qrTitles.remove(oldQR);
      if (title.isNotEmpty) {
        qrTitles[newQR] = title;
      }
    });
    _saveData();
  }

  void _createFolder(String folderName) {
    if (folderName.isNotEmpty && !qrFolders.containsKey(folderName)) {
      setState(() {
        qrFolders[folderName] = [];
        folderOrder.add(folderName);
      });
      _saveData();
    }
  }

  void _deleteFolder(String folderName) {
    if (folderName != 'Default') {
      setState(() {
        qrFolders.remove(folderName);
        folderOrder.remove(folderName);
      });
      _saveData();
    }
  }

  void _renameFolder(String oldName, String newName) {
    if (oldName != 'Default' && newName.isNotEmpty && !qrFolders.containsKey(newName)) {
      setState(() {
        List<String> qrs = qrFolders[oldName] ?? [];
        qrFolders.remove(oldName);
        qrFolders[newName] = qrs;
        int index = folderOrder.indexOf(oldName);
        if (index != -1) {
          folderOrder[index] = newName;
        }
      });
      _saveData();
    }
  }

  void _reorderFolders(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = folderOrder.removeAt(oldIndex);
      folderOrder.insert(newIndex, item);
    });
    _saveData();
  }

  void _moveQRToFolder(String qrData, String folderName) {
    setState(() {
      if (savedQRs.contains(qrData)) {
        savedQRs.remove(qrData);
      }
      if (!qrFolders[folderName]!.contains(qrData)) {
        qrFolders[folderName]!.add(qrData);
      }
    });
    _saveData();
  }

  void _exportData() async {
    try {
      Map<String, dynamic> allData = {
        'savedQRs': savedQRs,
        'qrTitles': qrTitles,
        'placeBinQRs': placeBinQRs,
        'bagQRs': bagQRs,
        'qrFolders': qrFolders,
        'folderOrder': folderOrder,
        'exportDate': DateTime.now().toIso8601String(),
      };
      
      String jsonData = json.encode(allData);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Data'),
          content: SingleChildScrollView(
            child: SelectableText(
              jsonData,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported! Copy from dialog.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  void _importData() {
    final TextEditingController importController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste your exported data below:'),
            const SizedBox(height: 10),
            TextField(
              controller: importController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste JSON data here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Map<String, dynamic> importedData = json.decode(importController.text);
                
                setState(() {
                  if (importedData['savedQRs'] != null) {
                    savedQRs = List<String>.from(importedData['savedQRs']);
                  }
                  if (importedData['qrTitles'] != null) {
                    qrTitles = Map<String, String>.from(importedData['qrTitles']);
                  }
                  if (importedData['placeBinQRs'] != null) {
                    placeBinQRs = Map<String, String>.from(importedData['placeBinQRs']);
                  }
                  if (importedData['bagQRs'] != null) {
                    bagQRs = Map<String, String>.from(importedData['bagQRs']);
                  }
                  if (importedData['qrFolders'] != null) {
                    Map<String, dynamic> importedFolders = importedData['qrFolders'];
                    qrFolders = importedFolders.map((key, value) => MapEntry(key, List<String>.from(value)));
                  }
                  if (importedData['folderOrder'] != null) {
                    folderOrder = List<String>.from(importedData['folderOrder']);
                  }
                });
                
                await _saveData();
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data imported successfully!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Import failed: Invalid data format')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isTrialExpired && !_isActivated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trial Expired'),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 100, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'Your trial period has expired',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Please activate the app to continue',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          QRGeneratorPage(onSave: _saveQR),
          BagsPage(qrCodes: bagQRs),
          PlaceBinPage(qrCodes: placeBinQRs),
          SavedQRPage(
            savedQRs: savedQRs,
            qrTitles: qrTitles,
            qrFolders: qrFolders,
            folderOrder: folderOrder,
            onDelete: _deleteQR,
            onDeleteFromFolder: _deleteQRFromFolder,
            onUpdate: _updateQR,
            onUpdateInFolder: _updateQRInFolder,
            onCreateFolder: _createFolder,
            onDeleteFolder: _deleteFolder,
            onRenameFolder: _renameFolder,
            onReorderFolders: _reorderFolders,
            onMoveToFolder: _moveQRToFolder,
          ),
          SettingsPage(
            placeBinQRs: placeBinQRs,
            bagQRs: bagQRs,
            onPlaceBinUpdate: (qrs) async {
              setState(() => placeBinQRs = qrs);
              await _saveData();
            },
            onBagUpdate: (qrs) async {
              setState(() => bagQRs = qrs);
              await _saveData();
            },
            onExportData: _exportData,
            onImportData: _importData,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Bags'),
          const BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Place Bin'),
          const BottomNavigationBarItem(icon: Icon(Icons.save), label: 'Saved QR'),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onLongPress: _showManualActivationDialog,
              child: const Icon(Icons.settings),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// QR Generator Page
class QRGeneratorPage extends StatefulWidget {
  final Function(String) onSave;
  const QRGeneratorPage({super.key, required this.onSave});

  @override
  State<QRGeneratorPage> createState() => _QRGeneratorPageState();
}

class _QRGeneratorPageState extends State<QRGeneratorPage> {
  final TextEditingController _textController = TextEditingController();
  String _qrData = '';
  bool _showSpeedometer = false;
  String _selectedAlpha1 = 'A';
  int _selectedDigit1 = 1;
  String _selectedAlpha2 = 'A';
  int _selectedDigit2 = 1;
  
  final List<String> _alpha1Options = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
  final List<int> _digit1Options = List.generate(28, (i) => i + 1);
  final List<String> _alpha2Options = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];
  final List<int> _digit2Options = List.generate(7, (i) => i + 1);
  
  @override
  void initState() {
    super.initState();
    _loadSpeedometerState();
  }
  
  Future<void> _loadSpeedometerState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showSpeedometer = prefs.getBool('showSpeedometer') ?? false;
      _selectedAlpha1 = prefs.getString('selectedAlpha1') ?? 'A';
      _selectedDigit1 = prefs.getInt('selectedDigit1') ?? 1;
      _selectedAlpha2 = prefs.getString('selectedAlpha2') ?? 'A';
      _selectedDigit2 = prefs.getInt('selectedDigit2') ?? 1;
    });
    if (_showSpeedometer) _generateSpeedometerQR();
  }
  
  Future<void> _saveSpeedometerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showSpeedometer', _showSpeedometer);
    await prefs.setString('selectedAlpha1', _selectedAlpha1);
    await prefs.setInt('selectedDigit1', _selectedDigit1);
    await prefs.setString('selectedAlpha2', _selectedAlpha2);
    await prefs.setInt('selectedDigit2', _selectedDigit2);
  }
  
  void _generateSpeedometerQR() {
    setState(() {
      _qrData = 'RVT-$_selectedAlpha1-$_selectedDigit1-$_selectedAlpha2-$_selectedDigit2';
    });
  }

  void _generateQR() {
    setState(() {
      _qrData = _textController.text.trim();
    });
  }

  void _clearText() {
    setState(() {
      _textController.clear();
      _qrData = '';
    });
  }
  
  Widget _buildSpeedometer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quick RVT Generator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showSpeedometer = false;
                  });
                  _saveSpeedometerState();
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text('RVT-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildWheelSelector(_selectedAlpha1, _alpha1Options, (value) {
                setState(() {
                  _selectedAlpha1 = value;
                  _generateSpeedometerQR();
                });
                _saveSpeedometerState();
              }),
              const Text('-', style: TextStyle(fontSize: 18)),
              _buildWheelSelector(_selectedDigit1.toString(), _digit1Options.map((e) => e.toString()).toList(), (value) {
                setState(() {
                  _selectedDigit1 = int.parse(value);
                  _generateSpeedometerQR();
                });
                _saveSpeedometerState();
              }),
              const Text('-', style: TextStyle(fontSize: 18)),
              _buildWheelSelector(_selectedAlpha2, _alpha2Options, (value) {
                setState(() {
                  _selectedAlpha2 = value;
                  _generateSpeedometerQR();
                });
                _saveSpeedometerState();
              }),
              const Text('-', style: TextStyle(fontSize: 18)),
              _buildWheelSelector(_selectedDigit2.toString(), _digit2Options.map((e) => e.toString()).toList(), (value) {
                setState(() {
                  _selectedDigit2 = int.parse(value);
                  _generateSpeedometerQR();
                });
                _saveSpeedometerState();
              }),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildWheelSelector(String currentValue, List<String> options, Function(String) onChanged) {
    int currentIndex = options.indexOf(currentValue);
    FixedExtentScrollController controller = FixedExtentScrollController(initialItem: currentIndex);
    
    return Container(
      width: 50,
      height: 120,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 40,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (index) {
          onChanged(options[index]);
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: options.length,
          builder: (context, index) {
            return Container(
              alignment: Alignment.center,
              child: Text(
                options[index],
                style: TextStyle(
                  fontSize: currentIndex == index ? 18 : 14,
                  fontWeight: currentIndex == index ? FontWeight.bold : FontWeight.normal,
                  color: currentIndex == index ? Colors.blue : Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zepto QR'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showSpeedometer = !_showSpeedometer;
                if (_showSpeedometer) _generateSpeedometerQR();
              });
              _saveSpeedometerState();
            },
            icon: Icon(_showSpeedometer ? Icons.keyboard : Icons.speed),
            tooltip: _showSpeedometer ? 'Text Input' : 'RVT Generator',
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < -500) {
            setState(() {
              _showSpeedometer = true;
              _generateSpeedometerQR();
            });
            _saveSpeedometerState();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
            Expanded(
              flex: 2,
              child: Center(
                child: _qrData.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrImageView(
                              data: _qrData,
                              version: QrVersions.auto,
                              size: 200.0,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _qrData,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () => widget.onSave(_qrData),
                              icon: const Icon(Icons.save),
                              label: const Text('Save QR'),
                            ),
                          ],
                        ),
                      )
                    : const Text(
                        'Enter text below to generate QR code\n\nSwipe left for quick RVT generator',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
            ),
            const SizedBox(height: 20),
            if (!_showSpeedometer) ...[
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Enter text to generate QR code',
                  border: OutlineInputBorder(),
                  hintText: 'Type your text here...',
                ),
                maxLines: 3,
                onChanged: (value) => _generateQR(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _generateQR,
                      child: const Text('Generate QR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _clearText,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
            if (_showSpeedometer) _buildSpeedometer(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}