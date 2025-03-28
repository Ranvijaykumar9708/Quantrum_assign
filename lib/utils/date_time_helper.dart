import 'package:intl/intl.dart';

String formatDateTime(DateTime dateTime) {
  return DateFormat('MMMM dd, yyyy  hh:mm a').format(dateTime);
}
