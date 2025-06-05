String cleanTime(String time) {
  return time
      .replaceAll(RegExp(r'[\u202F\u00A0]'), ' ') // Convert NBSP to space
      .replaceFirstMapped(
        RegExp(r'^(\d):'),
        (m) => '0${m[1]}:',
      ) // Add leading zero
      .trim();
}
