// lib/screens/chatbot_screen.dart
// 🤖 Cooking Assistant powered by Google Gemini API
// ─────────────────────────────────────────────────
// HOW TO ADD YOUR KEY:
//   Find this line below:
//     static const _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
//   Replace YOUR_GEMINI_API_KEY_HERE with your key from
//   https://aistudio.google.com/app/apikey
//   Example:
//     static const _apiKey = 'AIzaSyXXXXXXXXXXXXXXXXXXXXX';
// ─────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

enum _Role { user, assistant }

class _Msg {
  final _Role  role;
  final String content;
  const _Msg({required this.role, required this.content});
}

class ChatbotScreen extends StatefulWidget {
  final Map<String, dynamic>? recipeContext;
  const ChatbotScreen({super.key, this.recipeContext});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Msg>  _msgs    = [];
  bool              _loading = false;

  static const _apiKey = 'AIzaSyBTZF0ExF9RxryqEhNTHC0kfkDEBCFyyF4';

  static const _model = 'gemini-2.0-flash';

  bool get _hasKey => _apiKey.isNotEmpty;


  List<String> get _chips => widget.recipeContext != null
      ? [
    'Walk me through each step',
    'Substitute for butter?',
    'Double the servings',
    'Is it gluten-free?',
    'What wine pairs well?',
  ]
      : [
    'What can I cook with chicken?',
    'Easy 30-minute dinner ideas',
    'Vegetarian high-protein meals',
    'How do I make pasta from scratch?',
    'Tips for crispy roasted vegetables',
  ];

  String get _systemPrompt {
    final buf = StringBuffer()
      ..writeln('You are Chef AI, a warm expert cooking assistant inside a recipe app.')
      ..writeln()
      ..writeln('Your two main jobs:')
      ..writeln('1. RECIPE SUGGESTIONS: When a user describes ingredients, dietary')
      ..writeln('   needs, or time constraints, suggest 2-3 tailored recipes.')
      ..writeln('   For each: name, key ingredients, estimated time, difficulty.')
      ..writeln()
      ..writeln('2. STEP-BY-STEP GUIDANCE: Walk users through cooking clearly.')
      ..writeln('   Number each step. Be precise about temperatures and timings.')
      ..writeln()
      ..writeln('Keep responses concise. Use numbered lists for steps.')
      ..writeln('Bullets for ingredients. Always be warm and encouraging.')
      ..writeln('Never use markdown headers.');

    if (widget.recipeContext != null) {
      final r = widget.recipeContext!;
      buf
        ..writeln()
        ..writeln('CURRENT RECIPE the user is viewing:')
        ..writeln('Name:        ${r['name']       ?? ''}')
        ..writeln('Time:        ${r['time']        ?? ''}')
        ..writeln('Ingredients: ${r['ingredients'] ?? ''}')
        ..writeln('Description: ${r['description'] ?? ''}')
        ..writeln('Steps:       ${r['steps']       ?? ''}');
    }
    return buf.toString();
  }

  void _addWelcome() {
    final hasCtx = widget.recipeContext != null;
    final name   = widget.recipeContext?['name'] ?? '';
    _msgs.add(_Msg(
      role: _Role.assistant,
      content: hasCtx
          ? "Hi! I'm Chef AI 👨‍🍳\n\nI can see you're making **$name**. I can:\n"
          "• Walk you through every step\n"
          "• Suggest ingredient substitutions\n"
          "• Adjust serving sizes\n"
          "• Answer any cooking question\n\nWhat do you need help with?"
          : "Hi! I'm Chef AI 👨‍🍳 — your personal cooking assistant.\n\n"
          "Tell me what ingredients you have and I'll suggest recipes, "
          "or ask me to guide you through any dish step by step.\n\n"
          "What would you like to cook today?",
    ));
  }

  @override
  void initState() {
    super.initState();
    _addWelcome();
  }

  // ── Gemini API call ────────────────────────────────────────────────────────

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (!_hasKey) {
      setState(() {
        _msgs.add(_Msg(
          role: _Role.assistant,
          content: '⚠️ No API key set.\n\n'
              'Open chatbot_screen.dart and replace\n'
              'YOUR_GEMINI_API_KEY_HERE\n'
              'with your key from:\n'
              'https://aistudio.google.com/app/apikey',
        ));
      });
      return;
    }

