String formatKsh(double amount) {
  final fixed = amount.toStringAsFixed(0);
  final negative = fixed.startsWith('-');
  final abs = negative ? fixed.substring(1) : fixed;
  final buf = StringBuffer();
  for (var i = 0; i < abs.length; i++) {
    if (i > 0 && (abs.length - i) % 3 == 0) buf.write(',');
    buf.write(abs[i]);
  }
  final formatted = buf.toString();
  return 'KSh ${negative ? '-' : ''}$formatted';
}