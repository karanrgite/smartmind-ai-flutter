class ApiConstants {
  static const String baseUrl = 'https://smartmind-backend-production.up.railway.app';

  // Auth endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';

  // Chat endpoints
  static const String conversations = '/api/chat/conversations';
  static const String sendMessage = '/api/chat/send';

  static String getMessages(String conversationId) =>
      '/api/chat/conversations/$conversationId/messages';

  static String deleteConversation(String conversationId) =>
      '/api/chat/conversations/$conversationId';

  static String updatePersona(String conversationId) =>
      '/api/chat/conversations/$conversationId/persona';
}