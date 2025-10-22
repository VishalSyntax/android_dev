import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

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