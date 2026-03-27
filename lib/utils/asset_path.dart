/// Normalizes Flutter bundle asset paths so mistaken `assets/assets/...`
/// duplicates collapse to a single `assets/` prefix, while preserving network URLs.
String normalizeBundleAssetPath(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  var p = raw.trim().replaceAll('\\', '/');
  if (p.startsWith('http://') || p.startsWith('https://')) {
    return p;
  }
  while (p.startsWith('/')) {
    p = p.substring(1);
  }
  while (p.contains('assets/assets/')) {
    p = p.replaceAll('assets/assets/', 'assets/');
  }
  if (!p.startsWith('assets/')) {
    p = 'assets/$p';
  }
  while (p.contains('assets/assets/')) {
    p = p.replaceAll('assets/assets/', 'assets/');
  }
  return p;
}
