import 'package:flutter/material.dart';

class AIAssistantSheet extends StatefulWidget {
  const AIAssistantSheet({Key? key}) : super(key: key);

  @override
  State<AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends State<AIAssistantSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isAwaitingResponse = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(_ChatMessage(text: text, isUser: true));
        _isAwaitingResponse = true;
      });
      _controller.clear();
      // Placeholder for Gemini/AI integration:
      final aiResponse = await _getAIResponse(text);
      setState(() {
        _messages.add(_ChatMessage(text: aiResponse, isUser: false));
        _isAwaitingResponse = false;
      });
    }
  }

  // Placeholder for Gemini/AI model integration
  Future<String> _getAIResponse(String prompt) async {
    // TODO: Replace this with Gemini API call
    await Future.delayed(const Duration(milliseconds: 800));
    return "(AI) This is a placeholder response for: '$prompt'";
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'ResqTail Guide',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6750A4),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                reverse: true,
                itemCount: _messages.length + (_isAwaitingResponse ? 2 : 1),
                itemBuilder: (context, index) {
                  if (_isAwaitingResponse && index == 0) {
                    // Loading bubble for AI response
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _ChatBubble(
                          text: 'ResqTail Guide is typing...',
                          isUser: false,
                          isLoading: true,
                        ),
                      ),
                    );
                  }
                  final msgIndex = _messages.length -
                      1 -
                      (index - (_isAwaitingResponse ? 1 : 0));
                  if (index ==
                      (_messages.length + (_isAwaitingResponse ? 1 : 0))) {
                    // Initial AI greeting as left bubble
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _ChatBubble(
                          text: 'How can I help you today?',
                          isUser: false,
                        ),
                      ),
                    );
                  }
                  final msg = _messages[msgIndex];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Align(
                      alignment: msg.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: _ChatBubble(
                        text: msg.text,
                        isUser: msg.isUser,
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF6750A4)),
                  onPressed: _isAwaitingResponse ? null : _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isLoading;
  const _ChatBubble(
      {required this.text, required this.isUser, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: EdgeInsets.only(
        left: isUser ? 40 : 0,
        right: isUser ? 0 : 40,
      ),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF6750A4) : const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        isUser ? Colors.white : const Color(0xFF6750A4)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
    );
  }
}
