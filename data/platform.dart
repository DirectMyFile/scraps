library platform.core;

/// Represents a Platform-Independent API for doing common tasks that differ between platforms.
/// We can't use any standard non-core libraries. They are not guaranteed to be available.
/// This is designed to rely only on the language-spec whenever possible.
abstract class PlatformAdapter {
  void fetchString(
    String method,
    String url,
    void handler(int statusCode, String content, Map<String, String> headers),
    {
      String body,
      Map<String, String> headers
    }
  );

  void fetchBytes(
    String method,
    String url,
    void handler(int statusCode, List<int> content, Map<String, String> headers),
    {
      List<int> body,
      Map<String, String> headers
    }
  );

  dynamic parseJSON(String input);
  String encodeJSON(input);

  String encodeUriComponent(String input);
  String decodeUriComponent(String input);

  void createWebSocket(String url, void handler(WebSocket socket), {List<String> protocols});
}

/// A WebSocket API
abstract class WebSocket {
  void close({int code, String reason, void callback()});
  void send(dynamic message);
  void onMessage(void callback(dynamic message));
  void onClose(void callback(int code, String reason));
}
