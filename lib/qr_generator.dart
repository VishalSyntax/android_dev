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