import 'package:flutter/material.dart';
import 'package:kq/widgets/appBar.dart';

// Enquiries Screen
class EnquiriesScreen extends StatefulWidget {
  const EnquiriesScreen({super.key});

  @override
  State<EnquiriesScreen> createState() => _EnquiriesScreenState();
}

class _EnquiriesScreenState extends State<EnquiriesScreen> {
  String selectedCategory = 'Contributions';
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  @override
  void dispose() {
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enquiries',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.phone,
                            title: 'Call Us',
                            subtitle: '+254712340789',
                            info: 'Mon - Fri, 8am - 5pm',
                            color: const Color(0xFFFFF4E6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.email_outlined,
                            title: 'Email Us',
                            subtitle: 'support@kq.ke',
                            info: 'Response within 24 hours',
                            color: const Color(0xFFFFEEEE),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Enquiry Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_document,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Submit Enquiry',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Select Category',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Category Buttons
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildCategoryButton(
                                'Contributions',
                                Icons.account_balance_wallet,
                              ),
                              _buildCategoryButton(
                                'Statement',
                                Icons.description_outlined,
                              ),
                              _buildCategoryButton(
                                'Profile Info Update',
                                Icons.person_outline,
                              ),
                              _buildCategoryButton(
                                'General Inquiry',
                                Icons.help_outline,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Subject Field
                          const Text(
                            'Subject',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: subjectController,
                            decoration: InputDecoration(
                              hintText: 'Contribution Inquiry',
                              hintStyle: const TextStyle(
                                color: Color(0xFF999999),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Message Field
                          const Text(
                            'Message',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: messageController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'I need details of my last Inquiry',
                              hintStyle: const TextStyle(
                                color: Color(0xFF999999),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle submit
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE31E24),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit Inquiry',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent Enquiries Section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.history, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Recent Enquiries',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Recent Enquiry Items
                    _buildEnquiryItem(
                      title: 'Missing October Contribution',
                      date: 'Nov 10, 2024',
                      status: 'RESOLVED',
                      statusColor: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EnquiryDetailScreen(
                              title: 'Missing October Contribution',
                              date: 'Nov 10, 2024',
                              status: 'RESOLVED',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildEnquiryItem(
                      title: 'Statement Request',
                      date: 'Nov 10, 2024',
                      status: 'IN PROGRESS',
                      statusColor: const Color(0xFFFFA500),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EnquiryDetailScreen(
                              title: 'Statement Request',
                              date: 'Nov 10, 2024',
                              status: 'IN PROGRESS',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildEnquiryItem(
                      title: 'Profile Update Query',
                      date: 'Nov 10, 2024',
                      status: 'RESOLVED',
                      statusColor: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EnquiryDetailScreen(
                              title: 'Profile Update Query',
                              date: 'Nov 10, 2024',
                              status: 'RESOLVED',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String info,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFE31E24), size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info,
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String label, IconData icon) {
    final isSelected = selectedCategory == label;
    return InkWell(
      onTap: () {
        setState(() {
          selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF5F5F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF666666),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryItem({
    required String title,
    required String date,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}

// Enquiry Detail Screen
class EnquiryDetailScreen extends StatefulWidget {
  final String title;
  final String date;
  final String status;

  const EnquiryDetailScreen({
    super.key,
    required this.title,
    required this.date,
    required this.status,
  });

  @override
  State<EnquiryDetailScreen> createState() => _EnquiryDetailScreenState();
}

class _EnquiryDetailScreenState extends State<EnquiryDetailScreen> {
  final TextEditingController messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Back',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Message
                  _buildChatBubble(
                    message: "Hi, I can't see my October contribution.",
                    time: 'Nov 10, 2024',
                    isUser: true,
                  ),
                  const SizedBox(height: 16),

                  // Support Response
                  _buildChatBubble(
                    message:
                        "Thank you for reaching out. Let me check that for you.\n\nPlease give me a moment while we review your contribution records.",
                    time: 'Nov 10, 2024',
                    isUser: false,
                  ),
                  const SizedBox(height: 16),

                  // Confirmation
                  _buildChatBubble(
                    message: "Okay, sure.",
                    time: 'Nov 10, 2024',
                    isUser: true,
                  ),
                  const SizedBox(height: 16),

                  // Final Response
                  _buildChatBubble(
                    message:
                        "We've received your request. Our team will update you once the October contribution is verified.",
                    time: 'Nov 10, 2024',
                    isUser: false,
                  ),
                  const SizedBox(height: 16),

                  // Thank You
                  _buildChatBubble(
                    message: "Thank You",
                    time: 'Nov 10, 2024',
                    isUser: true,
                  ),
                ],
              ),
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Write your message',
                      hintStyle: const TextStyle(color: Color(0xFF999999)),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {
                      // Handle send message
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble({
    required String message,
    required String time,
    required bool isUser,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE31E24),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFFE31E24) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: isUser ? 0 : 36),
            child: Text(
              time,
              style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
            ),
          ),
        ],
      ),
    );
  }
}
