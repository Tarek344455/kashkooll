library thermal_printer_service;

/// Thermal Printer Service for Secretary Desk
/// Generates a thermal receipt layout in <1 second offline.
/// Simulates printing 500+ student scan receipts.

class ThermalPrinterService {
  /// Prints a batch receipt summary
  /// Returns a string representing the thermal receipt content
  static String printBatchReceipt(List<String> scannedStudentIds, double totalAmount) {
    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('      KASHKOOL CENTER RECEIPT    ');
    buffer.writeln('================================');
    buffer.writeln('Date: ${DateTime.now().toLocal()}');
    buffer.writeln('Scanned Students: ${scannedStudentIds.length}');
    buffer.writeln('--------------------------------');
    for (int i = 0; i < scannedStudentIds.length; i++) {
      buffer.writeln('  - ${scannedStudentIds[i]}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Total Amount: ${ThermalPrinterService.formatEgp(totalAmount)}');
    buffer.writeln('Payment: Cash-to-Wallet Top-up');
    buffer.writeln('--------------------------------');
    buffer.writeln('Thank you for using Kashkool!');
    buffer.writeln('================================');
    return buffer.toString();
  }

  static String formatEgp(double amount) {
    return '${amount.toStringAsFixed(2)} ج.م';
  }
}