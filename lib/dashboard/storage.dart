import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StoragePage extends StatefulWidget {
  @override
  _StoragePageState createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;
  List<Map<String, dynamic>> _uploadedFiles = [];
  bool _isLoadingFiles = false;

  @override
  void initState() {
    super.initState();
    _loadUploadedFiles();
  }

  Future<void> _loadUploadedFiles() async {
    setState(() => _isLoadingFiles = true);
    try {
      final storageRef = FirebaseStorage.instance.ref().child('documents');
      final result = await storageRef.listAll();

      final files = await Future.wait(
        result.items.map((item) async {
          final url = await item.getDownloadURL();
          final metadata = await item.getMetadata();
          return {
            'name': item.name,
            'url': url,
            'ref': item,
            'size': metadata.size,
            'uploaded': metadata.timeCreated,
          };
        }),
      );

      setState(() {
        _uploadedFiles = files;
        _isLoadingFiles = false;
      });
    } catch (e) {
      setState(() => _isLoadingFiles = false);
      _showSnackBar('Failed to load files: ${e.toString()}');
    }
  }

  Future<void> _pickFile() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _isUploading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final fileName = path.basename(_selectedFile!.path);
      final storageRef = FirebaseStorage.instance.ref().child(
          'documents/${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = storageRef.putFile(_selectedFile!);

      uploadTask.snapshotEvents.listen((taskSnapshot) {
        setState(() {
          _uploadProgress =
              taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        });
      });

      await uploadTask.whenComplete(() {});
      _showSnackBar('File uploaded successfully!');
      await _loadUploadedFiles();
    } catch (e) {
      _showSnackBar('Upload failed: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteFile(String url) async {
    try {
      setState(() => _isUploading = true);
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
      _showSnackBar('File deleted successfully!');
      await _loadUploadedFiles();
    } catch (e) {
      _showSnackBar('Delete failed: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _viewFileDetails(Map<String, dynamic> file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file['name']),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Image.network(file['url']),
              SizedBox(height: 16),
              Text('Uploaded: ${file['uploaded']?.toString() ?? 'Unknown'}'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteFile(file['url']);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Storage'),
      ),
      body: Column(
        children: [
          // Upload Section
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _selectedFile != null
                      ? Column(
                          children: [
                            Image.file(_selectedFile!,
                                width: 150, height: 150, fit: BoxFit.cover),
                            SizedBox(height: 10),
                          ],
                        )
                      : Icon(Icons.image_outlined,
                          size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  if (_isUploading)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: _uploadProgress,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Uploading: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          child: Text('Select File'),
                          onPressed: _isUploading ? null : _pickFile,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          child: Text('Upload'),
                          onPressed: _selectedFile == null || _isUploading
                              ? null
                              : _uploadFile,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Documents List
          Expanded(
            child: _isLoadingFiles
                ? Center(child: CircularProgressIndicator())
                : _uploadedFiles.isEmpty
                    ? Center(child: Text('No documents uploaded yet'))
                    : ListView.builder(
                        itemCount: _uploadedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _uploadedFiles[index];
                          return ListTile(
                            leading: Icon(Icons.insert_drive_file),
                            title: Text(file['name']),
                            subtitle: Text(
                                'Uploaded: ${file['uploaded']?.toString().substring(0, 10) ?? 'Unknown'}'),
                            onTap: () => _viewFileDetails(file),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
