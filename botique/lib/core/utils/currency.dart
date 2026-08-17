String formatKsh(double amount) {
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final negative = digits.startsWith('-');
  final abs = negative ? digits.substring(1) : digits;
  final buf = StringBuffer();
  for (var i = 0; i < abs.length; i++) {
    if (i > 0 && (abs.length - i) % 3 == 0) buf.write(',');
    buf.write(abs[i]);
  }
  final formatted = buf.toString();
  return 'KSh ${negative ? '-' : ''}$formatted.${parts[1]}';
}