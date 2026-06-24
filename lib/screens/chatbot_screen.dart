import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import 'dart:async';
import 'package:fixoo_partner/services/jini_service.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Neural link established! 🧠✨\n\nNamaste Master! I am Jini, your AI-powered companion. I am currently learning your preferences to serve you better. What is your command today?',
      'isBot': true,
      'time': DateTime.now(),
    },
  ];
  bool _isTyping = false;
  bool _isThinking = false;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add({
        'text': userMessage,
        'isBot': false,
        'time': DateTime.now(),
      });
      _messageController.clear();
      _isThinking = true;
    });

    _scrollToBottom();

    // REAL Gemini AI Neural Thinking
    try {
      final aiResponse = await JiniService.getJiniResponse(userMessage);
      
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _isTyping = true;
      });
      
      // Short delay for natural feel
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'text': aiResponse,
          'isBot': true,
          'time': DateTime.now(),
        });
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _isTyping = false;
        _messages.add({
          'text': "Master, something went wrong in my magic. Check your internet or API key!",
          'isBot': true,
          'time': DateTime.now(),
        });
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D1FF).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00D1FF).withValues(alpha: 0.3), width: 1),
                  ),
                  child: Image.asset('assets/images/genie_icon.png', width: 32, height: 32),
                ),
                if (_isThinking)
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF0FF4C6).withValues(alpha: 0.5)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jini AI', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0FF4C6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('NEURAL LINK ACTIVE', style: TextStyle(color: Color(0xFF0FF4C6), fontSize: 8, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: _glow(const Color(0xFF00D1FF), 0.05, 300)),
          Positioned(bottom: -100, left: -50, child: _glow(const Color(0xFF7B61FF), 0.03, 300)),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg['text'], msg['isBot'], msg['time']);
                  },
                ),
              ),
              if (_isThinking)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 15),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.brainCircuit, color: Color(0xFF00D1FF), size: 16),
                      const SizedBox(width: 10),
                      Text('Jini is thinking...', style: TextStyle(color: const Color(0xFF00D1FF).withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Row(
                    children: [
                      Text('Jini is typing', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                      const SizedBox(width: 8),
                      const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D1FF))),
                    ],
                  ),
                ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isBot, DateTime time) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isBot ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF00D1FF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isBot ? 4 : 20),
            bottomRight: Radius.circular(isBot ? 20 : 4),
          ),
          border: isBot ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: isBot ? Colors.white : Colors.black, fontSize: 15, fontWeight: isBot ? FontWeight.w500 : FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: (isBot ? Colors.white : Colors.black).withValues(alpha: 0.4), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).padding.bottom + 10, top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF030712),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFF00D1FF), shape: BoxShape.circle),
              child: const Icon(LucideIcons.send, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double opacity, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox.expand()),
    );
  }
}
