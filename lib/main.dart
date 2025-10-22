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

  @override
  void initState() {
    super.initState();
    _loadData();
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Bags'),
          BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Place Bin'),
          BottomNavigationBarItem(icon: Icon(Icons.save), label: 'Saved QR'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zepto QR'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
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
                            ElevatedButton.icon(
                              onPressed: () => widget.onSave(_qrData),
                              icon: const Icon(Icons.save),
                              label: const Text('Save QR'),
                            ),
                          ],
                        ),
                      )
                    : const Text(
                        'Enter text below to generate QR code',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
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