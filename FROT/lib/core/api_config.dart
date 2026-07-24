// URL base del backend. En dev apunta al FastAPI local; en producción se
// sobreescribe al buildear con:
//   flutter build web --dart-define=API_URL=https://crafthub-api.onrender.com
// (o el hosting que uses).
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
}
