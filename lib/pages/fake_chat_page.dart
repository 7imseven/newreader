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

  // Sidebar state
  bool _isSidebarOpen = false;

  // Input state
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  // Chat messages (fake)
  final List<_ChatMessage> _messages = [];
  final _scrollController = ScrollController();

  // Animation
  late final AnimationController _animController;
  late final Animation<double> _sidebarAnim;
  late final Animation<double> _overlayAnim;

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
      duration: const Duration(milliseconds: 350),
    );
    _sidebarAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _overlayAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
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
      // Closing: animate first, then remove from tree after animation
      _animController.reverse();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _isSidebarOpen = false);
      });
    } else {
      // Opening: add to tree first, then animate
      setState(() => _isSidebarOpen = true);
      _animController.forward();
    }
  }

  void _onSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (text == _secretPassword) {
      // Success: navigate to MainPage
      context.toReplacement(() => const MainPage());
      return;
    }

    // Wrong password: fake AI error response
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
      ));
      _messages.add(_ChatMessage(
        text: '⚠️ 网络连接错误，请稍后再试。',
        isUser: false,
      ));
      _textController.clear();
    });

    // Auto-scroll to bottom
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

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _attachmentItem(Icons.camera_alt, '相机'),
              _attachmentItem(Icons.photo, '照片'),
              _attachmentItem(Icons.insert_drive_file, '文件'),
              _attachmentItem(Icons.extension, '插件'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentItem(IconData icon, String label) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            child: Icon(icon, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Bottom layer: Main chat view
          _buildMainChat(),

          // Middle layer: Sidebar overlay
          // Always rendered; ignores touches when sidebar is closed
          AnimatedBuilder(
            animation: _overlayAnim,
            builder: (context, child) => IgnorePointer(
              ignoring: !_isSidebarOpen,
              child: GestureDetector(
                onTap: _isSidebarOpen ? _toggleSidebar : null,
                child: Container(
                  color: Colors.black.withOpacity(_overlayAnim.value * 0.3),
                ),
              ),
            ),
          ),

          // Top layer: Sidebar — ignore touches when fully closed
          IgnorePointer(
            ignoring: !_isSidebarOpen,
            child: AnimatedBuilder(
              animation: _sidebarAnim,
              builder: (context, child) {
                final screenWidth = MediaQuery.of(context).size.width;
                return Transform.translate(
                  offset: Offset(-screenWidth * 0.8 * (1.0 - _sidebarAnim.value), 0),
                  child: SizedBox(
                    width: screenWidth * 0.8,
                    child: _buildSidebar(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Main Chat View ──

  Widget _buildMainChat() {
    return AnimatedBuilder(
      animation: _sidebarAnim,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Transform(
          transform: Matrix4.identity()
            ..translate(screenWidth * 0.8 * _sidebarAnim.value)
            ..scale(1.0 - 0.07 * _sidebarAnim.value),
          alignment: Alignment.centerLeft,
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
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _toggleSidebar,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('✨', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text('升级', style: TextStyle(fontSize: 13, color: Colors.purple)),
              ],
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.autorenew),
            onSelected: (_) {},
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'temp', child: Text('临时聊天')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final isFocused = _focusNode.hasFocus;

    return Column(
      children: [
        // Chat messages
        if (_messages.isNotEmpty)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

        // Suggestions (hidden when keyboard is open)
        if (_messages.isEmpty)
          Expanded(
            child: AnimatedOpacity(
              opacity: isFocused ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _suggestionItem(Icons.sports_soccer, '⚽ 关注世界杯'),
                  _suggestionItem(Icons.image, '🖼️ 生成图片'),
                  _suggestionItem(Icons.language, '🌐 查找资料'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _suggestionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(text, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Icon(Icons.arrow_upward, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.auto_awesome, size: 16, color: Colors.green.shade700),
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
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: msg.isUser ? null : const Radius.circular(4),
                  bottomRight: msg.isUser ? const Radius.circular(4) : null,
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 15,
                  color: msg.isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.black87,
                ),
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.person, size: 16, color: Colors.blue.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Plus button
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: Colors.grey.shade600,
              onPressed: _showAttachmentSheet,
            ),
            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _onSend(),
                  decoration: const InputDecoration(
                    hintText: '询问 ChatGPT',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Send / Mic button
            GestureDetector(
              onTap: _hasText ? _onSend : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _hasText ? Colors.blue : Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _hasText ? Icons.arrow_upward : Icons.mic,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sidebar ──

  Widget _buildSidebar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Top: title + search
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                const Text('ChatGPT',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              ],
            ),
          ),
          // Menu items
          ..._buildMenuItems(),
          // Recent title
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text('最近',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
            ),
          ),
          // Recent list
          Expanded(child: _buildRecentList()),
          // Bottom bar
          _buildSidebarBottom(),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final items = [
      _MenuItem(Icons.bookmark_border, '库'),
      _MenuItem(Icons.folder_open, '项目'),
      _MenuItem(Icons.extension, '插件'),
      _MenuItem(Icons.more_horiz, '更多'),
    ];
    return items
        .map((item) => ListTile(
              leading: Icon(item.icon, color: Colors.black87),
              title: Text(item.label,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {},
            ))
        .toList();
  }

  Widget _buildRecentList() {
    final history = [
      '2026世界杯简报',
      'Flutter 动画实现方案',
      'Flutter 项目架构优化',
      'AI 聊天界面开发',
    ];
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: history.length,
      itemBuilder: (context, index) => ListTile(
        dense: true,
        leading: Icon(Icons.chat_bubble_outline,
            size: 20, color: Colors.grey.shade500),
        title: Text(history[index], style: const TextStyle(fontSize: 14)),
        onTap: () {},
      ),
    );
  }

  Widget _buildSidebarBottom() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('✏️', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text('聊天',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
    );
  }
}

// ── Data Models ──

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _MenuItem {
  final IconData icon;
  final String label;

  const _MenuItem(this.icon, this.label);
}
