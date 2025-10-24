import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BagsPage extends StatefulWidget {
  final Map<String, String> qrCodes;
  const BagsPage({super.key, required this.qrCodes});

  @override
  State<BagsPage> createState() => _BagsPageState();
}

class _BagsPageState extends State<BagsPage> {
  String _selectedBagType = 'Regular Bags';
  int _selectedSizeIndex = 0;
  final TextEditingController _bulkController1 = TextEditingController();
  final TextEditingController _bulkController2 = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadBulkData();
  }
  
  Future<void> _loadBulkData() async {
    final prefs = await SharedPreferences.getInstance();
    _bulkController1.text = prefs.getString('bulkQR1') ?? '';
    _bulkController2.text = prefs.getString('bulkQR2') ?? '';
  }
  
  Future<void> _saveBulkData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bulkQR1', _bulkController1.text);
    await prefs.setString('bulkQR2', _bulkController2.text);
  }
  
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // QR Display Area
            Container(
              height: 300,
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
          
          const SizedBox(height: 30),
          
          // Bulk QR Generator 1
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bulk QR Code Generator 1', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _bulkController1,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Paste codes here (each line or space creates new QR)',
                  ),
                  onChanged: (value) => _saveBulkData(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _showBulkQRDialog(_bulkController1.text, 'Bulk QR Generator 1'),
                  child: const Text('Generate Bulk QR'),
                ),
              ],
            ),
          ),
          
          // Bulk QR Generator 2
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bulk QR Code Generator 2', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _bulkController2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Paste codes here (each line or space creates new QR)',
                  ),
                  onChanged: (value) => _saveBulkData(),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _showBulkQRDialog(_bulkController2.text, 'Bulk QR Generator 2'),
                  child: const Text('Generate Bulk QR'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    ));
  }

  void _showBulkQRDialog(String inputText, String title) {
    if (inputText.trim().isEmpty) return;
    
    List<String> codes = inputText.split(RegExp(r'[\s\n]+'))
        .where((code) => code.trim().isNotEmpty)
        .map((code) => code.trim())
        .toList();
    
    if (codes.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: codes.length,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: QrImageView(
                        data: codes[index],
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      codes[index],
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
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
  }

  @override
  void dispose() {
    _bulkController1.dispose();
    _bulkController2.dispose();
    super.dispose();
  }
}