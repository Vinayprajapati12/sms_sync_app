import 'package:flutter/material.dart';
import '../models/conversation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:telephony/telephony.dart';
import '../services/sms_service.dart';

class ChatScreen extends StatefulWidget {
  final String? startNumber;
  final Conversation? conversation;
  const ChatScreen({this.startNumber, this.conversation, Key? key})
    : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SmsService smsService = SmsService.instance;
  List<SmsMessage> messages = [];

  @override
  void initState() {
    super.initState();
    if (widget.conversation != null)
      messages = List.from(widget.conversation!.messages);
    smsService.onMessage.listen((msg) {
      if (msg.address == widget.startNumber)
        setState(() {
          messages.insert(0, msg);
        });
    });
  }

  Future<void> openComposer(String? to) async {
    final uri = Uri.parse(to == null ? 'sms:' : 'sms:$to');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget buildMessage(SmsMessage m) {
    final time = DateTime.fromMillisecondsSinceEpoch(m.date ?? 0);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.body ?? ''),
            const SizedBox(height: 6),
            Text(
              '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        widget.conversation?.displayName ??
        (widget.startNumber ?? 'New message');
    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => openComposer(widget.startNumber),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, i) => buildMessage(messages[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'To send messages use default SMS app — tap send icon.',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.launch),
                  onPressed: () => openComposer(widget.startNumber),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
