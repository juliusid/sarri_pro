import 'package:intl/intl.dart';

class TFormatter {
  static String formatDate(DateTime? date) {
    date ??= DateTime.now();
    return DateFormat(
      'dd-MMM-yyyy',
    ).format(date); // Customize the date format as needed
  }

  static String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
    ).format(amount); // Customize the currency locale and symbol as needed
  }

  static String formatPhoneNumber(String phoneNumber) {
    // Assuming a 10-digit US phone number format (123) 456-7890
    if (phoneNumber.length == 10) {
      return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}';
    } else if (phoneNumber.length == 11) {
      return '${phoneNumber.substring(0, 1)} (${phoneNumber.substring(1, 4)}) ${phoneNumber.substring(4, 7)} ${phoneNumber.substring(7)}';
    }
    // Add more custom phone number formatting logic for different formats if needed.
    return phoneNumber;
  }

  static String formatNigeriaPhoneNumber(String phoneNumber) {
    // 1. Remove any non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // 2. Check if it starts with '0' and has 11 digits (e.g., 08012345678)
    if (digitsOnly.startsWith('0') && digitsOnly.length == 11) {
      return '+234${digitsOnly.substring(1)}';
    }
    // 3. Check if it starts with '234' and has 13 digits (e.g., 2348012345678)
    else if (digitsOnly.startsWith('234') && digitsOnly.length == 13) {
      return '+$digitsOnly';
    }
    // 4. Check if it has 10 digits (e.g., 8012345678) - assumes it's a local number
    else if (digitsOnly.length == 10) {
      return '+234$digitsOnly';
    }
    // 5. If it's already in the correct format, return as is
    else if (digitsOnly.startsWith('+234') && digitsOnly.length == 14) {
      return phoneNumber;
    }
    // 6. Otherwise, return the original number (or handle as an error)
    else {
      // You might want to throw an exception or return a specific error format
      return phoneNumber;
    }
  }
}
