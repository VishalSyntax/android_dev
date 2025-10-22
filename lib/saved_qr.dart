import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SavedQRPage extends StatefulWidget {
  final List<String> savedQRs;
  final Map<String, String> qrTitles;
  final Map<String, List<String>> qrFolders;
  final List<String> folderOrder;
  final Function(int) onDelete;
  final Function(String, String) onDeleteFromFolder;
  final Function(String, String, String) onUpdate;
  final Function(String, String, String, String) onUpdateInFolder;
  final Function(String) onCreateFolder;
  final Function(String) onDeleteFolder;
  final Function(String, String) onRenameFolder;
  final Function(int, int) onReorderFolders;
  final Function(String, String) onMoveToFolder;
  
  const SavedQRPage({
    super.key, 
    required this.savedQRs,
    required this.qrTitles,
    required this.qrFolders,
    required this.folderOrder,
    required this.onDelete,
    required this.onDeleteFromFolder,
    required this.onUpdate,
    required this.onUpdateInFolder,
    required this.onCreateFolder,
    required this.onDeleteFolder,
    required this.onRenameFolder,
    required this.onReorderFolders,
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

  void _showEditQRDialog(String qrData) {
    final TextEditingController qrController = TextEditingController(text: qrData);
    final TextEditingController titleController = TextEditingController(text: widget.qrTitles[qrData] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qrController,
              decoration: const InputDecoration(
                labelText: 'QR Data',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              if (qrController.text.isNotEmpty) {
                if (_selectedFolder == 'Saved QRs') {
                  widget.onUpdate(qrData, qrController.text, titleController.text);
                } else {
                  widget.onUpdateInFolder(qrData, qrController.text, titleController.text, _selectedFolder);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFolderOptionsDialog(String folderName) {
    if (folderName == 'Saved QRs') return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Folder: $folderName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameFolderDialog(folderName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteFolderDialog(folderName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameFolderDialog(String oldName) {
    final TextEditingController controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
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
              if (controller.text.isNotEmpty && controller.text != oldName) {
                widget.onRenameFolder(oldName, controller.text);
                if (_selectedFolder == oldName) {
                  setState(() => _selectedFolder = controller.text);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(String folderName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "$folderName"? All QR codes in this folder will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteFolder(folderName);
              if (_selectedFolder == folderName) {
                setState(() => _selectedFolder = 'Saved QRs');
              }
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
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
            child: ReorderableListView(
              scrollDirection: Axis.horizontal,
              onReorder: widget.onReorderFolders,
              children: widget.folderOrder.map((folderName) {
                return _buildFolderTab(folderName, Key(folderName));
              }).toList(),
            ),
          ),
          
          // QR List
          Expanded(
            child: currentQRs.isEmpty
                ? const Center(child: Text('No QR codes in this folder'))
                : ListView.builder(
                    itemCount: currentQRs.length,
                    itemBuilder: (context, index) {
                      String qrData = currentQRs[index];
                      String title = widget.qrTitles[qrData] ?? '';
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.qr_code),
                          title: Text(title.isNotEmpty ? title : qrData),
                          subtitle: title.isNotEmpty ? Text(qrData, style: TextStyle(fontSize: 12, color: Colors.grey)) : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                child: QrImageView(
                                  data: qrData,
                                  size: 50,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.green),
                                onPressed: () => _showEditQRDialog(qrData),
                              ),
                              if (_selectedFolder == 'Saved QRs')
                                IconButton(
                                  icon: const Icon(Icons.folder, color: Colors.blue),
                                  onPressed: () => _showMoveToFolderDialog(qrData),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  if (_selectedFolder == 'Saved QRs') {
                                    widget.onDelete(index);
                                  } else {
                                    widget.onDeleteFromFolder(qrData, _selectedFolder);
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(title.isNotEmpty ? title : 'QR Code'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    QrImageView(
                                      data: qrData,
                                      version: QrVersions.auto,
                                      size: 250.0,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      qrData,
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

  Widget _buildFolderTab(String folderName, Key key) {
    bool isSelected = _selectedFolder == folderName;
    return GestureDetector(
      key: key,
      onTap: () {
        setState(() {
          _selectedFolder = folderName;
        });
      },
      onDoubleTap: () => _showFolderOptionsDialog(folderName),
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