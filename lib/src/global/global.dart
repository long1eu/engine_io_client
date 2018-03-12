class Global {
  Global._();

  static String encodeURIComponent(String str) {
    return Uri
        .encodeComponent(str)
        .replaceAll('+', '%20')
        .replaceAll('%21', '!')
        .replaceAll('%27', "'")
        .replaceAll('%28', '(')
        .replaceAll('%29', ')')
        .replaceAll('%7E', '~');
  }

  static String decodeURIComponent(String str) {
    return Uri.decodeComponent(str);
  }
}
