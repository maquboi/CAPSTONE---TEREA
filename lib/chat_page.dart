import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shared_widgets.dart';
import 'app_models.dart';
import 'typing_indicator.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isTagalog = false;
  bool _isFirstLoad = true;
  
  // Character limit
  final int _maxChars = 500;
  int _charCount = 0;

  // Profile picture
  String? _userAvatarUrl;
  
  // Bot avatar (using medical icon - you can change to your logo)
  final Widget _botAvatar = const CircleAvatar(
    radius: 16,
    backgroundColor: Color(0xFF606C38),
    child: Icon(Icons.medical_services, color: Colors.white, size: 18),
  );

  final String apiUrl = 'https://chatbot.richoffgrandmas04.workers.dev';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadChatHistory();
    _controller.addListener(_updateCharCount);
    _updateCharCount();
  }

  @override
  void dispose() {
    _saveChatHistory();
    _controller.removeListener(_updateCharCount);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser != null) {
        final response = await supabase
            .from('profiles')
            .select('avatar_url')
            .eq('id', currentUser.id)
            .maybeSingle();
        
        if (response != null && response['avatar_url'] != null && response['avatar_url'].toString().isNotEmpty) {
          setState(() {
            _userAvatarUrl = response['avatar_url'];
          });
        }
      }
    } catch (e) {
      print('Error loading profile picture: $e');
    }
  }

  void _updateCharCount() {
    setState(() {
      _charCount = _controller.text.length;
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMessages = prefs.getStringList('chat_messages');
      
      if (savedMessages != null && savedMessages.isNotEmpty) {
        final List<ChatMessage> loadedMessages = [];
        for (String messageJson in savedMessages) {
          final Map<String, dynamic> decoded = jsonDecode(messageJson);
          loadedMessages.add(ChatMessage(
            text: decoded['text'],
            isUser: decoded['isUser'],
            timestamp: DateTime.parse(decoded['timestamp']),
          ));
        }
        setState(() {
          _messages = loadedMessages;
          _isFirstLoad = false;
        });
      } else {
        setState(() {
          _messages = [
            ChatMessage(
              text: "Hello! I am TEREA, your health assistant. How can I help you today?", 
              isUser: false,
            ),
          ];
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages = [
          ChatMessage(
            text: "Hello! I am TEREA, your health assistant. How can I help you today?", 
            isUser: false,
          ),
        ];
        _isFirstLoad = false;
      });
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> messagesToSave = [];
      
      for (ChatMessage msg in _messages) {
        if (msg.text != "___TYPING___") {
          messagesToSave.add(jsonEncode({
            'text': msg.text,
            'isUser': msg.isUser,
            'timestamp': msg.timestamp.toIso8601String(),
          }));
        }
      }
      
      await prefs.setStringList('chat_messages', messagesToSave);
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  Future<void> _clearChatHistory() async {
    setState(() {
      _messages = [
        ChatMessage(
          text: "Hello! I am TEREA, your health assistant. How can I help you today?", 
          isUser: false,
        ),
      ];
    });
    await _saveChatHistory();
  }

  Future<void> _exportChat() async {
    final realMessages = _messages.where((m) => m.text != "___TYPING___").toList();
    if (realMessages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No conversation to export. Send some messages first!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    StringBuffer exportText = StringBuffer();
    
    exportText.writeln('═══════════════════════════════════════');
    exportText.writeln('        TEREA TB ASSISTANT CHAT');
    exportText.writeln('        Exported on: ${_getCurrentDateTime()}');
    exportText.writeln('═══════════════════════════════════════');
    exportText.writeln('');
    
    for (var msg in _messages) {
      if (msg.text != "___TYPING___") {
        String sender = msg.isUser ? '👤 YOU' : '🤖 TEREA';
        String time = _formatTimestampForExport(msg.timestamp);
        exportText.writeln('[$time] $sender:');
        exportText.writeln('  ${msg.text}');
        exportText.writeln('');
      }
    }
    
    exportText.writeln('═══════════════════════════════════════');
    exportText.writeln('⚠️ DISCLAIMER:');
    exportText.writeln('This conversation is for informational purposes only.');
    exportText.writeln('TEREA is an AI assistant, not a medical professional.');
    exportText.writeln('Please consult a qualified doctor for medical advice.');
    exportText.writeln('═══════════════════════════════════════');
    
    await Share.share(
      exportText.toString(),
      subject: 'TEREA TB Assistant Chat Export',
    );
  }

  String _getCurrentDateTime() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
           '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  String _formatTimestampForExport(DateTime timestamp) {
    return '${timestamp.month}/${timestamp.day} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _sendMessage({String? predefinedMessage}) async {
    final userMessage = predefinedMessage ?? _controller.text;
    
    if (userMessage.trim().isEmpty || _isLoading) return;
    if (userMessage.length > _maxChars) return;
    
    setState(() {
      _isTagalog = _containsTagalog(userMessage);
    });
    
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isLoading = true;
    });
    
    if (predefinedMessage == null) {
      _controller.clear();
      _updateCharCount();
    }
    
    await _saveChatHistory();
    
    setState(() {
      _messages.add(ChatMessage(text: "___TYPING___", isUser: false));
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': userMessage}),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.removeLast();
          _messages.add(ChatMessage(text: data['reply'], isUser: false));
        });
        await _saveChatHistory();
      } else {
        throw Exception('API returned ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: _isTagalog 
              ? "Sorry, nagka-error. Pakisubukan muli."
              : "Sorry, I'm having trouble. Please try again.",
          isUser: false
        ));
      });
      await _saveChatHistory();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _containsTagalog(String text) {
    final tagalogWords = ['ano', 'paano', 'bakit', 'saan', 'kailan', 'sino', 'po', 'ako', 'ikaw', 'ng', 'mga', 'at', 'sa', 'para', 'may', 'meron', 'wala', 'doktor', 'gamot', 'ubo', 'lagnat', 'timbang', 'pagpapawis'];
    final lowerText = text.toLowerCase();
    return tagalogWords.any((word) => lowerText.contains(word));
  }

  Widget _buildQuickReplies() {
    final List<Map<String, String>> questions = _isTagalog
        ? [
            {"text": "Ano ang TB?", "question": "Ano ang TB?"},
            {"text": "🫁 Sintomas ng TB", "question": "Ano ang mga sintomas ng TB?"},
            {"text": "💊 Paano gamutin?", "question": "Paano ginagamot ang TB?"},
            {"text": "🏥 Saan magpa-test?", "question": "Saan pwede magpa-test ng TB?"},
            {"text": "🛡️ Paano maiwasan?", "question": "Paano maiwasan ang TB?"},
            {"text": "📱 Paano gamitin app?", "question": "Paano gamitin ang app na ito?"},
          ]
        : [
            {"text": "What is TB?", "question": "What is tuberculosis?"},
            {"text": "🫁 Symptoms", "question": "What are the symptoms of TB?"},
            {"text": "💊 Treatment", "question": "How is TB treated?"},
            {"text": "🏥 Where to test?", "question": "Where can I get tested for TB?"},
            {"text": "🛡️ Prevention", "question": "How can I prevent TB?"},
            {"text": "📱 App Workflow", "question": "How do I navigate this app? I'm lost"},
          ];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                questions[index]["text"]!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF606C38), fontWeight: FontWeight.w600),
              ),
              onPressed: _isLoading ? null : () {
                _sendMessage(predefinedMessage: questions[index]["question"]!);
              },
              backgroundColor: const Color(0xFFFEFAE0),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFDDE5B6))),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9), // Light clean background
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF283618), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            buildLogo(size: 32), 
            const SizedBox(width: 10), 
            const Text(
              'TEREA Chat',
              style: TextStyle(color: Color(0xFF283618), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF283618)),
            onPressed: _exportChat,
            tooltip: 'Export chat',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFF283618)),
            onPressed: () => _showClearDialog(),
            tooltip: 'Clear chat history',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isTyping = msg.text == "___TYPING___" && !msg.isUser;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bot avatar (left side)
                      if (!msg.isUser && !isTyping) _botAvatar,
                      if (!msg.isUser && !isTyping) const SizedBox(width: 8),
                      
                      // Message bubble
                      Expanded(
                        child: Align(
                          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: isTyping
                                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                                : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.65,
                            ),
                            decoration: BoxDecoration(
                              color: msg.isUser ? const Color(0xFF606C38) : Colors.white,
                              borderRadius: BorderRadius.circular(20).copyWith(
                                bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(20),
                                bottomLeft: msg.isUser ? const Radius.circular(20) : const Radius.circular(4),
                              ),
                              boxShadow: [
                                if (!msg.isUser)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: isTyping
                                ? const TypingIndicator()
                                : Column(
                                    crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.text, 
                                        style: TextStyle(
                                          color: msg.isUser ? Colors.white : const Color(0xFF283618),
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        msg.formattedTime,
                                        style: TextStyle(
                                          color: msg.isUser ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      
                      // User avatar (right side)
                      if (msg.isUser && !isTyping) const SizedBox(width: 8),
                      if (msg.isUser && !isTyping)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: _userAvatarUrl != null && _userAvatarUrl!.isNotEmpty
                              ? NetworkImage(_userAvatarUrl!)
                              : null,
                          backgroundColor: Colors.grey[200],
                          child: _userAvatarUrl == null || _userAvatarUrl!.isEmpty
                              ? const Icon(Icons.person, color: Color(0xFF606C38), size: 18)
                              : null,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (!_isLoading && _messages.length > 1) _buildQuickReplies(),
          _buildInputArea(),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Clear Chat History', style: TextStyle(color: Color(0xFF283618), fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to delete all messages? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                _clearChatHistory();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Chat history cleared'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: const Color(0xFF606C38),
                  ),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30), // Extra bottom padding for safe area
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F4),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _controller,
                    enabled: !_isLoading,
                    maxLength: _maxChars,
                    maxLines: 4,
                    minLines: 1,
                    style: const TextStyle(color: Color(0xFF283618), fontSize: 15),
                    decoration: InputDecoration(
                      hintText: _isTagalog 
                          ? "Magtanong tungkol sa TB..."
                          : "Ask about TB symptoms, treatment, or prevention...",
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      counterText: "",
                    ),
                    onChanged: (text) => _updateCharCount(),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, right: 12),
                    child: Text(
                      '$_charCount / $_maxChars',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _charCount > _maxChars 
                            ? Colors.red 
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            margin: const EdgeInsets.only(bottom: 20), // Align with the bottom of the textfield, above the counter
            decoration: BoxDecoration(
              color: const Color(0xFF606C38),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF606C38).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), 
                    padding: const EdgeInsets.all(14),
                    onPressed: _charCount > 0 && _charCount <= _maxChars && !_isLoading
                        ? () => _sendMessage()
                        : null,
                  ),
          ),
        ],
      ),
    );
  }
}