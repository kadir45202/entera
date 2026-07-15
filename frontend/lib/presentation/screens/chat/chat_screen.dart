import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../data/services/gemini_service.dart';
import '../../../core/theme/theme.dart';

/// Chat messages state
final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => []);

/// Chat loading state
final chatLoadingProvider = StateProvider<bool>((ref) => false);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    _controller.clear();

    final userMessage = ChatMessage(role: 'user', content: message);
    ref.read(chatMessagesProvider.notifier).update((state) => [...state, userMessage]);
    _scrollToBottom();

    ref.read(chatLoadingProvider.notifier).state = true;

    try {
      final gemini = ref.read(geminiServiceProvider);
      final history = ref.read(chatMessagesProvider);
      
      final response = await gemini.chat(
        message,
        history: history.take(history.length - 1).toList(),
      );

      final assistantMessage = ChatMessage(role: 'model', content: response);
      ref.read(chatMessagesProvider.notifier).update((state) => [...state, assistantMessage]);
      _scrollToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        role: 'model',
        content: 'Bir hata oluştu. Lütfen tekrar deneyin.',
      );
      ref.read(chatMessagesProvider.notifier).update((state) => [...state, errorMessage]);
    } finally {
      ref.read(chatLoadingProvider.notifier).state = false;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(chatLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Sağlık Asistanı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(chatMessagesProvider.notifier).state = [];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome or messages
          Expanded(
            child: messages.isEmpty
                ? _buildWelcome(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(EnteraShapes.paddingM),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (isLoading && index == messages.length) {
                        return const _TypingIndicator();
                      }
                      return _ChatBubble(message: messages[index]);
                    },
                  ),
          ),

          // Input
          _buildInput(context, isLoading),
        ],
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EnteraShapes.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: EnteraColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety_outlined,
                size: 48,
                color: EnteraColors.primary,
              ),
            ),
            const Gap(24),
            Text(
              'Merhaba! 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Gap(8),
            Text(
              'Bağırsak sağlığı, beslenme ve sindirim hakkında sorularını yanıtlayabilirim.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: EnteraColors.textSecondary,
              ),
            ),
            const Gap(32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _QuickChip(
                  label: 'Sağlıklı beslenme',
                  onTap: () => _sendQuick('Sağlıklı beslenme için önerilerin neler?'),
                ),
                _QuickChip(
                  label: 'Şişkinlik neden olur?',
                  onTap: () => _sendQuick('Şişkinlik neden olur?'),
                ),
                _QuickChip(
                  label: 'Ne kadar su içmeliyim?',
                  onTap: () => _sendQuick('Günde ne kadar su içmeliyim?'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(EnteraShapes.paddingM),
      decoration: BoxDecoration(
        color: EnteraColors.surface,
        border: Border(top: BorderSide(color: EnteraColors.borderLight)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Bir soru sor...',
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !isLoading,
              ),
            ),
            const Gap(8),
            Container(
              decoration: BoxDecoration(
                color: EnteraColors.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: EnteraShadows.fab,
              ),
              child: IconButton(
                onPressed: isLoading ? null : _sendMessage,
                icon: const Icon(Icons.send_rounded),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendQuick(String message) {
    _controller.text = message;
    _sendMessage();
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? EnteraColors.primary : EnteraColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
        ),
        child: Text(
          message.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : EnteraColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: EnteraColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => _Dot(delay: i * 200)),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween(begin: 0.3, end: 1.0).animate(_controller);
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: EnteraColors.textTertiary.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EnteraColors.surfaceAlt,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}
