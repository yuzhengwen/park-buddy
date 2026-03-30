import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../controllers/parking_session_controller.dart';

class PhotosSection extends StatelessWidget {
  const PhotosSection();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ParkingSessionController>();

    if (c.imageUrls.isEmpty && !c.isOngoing) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...c.imageUrls.map((url) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: 150,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 150,
                          height: 120,
                          color: Colors.grey[200]),
                    ),
                  )),
              if (c.isOngoing)
                GestureDetector(
                  onTap: c.isUploadingImage
                      ? null
                      : () => _showSourceSheet(context, c),
                  child: Container(
                    width: 150,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.grey.shade300),
                    ),
                    child: c.isUploadingImage
                        ? const Center(
                            child: CircularProgressIndicator())
                        : const Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: Colors.grey, size: 32),
                              SizedBox(height: 6),
                              Text('Add photo',
                                  style: TextStyle(
                                      color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  void _showSourceSheet(
      BuildContext context, ParkingSessionController c) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () async {
                Navigator.pop(context);
                await _upload(context, c, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _upload(context, c, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upload(BuildContext context,
      ParkingSessionController c, ImageSource source) async {
    try {
      await c.uploadImage(source);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }
}