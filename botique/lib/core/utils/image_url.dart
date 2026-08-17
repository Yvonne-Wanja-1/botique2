import '../../data/api/api_bootstrap.dart';

/// Resolves backend-relative asset URLs (e.g. `/images/abc.png`) against the
/// API base URL while leaving absolute URLs untouched. Used by widgets that
/// render product images but have no access to the ApiClient instance.
String resolveImageUrl(String url) {
  if (url.isEmpty || url.startsWith('http://') || url.startsWith('https://')) return url;
  return url.startsWith('/') ? '$kApiBaseUrl$url' : '$kApiBaseUrl/$url';
}