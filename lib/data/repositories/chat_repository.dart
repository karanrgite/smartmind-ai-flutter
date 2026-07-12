import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation_model.dart';


class ChatRepository {
  final Dio _dio = ApiClient().dio;

  // Get all conversations
  Future<List<ConversationModel>> getConversations() async {
    try {
      print('>>> GET CONVERSATIONS URL: ${ApiConstants.baseUrl}${ApiConstants.conversations}');
      final response = await _dio.get(ApiConstants.conversations);
      print('✅ GET CONVERSATIONS SUCCESS: ${response.statusCode}');
      print('>>> DATA: ${response.data}');
      final List data = response.data;
      return data.map((e) => ConversationModel.fromJson(e)).toList();
    } catch (e) {
      print('❌ GET CONVERSATIONS FAILED: $e');
      if (e is DioException) {
        print('>>> STATUS CODE: ${e.response?.statusCode}');
        print('>>> RESPONSE DATA: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // Create new conversation
  Future<ConversationModel> createConversation(String title) async {
    final response = await _dio.post(
      ApiConstants.conversations,
      data: {'title': title},
    );
    return ConversationModel.fromJson(response.data);
  }

  Future<void> cacheMessages(String conversationId, List<MessageModel> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmed = messages.length > 50
          ? messages.sublist(messages.length - 50)
          : messages;
      final jsonList = trimmed.map((m) => m.toJson()).toList();
      await prefs.setString('messages_$conversationId', jsonEncode(jsonList));
    } catch (_) {
      // Cache failures are silent — network is source of truth
    }
  }

  Future<List<MessageModel>> getCachedMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('messages_$conversationId');
      if (raw == null) return [];
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => MessageModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearCachedMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('messages_$conversationId');
    } catch (_) {}
  }

  Future<void> deleteAllConversations() async {
    final conversations = await getConversations();
    for (final conv in conversations) {
      try {
        await deleteConversation(conv.id);
      } catch (_) {
        // keep deleting the rest even if one fails
      }
    }
  }

  Future<void> clearAllCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('messages_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }

  // Send message and get AI reply
  Future<MessageModel> sendMessage(String conversationId, String message) async {
    final response = await _dio.post(
      ApiConstants.sendMessage,
      data: {
        'conversationId': conversationId,
        'message': message,
      },
    );
    return MessageModel.fromJson(response.data);
  }
  // Get messages for a conversation
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      print('╔══════════════════════════════════════╗');
      print('║         GET MESSAGES REQUEST          ║');
      print('╚══════════════════════════════════════╝');
      print('>>> CONVERSATION ID: $conversationId');
      print('>>> URL: ${ApiConstants.baseUrl}${ApiConstants.getMessages(conversationId)}');

      final response = await _dio.get(ApiConstants.getMessages(conversationId));

      print('✅ GET MESSAGES SUCCESS');
      print('>>> STATUS: ${response.statusCode}');
      print('>>> DATA: ${response.data}');

      final List data = response.data;
      return data.map((e) => MessageModel.fromJson(e)).toList();

    } catch (e) {
      print('❌ GET MESSAGES FAILED');
      print('>>> ERROR: $e');
      rethrow;
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    await _dio.delete(ApiConstants.deleteConversation(conversationId));
  }

  // Update conversation persona
  Future<ConversationModel> updatePersona(String conversationId, String persona) async {
    final response = await _dio.put(
      ApiConstants.updatePersona(conversationId),
      data: {'persona': persona},
    );
    return ConversationModel.fromJson(response.data);
  }

}