    setState(() {
      _msgs.add(_Msg(role: _Role.user, content: trimmed));
      _loading = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    try {
      // Build conversation history for Gemini
      final contents = <Map<String, dynamic>>[];

      // Add all previous messages except the first welcome message
      for (int i = 1; i < _msgs.length; i++) {
        final msg = _msgs[i];
        contents.add({
          'role': msg.role == _Role.user ? 'user' : 'model',
          'parts': [{'text': msg.content}],
        });
      }

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [{'text': _systemPrompt}],
          },
          'contents': contents,
          'generationConfig': {
            'temperature':     0.7,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data  = jsonDecode(response.body);
        final reply = data['candidates']?[0]?['content']?['parts']?[0]?['text']
        as String? ?? "Sorry, I couldn't respond.";
        setState(() =>
            _msgs.add(_Msg(role: _Role.assistant, content: reply)));
      } else {
        final err = jsonDecode(response.body);
        final msg = err['error']?['message'] ?? 'Unknown error';
        _addError('Gemini error ${response.statusCode}: $msg');
      }
    } catch (e) {
      _addError('Connection error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _addError(String msg) {
    if (!mounted) return;
    setState(() =>
        _msgs.add(_Msg(role: _Role.assistant, content: '⚠️ $msg')));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chef AI',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(
                  widget.recipeContext != null
                      ? 'Cooking: ${widget.recipeContext!['name'] ?? ''}'
                      : 'Powered by Gemini',
                  style:    const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ]),
        actions: [
          IconButton(
            icon:    const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Clear chat',
            onPressed: () => setState(() {
              _msgs.clear();
              _addWelcome();
            }),
          ),
        ],
      ),
      body: Column(children: [

        // ── No key warning ──────────────────────────────────
        if (!_hasKey)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.orange.shade700,
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gemini API key not set — tap send to see setup instructions.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ]),
          ),

        // ── Messages ────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _msgs.length) return _TypingBubble(theme: theme);
              return _Bubble(msg: _msgs[i], theme: theme, isDark: isDark);
            },
          ),
        ),

        // ── Suggestion chips ────────────────────────────────
        if (_msgs.length == 1)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(_chips[i],
                    style: const TextStyle(fontSize: 12)),
                onPressed: () => _send(_chips[i]),
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                side: BorderSide(
                    color: theme.primaryColor.withOpacity(0.3)),
              ),
            ),
          ),

        const SizedBox(height: 8),

        // ── Input bar ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset:     const Offset(0, -2),
              ),
            ],
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                minLines: 1, maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: widget.recipeContext != null
                      ? 'Ask about this recipe…'
                      : 'What would you like to cook?',
                  hintStyle:
                  TextStyle(color: theme.textTheme.bodySmall?.color),
                  filled:    true,
                  fillColor: isDark
                      ? Colors.grey[800] : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:   BorderSide.none,
                  ),
                ),
                onSubmitted: _loading ? null : _send,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _loading ? null : () => _send(_inputCtrl.text),
              backgroundColor:
              _loading ? Colors.grey : theme.primaryColor,
              elevation: 0,
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final _Msg msg; final ThemeData theme; final bool isDark;
  const _Bubble({required this.msg, required this.theme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == _Role.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor.withOpacity(0.15),
              child: Icon(Icons.smart_toy_outlined,
                  size: 16, color: theme.primaryColor),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.primaryColor
                    : (isDark ? Colors.grey[800] : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withOpacity(0.07),
                    blurRadius: 4,
                    offset:     const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(msg.content,
                  style: TextStyle(
                    color: isUser
                        ? Colors.white
                        : theme.textTheme.bodyMedium?.color,
                    fontSize: 15,
                    height:   1.45,
                  )),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Typing indicator ───────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  final ThemeData theme;
  const _TypingBubble({required this.theme});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: widget.theme.primaryColor.withOpacity(0.15),
          child: Icon(Icons.smart_toy_outlined,
              size: 16, color: widget.theme.primaryColor),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 4,
                  offset: Offset(0, 2)),
            ],
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final t      = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
                final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  8,
                  height: 8 + bounce * 5,
                  decoration: BoxDecoration(
                    color: widget.theme.primaryColor.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ),
      ]),
    );
  }
}