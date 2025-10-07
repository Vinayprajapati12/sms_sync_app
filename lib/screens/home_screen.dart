import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import '../models/conversation.dart';
import '../services/sms_service.dart';
import '../widgets/conversation_card.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SmsService smsService = SmsService.instance;
  List<Conversation> conversations = [];
  String query = '';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    initAll();
    smsService.onMessage.listen((msg) => refreshConversations());
  }

  Future<void> initAll() async {
    await smsService.init();
    await refreshConversations();
  }

  Future<void> refreshConversations() async {
    final inbox = await smsService.fetchInbox();
    final Map<String, List<SmsMessage>> grouped = {};

    for (var m in inbox) {
      final address = m.address ?? 'unknown';
      grouped.putIfAbsent(address, () => []).add(m);
    }

    final List<Conversation> convs = [];
    grouped.forEach((address, msgs) {
      msgs.sort((a, b) => (b.date ?? 0).compareTo(a.date ?? 0));
      final last = msgs.first;
      final name = smsService.lookupName(address);
      convs.add(
        Conversation(
          address: address,
          displayName: name,
          snippet: last.body ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(last.date ?? 0),
          messages: msgs,
        ),
      );
    });

    convs.sort((a, b) => b.date.compareTo(a.date));
    if (mounted) setState(() => conversations = convs);
  }

  List<Conversation> get filtered => query.isEmpty
      ? conversations
      : conversations
            .where(
              (c) =>
                  c.displayName.toLowerCase().contains(query.toLowerCase()) ||
                  c.snippet.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(startNumber: null),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search messages or contacts',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                    setState(() => query = '');
                  },
                ),
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshConversations,
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) => ConversationCard(
                  conversation: filtered[i],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          startNumber: filtered[i].address,
                          conversation: filtered[i],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
