import 'base_url_store.dart';

class AppConfig {
  static const String _defaultBaseUrl =
      "https://script.google.com/macros/s/AKfycbzXQyqvnr1igO1MDW3E1_9t4w_HMb0BSJ54I-ukFHo1QNo8XCl63NncIQ3OLrD7aLdA/exec";

  static String get baseUrl {
    if (BaseUrlStore.url.isNotEmpty) {
      return BaseUrlStore.url;
    }
    return _defaultBaseUrl;
  }
}