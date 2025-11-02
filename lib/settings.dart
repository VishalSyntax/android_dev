import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
      _updatePlaceBinController();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR added for $_selectedColor Bin $_selectedBoxNumber!')),
      );
    }
  }
  
  void _updatePlaceBinController() {
    String key = '${_selectedColor}_$_selectedBoxNumber';
    _placeBinController.text = widget.placeBinQRs[key] ?? '';
  }

  void _addBagQR() {
    if (_bagController.text.isNotEmpty) {
      String key = '${_selectedBagType}_$_selectedBagSize';
      Map<String, String> updated = Map.from(widget.bagQRs);
      updated[key] = _bagController.text;
      widget.onBagUpdate(updated);
      _bagController.clear();
      _updateBagController();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR added for $_selectedBagType - $_selectedBagSize!')),
      );
    }
  }
  
  void _updateBagController() {
    String key = '${_selectedBagType}_$_selectedBagSize';
    _bagController.text = widget.bagQRs[key] ?? '';
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
                  _updatePlaceBinController();
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
                  _updatePlaceBinController();
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
                  _updateBagController();
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
                  _updateBagController();
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
    _updatePlaceBinController();
    _updateBagController();
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