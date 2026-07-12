import 'dart:async';

import 'package:flutter/material.dart';
import 'package:venera/foundation/context.dart';
import 'package:venera/pages/main_page.dart';

class FakeChatPage extends StatefulWidget {
  const FakeChatPage({super.key});

  @override
  State<FakeChatPage> createState() => _FakeChatPageState();
}

class _FakeChatPageState extends State<FakeChatPage>
    with SingleTickerProviderStateMixin {
  static const _secretPassword = '8012';

  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  late final AnimationController _animController;
  late final Animation<double> _sidebarAnim;
  late final Animation<double> _overlayAnim;

  bool _isSidebarOpen = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final hasText = _textController.text.isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _focusNode.addListener(() => setState(() {}));

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sidebarAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _overlayAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    if (_isSidebarOpen) {
      _animController.reverse();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _isSidebarOpen = false);
      });
    } else {
      setState(() => _isSidebarOpen = true);
      _animController.forward();
    }
  }

  void _onSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (text == _secretPassword) {
      context.toReplacement(() => const MainPage());
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messages.add(const _ChatMessage(
        text: 'Network error, please try again later.',
        isUser: false,
      ));
      _textController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMainChat(),
          AnimatedBuilder(
            animation: _overlayAnim,
            builder: (context, _) => IgnorePointer(
              ignoring: !_isSidebarOpen,
              child: GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  color: Colors.black.withOpacity(_overlayAnim.value * 0.25),
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: !_isSidebarOpen,
            child: AnimatedBuilder(
              animation: _sidebarAnim,
              builder: (context, _) {
                final w = MediaQuery.of(context).size.width;
                return Transform.translate(
                  offset: Offset(-w * 0.8 * (1 - _sidebarAnim.value), 0),
                  child: SizedBox(width: w * 0.8, child: _buildSidebar()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChat() {
    return AnimatedBuilder(
      animation: _sidebarAnim,
      builder: (context, child) {
        final w = MediaQuery.of(context).size.width;
        return Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.identity()
            ..translate(w * 0.8 * _sidebarAnim.value)
            ..scale(1.0 - 0.07 * _sidebarAnim.value),
          child: child,
        );
      },
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _buildContent()),
          _buildBottomInput(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 4,
        right: 4,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.menu), onPressed: _toggleSidebar),
          const SizedBox(width: 4),
          const Text('ChatGPT',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: Text('New chat')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final focused = _focusNode.hasFocus;
    if (_messages.isNotEmpty) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
      );
    }

    return AnimatedOpacity(
      opacity: focused ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('Enter 8012 to unlock the main app'),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.auto_awesome,
                  size: 16, color: Colors.green.shade700),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(msg.text),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue.shade100,
              child:
                  Icon(Icons.person, size: 16, color: Colors.blue.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _onSend(),
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: Icon(_hasText ? Icons.send : Icons.mic),
              onPressed: _hasText ? _onSend : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 16),
          const ListTile(title: Text('Recent chats')),
          const Divider(height: 1),
          const Expanded(
            child: Center(child: Text('Sidebar placeholder')),
          ),
          SafeArea(
            top: false,
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}
