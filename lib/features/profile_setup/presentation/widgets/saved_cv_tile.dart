import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../profile_copy.dart';

/// The CV already stored on the profile (`personal-information.cv`), shown
/// while editing. Replacing it from here is not connected yet.
class SavedCvTile extends StatelessWidget {
  const SavedCvTile({super.key, required this.cv});
  final Map<String, dynamic>? cv;

  /// "124 KB" / "2.4 MB" from the backend's size in bytes.
  static String? _size(Object? raw) {
    final bytes = num.tryParse('${raw ?? ''}');
    if (bytes == null || bytes <= 0) return null;
    return bytes >= 1024 * 1024
        ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(bytes / 1024).ceil()} KB';
  }

  @override
  Widget build(BuildContext context) {
    final name = cv?['file_name']?.toString() ?? cv?['name']?.toString() ?? '';
    final size = _size(cv?['size']);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.insert_drive_file,
              size: 18,
              color: AppColors.blueStrong,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: AppColors.blueStrong,
                  ),
                ),
                if (size != null)
                  Text(
                    size,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.5,
                      color: AppColors.neutral600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            pc(context, 'Uploaded'),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.blueStrong,
            ),
          ),
        ],
      ),
    );
  }
}
