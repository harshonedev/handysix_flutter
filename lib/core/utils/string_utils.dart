class StringUtils {
  static String limitTextLength(String text, {int maxLength = 10}) {
    if (text.length > maxLength) {
      return '${text.substring(0, maxLength)}...';
    }
    return text;
  }
}
