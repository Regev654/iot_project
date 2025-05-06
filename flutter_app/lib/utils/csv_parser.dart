import 'package:csv/csv.dart';

List<String> parseUserIDsFromCSV(String csvContent) {
  final List<List<dynamic>> csvTable = CsvToListConverter().convert(csvContent);
  return csvTable
      .map((row) => row[0].toString())
      .where((id) => RegExp(r'^\d+$').hasMatch(id)) // Only digits
      .toSet() // Remove duplicates
      .toList();
}