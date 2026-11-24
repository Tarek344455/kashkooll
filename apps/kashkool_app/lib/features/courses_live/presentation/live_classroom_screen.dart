import 'package:material_ui/material_ui.dart';

class LiveClassroomScreen extends StatefulWidget {
  final String sessionTitle;
  final String teacherName;

  const LiveClassroomScreen({
    super.key,
    this.sessionTitle = 'بث مباشر: مراجعة ليلة الامتحان في التفاضل والتكامل',
    this.teacherName = 'أ. أحمد فؤاد',
  });

  @override
  State<LiveClassroomScreen> createState() => _LiveClassroomScreenState();
}

class _LiveClassroomScreenState extends State<LiveClassroomScreen> {
  bool _handRaised = false;
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'sender': 'كريم حسام', 'text': 'هل المسألة دي تيجي في المقالي يا مستر؟', 'time': '7:14 م'},
    {'sender': 'سارة محمود', 'text': 'ممكن إعادة فكرة التكامل بالتجزيء السريع؟', 'time': '7:15 م'},
    {'sender': 'أحمد فؤاد (المعلم)', 'text': 'تمام يا شباب، هنحل مسألة تطبيقية عليها حالاً!', 'time': '7:16 م'},
  ];

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({
          'sender': 'أنا (طالب)',
          'text': text,
          'time': '${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
        });
        _chatController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.sessionTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('${widget.teacherName} • 185 طالب متصل الآن', style: const TextStyle(fontSize: 11, color: Colors.greenAccent)),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: Icon(
              _handRaised ? Icons.pan_tool : Icons.pan_tool_outlined,
              color: _handRaised ? Colors.amberAccent : Colors.white,
            ),
            tooltip: _handRaised ? 'إنزال اليد' : 'رفع اليد لطلب التحدث',
            onPressed: () {
              setState(() {
                _handRaised = !_handRaised;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_handRaised ? 'تم رفع يدك لطلب السؤال من المعلم' : 'تم إنزال اليد'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Video Container
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.live_tv, size: 54, color: Colors.redAccent),
                      const SizedBox(height: 8),
                      Text(
                        'البث المباشر التفاعلي قيد التشغيل',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'جودة البث: 1080p WebRTC منخفض زمن الوصول (<1s)',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 10),
                        SizedBox(width: 4),
                        Text('مباشر LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Live Chat Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E293B),
            child: const Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.cyanAccent, size: 16),
                SizedBox(width: 8),
                Text('شات الفصل المباشر والأسئلة التفاعلية', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isTeacher = msg['sender']!.contains('المعلم');
                final isMe = msg['sender']!.contains('أنا');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isTeacher
                            ? Colors.cyanAccent.withValues(alpha: 0.2)
                            : (isMe ? const Color(0xFF334155) : const Color(0xFF1E293B)),
                        borderRadius: BorderRadius.circular(8),
                        border: isTeacher ? Border.all(color: Colors.cyanAccent) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                msg['sender']!,
                                style: TextStyle(
                                  color: isTeacher ? Colors.cyanAccent : (isMe ? Colors.white70 : Colors.amberAccent),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(msg['time']!, style: const TextStyle(color: Colors.white38, fontSize: 9)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(msg['text']!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اكتب سؤالك أو استفسارك هنا...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyanAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
