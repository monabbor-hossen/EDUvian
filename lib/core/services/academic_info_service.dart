import 'package:shared_preferences/shared_preferences.dart';
import '../models/academic_info.dart';

class AcademicInfoService {
  static const String _key = 'academic_info';

  /// Fetches the raw string of the academic info from SharedPreferences
  static Future<String?> getRawAcademicInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// Fetches and parses the academic info from SharedPreferences
  static Future<AcademicInfo?> getAcademicInfo() async {
    final infoString = await getRawAcademicInfo();
    if (infoString != null && infoString.isNotEmpty) {
      return parseAcademicInfo(infoString);
    }
    return null;
  }
}
