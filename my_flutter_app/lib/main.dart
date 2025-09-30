import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR by Vishal',
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

  void _saveQR(String qrData) {
    if (qrData.isNotEmpty && !savedQRs.contains(qrData)) {
      setState(() {
        savedQRs.add(qrData);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code saved!')),
      );
    }
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
          SavedQRPage(savedQRs: savedQRs),
          SettingsPage(
            placeBinQRs: placeBinQRs,
            bagQRs: bagQRs,
            onPlaceBinUpdate: (qrs) => setState(() => placeBinQRs = qrs),
            onBagUpdate: (qrs) => setState(() => bagQRs = qrs),
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
        title: const Text('QR by Vishal'),
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
  final List<Color> _colorValues = [Colors.grey[300]!, Colors.yellow, Colors.blue, Colors.green, Colors.red];
  
  String _getCurrentQRData() {
    String colorKey = '${_colors[_selectedColorIndex]}_$_selectedBoxNumber';
    return widget.qrCodes[colorKey] ?? 'No QR defined for ${_colors[_selectedColorIndex]} Box $_selectedBoxNumber';
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
                      '${_colors[_selectedColorIndex]} Box $_selectedBoxNumber',
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
                // Box Number Selection (Horizontal Scroll)
                const Text('Select Box Number:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: PageView.builder(
                    onPageChanged: (index) {
                      setState(() {
                        _selectedBoxNumber = index + 1;
                      });
                    },
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      int boxNumber = index + 1;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
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
                            'Box $boxNumber',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _selectedBoxNumber == boxNumber ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Color Selection (Vertical Scroll)
                const Text('Select Color:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: PageView.builder(
                    scrollDirection: Axis.vertical,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedColorIndex = index;
                      });
                    },
                    itemCount: _colors.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
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
                            _colors[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: index == 0 ? Colors.black : Colors.white,
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


class SavedQRPage extends StatelessWidget {
  final List<String> savedQRs;
  const SavedQRPage({super.key, required this.savedQRs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved QR'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: savedQRs.isEmpty
          ? const Center(child: Text('No saved QR codes'))
          : ListView.builder(
              itemCount: savedQRs.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.qr_code),
                    title: Text(savedQRs[index]),
                    trailing: Container(
                      width: 50,
                      height: 50,
                      child: QrImageView(
                        data: savedQRs[index],
                        size: 50,
                      ),
                    ),
                  ),
                );
              },
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
  
  Map<String, List<String>> _bagSizes = {
    'Regular Bags': ['Small', 'Medium', 'Large', 'Extra Large'],
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
                  child: PageView.builder(
                    onPageChanged: (index) {
                      setState(() {
                        _selectedSizeIndex = index;
                      });
                    },
                    itemCount: _bagSizes[_selectedBagType]!.length,
                    itemBuilder: (context, index) {
                      String sizeLabel = _bagSizes[_selectedBagType]![index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _selectedSizeIndex == index ? Colors.white : Colors.black,
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

  const SettingsPage({
    super.key,
    required this.placeBinQRs,
    required this.bagQRs,
    required this.onPlaceBinUpdate,
    required this.onBagUpdate,
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
  
  Map<String, List<String>> _bagSizes = {
    'Regular Bags': ['Small', 'Medium', 'Large', 'Extra Large'],
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
        SnackBar(content: Text('QR added for $_selectedColor Box $_selectedBoxNumber!')),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Place Bin QR Codes (35 boxes)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            
            // Box Number Selection
            DropdownButtonFormField<int>(
              value: _selectedBoxNumber,
              decoration: const InputDecoration(
                labelText: 'Select Box Number',
                border: OutlineInputBorder(),
              ),
              items: List.generate(7, (index) {
                int boxNumber = index + 1;
                return DropdownMenuItem(
                  value: boxNumber,
                  child: Text('Box $boxNumber'),
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
                      labelText: 'QR text for $_selectedColor Box $_selectedBoxNumber',
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
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedBagSize = _bagSizes[_selectedBagType]![0];
  }
  
  @override
  void dispose() {
    _placeBinController.dispose();
    _bagController.dispose();
    super.dispose();
  }
}
