import 'package:flutter/material.dart';

/// Reusable Image Picker Tile for settings pages.
class SettingsImagePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String buttonText;

  const SettingsImagePickerTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.buttonText = 'اختر',
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            buttonText,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}
