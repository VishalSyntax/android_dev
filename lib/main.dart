import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

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
  Map<String, String> placeBinQRs = {};
  Map<String, String> bagQRs = {};
  Map<String, List<String>> qrFolders = {'Default': []};

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
        
        String placeBinData = prefs.getString('placeBinQRs') ?? '{}';
        placeBinQRs = Map<String, String>.from(json.decode(placeBinData));
        
        String bagData = prefs.getString('bagQRs') ?? '{}';
        bagQRs = Map<String, String>.from(json.decode(bagData));
        
        String folderData = prefs.getString('qrFolders') ?? '{"Default":[]}';
        Map<String, dynamic> decodedFolders = json.decode(folderData);
        qrFolders = decodedFolders.map((key, value) => MapEntry(key, List<String>.from(value)));
      });
      
      print('Data loaded - SavedQRs: ${savedQRs.length}, PlaceBin: ${placeBinQRs.length}, Bags: ${bagQRs.length}, Folders: ${qrFolders.length}');
    } catch (e) {
      print('Error loading data: $e');
      // If data is corrupted, reset to empty
      setState(() {
        savedQRs = [];
        placeBinQRs = {};
        bagQRs = {};
        qrFolders = {'Default': []};
      });
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('savedQRs', savedQRs);
      await prefs.setString('placeBinQRs', json.encode(placeBinQRs));
      await prefs.setString('bagQRs', json.encode(bagQRs));
      await prefs.setString('qrFolders', json.encode(qrFolders));
      
      print('Data saved - SavedQRs: ${savedQRs.length}, PlaceBin: ${placeBinQRs.length}, Bags: ${bagQRs.length}, Folders: ${qrFolders.length}');
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
      savedQRs.removeAt(index);
    });
    _saveData();
  }

  void _createFolder(String folderName) {
    if (folderName.isNotEmpty && !qrFolders.containsKey(folderName)) {
      setState(() {
        qrFolders[folderName] = [];
      });
      _saveData();
    }
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
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> allData = {
        'savedQRs': savedQRs,
        'placeBinQRs': placeBinQRs,
        'bagQRs': bagQRs,
        'exportDate': DateTime.now().toIso8601String(),
      };
      
      String jsonData = json.encode(allData);
      
      // For now, show the data in a dialog for manual copy
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
                  if (importedData['placeBinQRs'] != null) {
                    placeBinQRs = Map<String, String>.from(importedData['placeBinQRs']);
                  }
                  if (importedData['bagQRs'] != null) {
                    bagQRs = Map<String, String>.from(importedData['bagQRs']);
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
            qrFolders: qrFolders,
            onDelete: _deleteQR,
            onCreateFolder: _createFolder,
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

class PlaceBinPage extends StatefulWidget {
  final Map<String, String> qrCodes;
  const PlaceBinPage({super.key, required this.qrCodes});

  @override
  State<PlaceBinPage> createState() => _PlaceBinPageState();
}

class _PlaceBinPageState extends State<PlaceBinPage> {
  int _selectedColorIndex = 0;
  int _selectedBoxNumber = 1;
  
  final List<String> _colors = ['White', 'Yellow', 'Blue', 'Green', 'Red'];
  final List<Color> _colorValues = [Colors.grey[300]!, Colors.yellow, Colors.blue[800]!, Colors.green[800]!, Colors.red];
  
  String _getCurrentQRData() {
    String colorKey = '${_colors[_selectedColorIndex]}_$_selectedBoxNumber';
    return widget.qrCodes[colorKey] ?? 'No QR defined for ${_colors[_selectedColorIndex]} Bin $_selectedBoxNumber';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Bin'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // QR Display Area
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
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
                      data: _getCurrentQRData(),
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_colors[_selectedColorIndex]} Bin $_selectedBoxNumber',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Controls Area
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Color Selection (Horizontal Scroll)
                const Text('Select Color:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColorIndex = index;
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _colorValues[index],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedColorIndex == index ? Colors.black : Colors.grey,
                              width: _selectedColorIndex == index ? 3 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _colors[index][0],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: index == 0 ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Bin Number Selection (Horizontal Scroll)
                const Text('Select Bin Number:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      int boxNumber = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBoxNumber = boxNumber;
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _selectedBoxNumber == boxNumber ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedBoxNumber == boxNumber ? Colors.blue : Colors.grey,
                              width: _selectedBoxNumber == boxNumber ? 3 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$boxNumber',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _selectedBoxNumber == boxNumber ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class SavedQRPage extends StatefulWidget {
  final List<String> savedQRs;
  final Map<String, List<String>> qrFolders;
  final Function(int) onDelete;
  final Function(String) onCreateFolder;
  final Function(String, String) onMoveToFolder;
  
  const SavedQRPage({
    super.key, 
    required this.savedQRs, 
    required this.qrFolders,
    required this.onDelete,
    required this.onCreateFolder,
    required this.onMoveToFolder,
  });

  @override
  State<SavedQRPage> createState() => _SavedQRPageState();
}

class _SavedQRPageState extends State<SavedQRPage> {
  String _selectedFolder = 'Saved QRs';
  
  void _showCreateFolderDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                widget.onCreateFolder(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showMoveToFolderDialog(String qrData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.qrFolders.keys.map((folderName) {
            return ListTile(
              title: Text(folderName),
              onTap: () {
                widget.onMoveToFolder(qrData, folderName);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentQRs = _selectedFolder == 'Saved QRs' 
        ? widget.savedQRs 
        : widget.qrFolders[_selectedFolder] ?? [];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedFolder),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _showCreateFolderDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Folder Selection
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFolderTab('Saved QRs'),
                ...widget.qrFolders.keys.map((folder) => _buildFolderTab(folder)),
              ],
            ),
          ),
          
          // QR List
          Expanded(
            child: currentQRs.isEmpty
                ? const Center(child: Text('No QR codes in this folder'))
                : ListView.builder(
                    itemCount: currentQRs.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.qr_code),
                          title: Text(currentQRs[index]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                child: QrImageView(
                                  data: currentQRs[index],
                                  size: 50,
                                ),
                              ),
                              if (_selectedFolder == 'Saved QRs')
                                IconButton(
                                  icon: const Icon(Icons.folder, color: Colors.blue),
                                  onPressed: () => _showMoveToFolderDialog(currentQRs[index]),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => widget.onDelete(index),
                              ),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('QR Code'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    QrImageView(
                                      data: currentQRs[index],
                                      version: QrVersions.auto,
                                      size: 250.0,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      currentQRs[index],
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderTab(String folderName) {
    bool isSelected = _selectedFolder == folderName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFolder = folderName;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          folderName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class BagsPage extends StatefulWidget {
  final Map<String, String> qrCodes;
  const BagsPage({super.key, required this.qrCodes});

  @override
  State<BagsPage> createState() => _BagsPageState();
}

class _BagsPageState extends State<BagsPage> {
  String _selectedBagType = 'Regular Bags';
  int _selectedSizeIndex = 0;
  
  final List<String> _bagTypes = ['Regular Bags', 'Reusable Bags', 'Small Reusable Bags', 'Insulated Bags'];
  
  final Map<String, List<String>> _bagSizes = {
    'Regular Bags': ['VS', 'GS', 'GM', 'GL', 'GXL', 'GXXL'],
    'Reusable Bags': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'],
    'Small Reusable Bags': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'],
    'Insulated Bags': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'],
  };
  
  String _getCurrentQRData() {
    String currentSize = _bagSizes[_selectedBagType]![_selectedSizeIndex];
    String key = '${_selectedBagType}_$currentSize';
    return widget.qrCodes[key] ?? 'No QR defined for $_selectedBagType - $currentSize';
  }
  
  String _getCurrentSizeLabel() {
    return _bagSizes[_selectedBagType]![_selectedSizeIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bags'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // QR Display Area
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
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
                      data: _getCurrentQRData(),
                      version: QrVersions.auto,
                      size: 180.0,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$_selectedBagType - ${_getCurrentSizeLabel()}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Size Selection (Horizontal Scroll)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text('Select ${_selectedBagType == 'Regular Bags' ? 'Size' : 'Number'}:', 
                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _bagSizes[_selectedBagType]!.length,
                    itemBuilder: (context, index) {
                      String sizeLabel = _bagSizes[_selectedBagType]![index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSizeIndex = index;
                          });
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _selectedSizeIndex == index ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedSizeIndex == index ? Colors.blue : Colors.grey,
                              width: _selectedSizeIndex == index ? 3 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              sizeLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedSizeIndex == index ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Bag Type Selection (Radio Buttons)
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Bag Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ..._bagTypes.map((bagType) {
                  return RadioListTile<String>(
                    title: Text(bagType),
                    value: bagType,
                    groupValue: _selectedBagType,
                    onChanged: (value) {
                      setState(() {
                        _selectedBagType = value!;
                        _selectedSizeIndex = 0; // Reset to first option
                      });
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final Map<String, String> placeBinQRs;
  final Map<String, String> bagQRs;
  final Function(Map<String, String>) onPlaceBinUpdate;
  final Function(Map<String, String>) onBagUpdate;
  final VoidCallback onExportData;
  final VoidCallback onImportData;

  const SettingsPage({
    super.key,
    required this.placeBinQRs,
    required this.bagQRs,
    required this.onPlaceBinUpdate,
    required this.onBagUpdate,
    required this.onExportData,
    required this.onImportData,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _placeBinController = TextEditingController();
  final TextEditingController _bagController = TextEditingController();
  
  String _selectedColor = 'White';
  int _selectedBoxNumber = 1;
  String _selectedBagType = 'Regular Bags';
  String _selectedBagSize = 'Small';
  
  final List<String> _colors = ['White', 'Yellow', 'Blue', 'Green', 'Red'];
  final List<String> _bagTypes = ['Regular Bags', 'Reusable Bags', 'Small Reusable Bags', 'Insulated Bags'];
  
  final Map<String, List<String>> _bagSizes = {
    'Regular Bags': ['VS', 'GS', 'GM', 'GL', 'GXL', 'GXXL'],
    'Reusable Bags': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'],
    'Small Reusable Bags': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'],
    'Insulated Bags': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'],
  };

  void _addPlaceBinQR() {
    if (_placeBinController.text.isNotEmpty) {
      String key = '${_selectedColor}_$_selectedBoxNumber';
      Map<String, String> updated = Map.from(widget.placeBinQRs);
      updated[key] = _placeBinController.text;
      widget.onPlaceBinUpdate(updated);
      _placeBinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR added for $_selectedColor Bin $_selectedBoxNumber!')),
      );
    }
  }

  void _addBagQR() {
    if (_bagController.text.isNotEmpty) {
      String key = '${_selectedBagType}_$_selectedBagSize';
      Map<String, String> updated = Map.from(widget.bagQRs);
      updated[key] = _bagController.text;
      widget.onBagUpdate(updated);
      _bagController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR added for $_selectedBagType - $_selectedBagSize!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text('Place Bin QR Codes (35 bins)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Color Selection
            DropdownButtonFormField<String>(
              value: _selectedColor,
              decoration: const InputDecoration(
                labelText: 'Select Color',
                border: OutlineInputBorder(),
              ),
              items: _colors.map((color) {
                return DropdownMenuItem(
                  value: color,
                  child: Text(color),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedColor = value!;
                });
              },
            ),
            
            const SizedBox(height: 10),
            
            // Bin Number Selection
            DropdownButtonFormField<int>(
              value: _selectedBoxNumber,
              decoration: const InputDecoration(
                labelText: 'Select Bin Number',
                border: OutlineInputBorder(),
              ),
              items: List.generate(7, (index) {
                int boxNumber = index + 1;
                return DropdownMenuItem(
                  value: boxNumber,
                  child: Text('Bin $boxNumber'),
                );
              }),
              onChanged: (value) {
                setState(() {
                  _selectedBoxNumber = value!;
                });
              },
            ),
            
            const SizedBox(height: 10),
            
            // QR Text Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _placeBinController,
                    decoration: InputDecoration(
                      labelText: 'QR text for $_selectedColor Bin $_selectedBoxNumber',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addPlaceBinQR,
                  child: const Text('Add'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Text('Bag QR Codes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Bag Type Selection
            DropdownButtonFormField<String>(
              value: _selectedBagType,
              decoration: const InputDecoration(
                labelText: 'Select Bag Type',
                border: OutlineInputBorder(),
              ),
              items: _bagTypes.map((bagType) {
                return DropdownMenuItem(
                  value: bagType,
                  child: Text(bagType),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBagType = value!;
                  _selectedBagSize = _bagSizes[_selectedBagType]![0]; // Reset to first option
                });
              },
            ),
            
            const SizedBox(height: 10),
            
            // Bag Size Selection
            DropdownButtonFormField<String>(
              value: _selectedBagSize,
              decoration: InputDecoration(
                labelText: 'Select ${_selectedBagType == 'Regular Bags' ? 'Size' : 'Number'}',
                border: const OutlineInputBorder(),
              ),
              items: _bagSizes[_selectedBagType]!.map((size) {
                return DropdownMenuItem(
                  value: size,
                  child: Text(size),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBagSize = value!;
                });
              },
            ),
            
            const SizedBox(height: 10),
            
            // QR Text Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bagController,
                    decoration: InputDecoration(
                      labelText: 'QR text for $_selectedBagType - $_selectedBagSize',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addBagQR,
                  child: const Text('Add'),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            const Text('Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onExportData,
                    icon: const Icon(Icons.upload),
                    label: const Text('Export Data'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onImportData,
                    icon: const Icon(Icons.download),
                    label: const Text('Import Data'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            const Text('Feedback & Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('For feedback and suggestions, contact me below.'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _launchUrl('https://wa.me/919579575606'),
                  child: Image.asset('icon/whatsapp.png', width: 40, height: 40),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _launchUrl('https://www.instagram.com/thatvishal007?igsh=MXdtOGZiMXZwNmZmZg=='),
                  child: Image.asset('icon/instagram.png', width: 40, height: 40),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _launchUrl('https://www.linkedin.com/in/vishal0x?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app'),
                  child: Image.asset('icon/linkedin.png', width: 40, height: 40),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            const Text('Source Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: () => _launchUrl('https://github.com/VishalSyntax'),
                child: Image.asset('icon/GIthub.png', width: 40, height: 40),
              ),
            ),
            
            const SizedBox(height: 30),
            const Center(
              child: Text(
                '© 2025 Zepto QR. Developed by Vishal.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedBagSize = _bagSizes[_selectedBagType]![0];
  }
  
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  void dispose() {
    _placeBinController.dispose();
    _bagController.dispose();
    super.dispose();
  }
}
