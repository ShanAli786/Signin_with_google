// ignore_for_file: no_leading_underscores_for_local_identifiers, avoid_print

import 'package:image_picker/image_picker.dart';

pickImage(ImageSource source) async {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? file = await _imagePicker.pickImage(source: source);
  if (file != null) {
    return await file.readAsBytes();
  }
  print("NO image selected");
}
