import 'package:flutter/material.dart';
import 'package:kq/screens/auth/login.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';
import 'package:kq/widgets/appBar.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:kq/services/interceptor.dart';

// ============================================================================
// UTILITIES & CONSTANTS
// ============================================================================

class AppColors {
  // Primary
  static const primary = Color(0xFFE31E24);
  static const primaryDark = Color(0xFFB31118);

  // Status Colors
  static const statusResolved = Color(0xFF10B981);
  static const statusInProgress = Color(0xFFFFA500);
  static const statusOpen = Color(0xFF3B82F6);

  // Category
  static const categorySelected = Color(0xFF7C3AED);

  // Text
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textTertiary = Color(0xFF999999);

  // Background
  static const backgroundLight = Color(0xFFF5F5F8);
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const surfaceDarker = Color(0xFF2A2A2A);
}

class StatusUtils {
  static Color getStatusColor(String status) {
    final statusLower = status.toLowerCase().trim();

    if (_isResolved(statusLower)) return AppColors.statusResolved;
    if (_isInProgress(statusLower)) return AppColors.statusInProgress;
    return AppColors.statusOpen;
  }

  static String formatStatus(String status) {
    return status.isEmpty || status == ' ' ? 'OPEN' : status.toUpperCase();
  }

  static bool _isResolved(String status) =>
      status.contains('resolved') ||
      status.contains('closed') ||
      status == 'closed';

  static bool _isInProgress(String status) =>
      status.contains('progress') ||
      status.contains('pending') ||
      status == 'in progress';
}

// ============================================================================
// TOKEN EXPIRATION MIXIN
// ============================================================================

mixin TokenExpiredHandler {
  BuildContext get context;

  void handleTokenExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Session Expired'),
          ],
        ),
        content: const Text(
          'Your session has expired. Please login again to continue.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await SecureStorageService.clearAuth();
              if (context.mounted) {
                Navigator.of(context).pop();
               Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login Again'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ENQUIRIES SCREEN
// ============================================================================

class EnquiriesScreen extends StatefulWidget {
  const EnquiriesScreen({super.key});

  @override
  State<EnquiriesScreen> createState() => _EnquiriesScreenState();
}

class _EnquiriesScreenState extends State<EnquiriesScreen>
    with TokenExpiredHandler {
  String selectedCategory = 'Enquiry';
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isLoading = false;
  bool isSubmitting = false;
  List<Map<String, dynamic>> interactions = [];
  String? memberNo;
  String? accessToken;

  final Map<String, String> categoryTypes = {
    'Enquiry': 'Enquiry',
    'Complaint': 'Complaint',
    'Feedback': 'Feedback',
    'General Inquiry': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      await ApiTokenInterceptor.getValidTokenOrThrow();

      final memberDetails = await SecureStorageService.getMemberDetails();
      final token = await SecureStorageService.getAccessToken();

      memberNo = memberDetails['memberNo'];
      accessToken = token;

      if (memberNo != null && accessToken != null) {
        await _fetchInteractions();
      }
    } on TokenExpiredException catch (e) {
      print('Token expired: $e');
      if (mounted) {
        handleTokenExpired();
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchInteractions() async {
    if (accessToken == null || memberNo == null) return;

    try {
      final result = await ApiService.fetchInteractions(
        accessToken: accessToken!,
        memberNo: memberNo,
        includeComments: false,
      );

      setState(() {
        interactions = result;
      });

      print('📋 Loaded ${interactions.length} interactions');
    } catch (e) {
      print('Error fetching interactions: $e');
    }
  }

  Future<void> _submitEnquiry() async {
    if (subjectController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (accessToken == null || memberNo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await ApiTokenInterceptor.getValidTokenOrThrow();

      final result = await ApiService.createInteraction(
        accessToken: accessToken!,
        memberNo: memberNo!,
        type: categoryTypes[selectedCategory] ?? 'Enquiry',
        subject: subjectController.text.trim(),
        description: messageController.text.trim(),
        clientType: 'Member',
      );

      print('✅ Enquiry submitted: $result');

      subjectController.clear();
      messageController.clear();

      await _fetchInteractions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enquiry submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on TokenExpiredException catch (e) {
      print('Token expired during submit: $e');
      if (mounted) {
        handleTokenExpired();
      }
    } catch (e) {
      print('Error submitting enquiry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    subjectController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enquiries',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSubmitEnquirySection(isDarkMode),
                      const SizedBox(height: 24),
                      _buildRecentEnquiriesHeader(isDarkMode),
                      const SizedBox(height: 16),
                      _buildEnquiriesList(isDarkMode, theme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitEnquirySection(bool isDarkMode) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                  color: AppColors.backgroundLight.withOpacity(isDarkMode ? 0.1 : 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_document,
                  size: 20,
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Submit Enquiry',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Select Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryButton('Enquiry', Icons.help_outline, isDarkMode),
              _buildCategoryButton('Complaint', Icons.error_outline, isDarkMode),
              _buildCategoryButton('Feedback', Icons.feedback_outlined, isDarkMode),
              _buildCategoryButton(
                  'General Inquiry', Icons.question_answer_outlined, isDarkMode),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextFieldLabel('Subject', isDarkMode),
          const SizedBox(height: 8),
          _buildTextField(
            controller: subjectController,
            hintText: 'Enter enquiry subject',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 16),
          _buildTextFieldLabel('Message', isDarkMode),
          const SizedBox(height: 8),
          _buildTextField(
            controller: messageController,
            hintText: 'Describe your enquiry in detail',
            maxLines: 4,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submitEnquiry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: ExpressiveLoadingIndicator(color: Colors.white),
                    )
                  : const Row(
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
    );
  }

  Widget _buildRecentEnquiriesHeader(bool isDarkMode) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.history,
            size: 20,
            color: isDarkMode ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Recent Enquiries',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEnquiriesList(bool isDarkMode, ThemeData theme) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ExpressiveLoadingIndicator(
            color: isDarkMode ? Colors.red[300] : Colors.red,
          ),
        ),
      );
    }

    if (interactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: isDarkMode ? Colors.white24 : AppColors.textTertiary,
              ),
              const SizedBox(height: 12),
              Text(
                'No enquiries yet',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: interactions.map((interaction) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildEnquiryItem(interaction, isDarkMode, theme),
        );
      }).toList(),
    );
  }

  Widget _buildEnquiryItem(
    Map<String, dynamic> interaction,
    bool isDarkMode,
    ThemeData theme,
  ) {
    final message = interaction['message'] ?? 'No Message';
    final type = interaction['type']?.toString().trim() ?? 'Enquiry';
    final status = interaction['status']?.toString().trim() ?? 'Open';
    final dateRaised = interaction['dateRaised'] ?? 'Unknown Date';

    final statusColor = StatusUtils.getStatusColor(status);
    final displayType = type.isEmpty || type == ' ' ? 'Enquiry' : type;
    final displayStatus = StatusUtils.formatStatus(status);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnquiryDetailScreen(
              interaction: interaction,
              accessToken: accessToken,
            ),
          ),
        ).then((_) => _fetchInteractions());
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                          displayStatus,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight
                              .withOpacity(isDarkMode ? 0.1 : 1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayType,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateRaised,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white54 : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white24 : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(
    String label,
    IconData icon,
    bool isDarkMode,
  ) {
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
          color: isSelected
              ? AppColors.categorySelected
              : AppColors.backgroundLight.withOpacity(isDarkMode ? 0.1 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.white70 : AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDarkMode ? Colors.white70 : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldLabel(String label, bool isDarkMode) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    required bool isDarkMode,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.white54 : AppColors.textTertiary,
        ),
        filled: true,
        fillColor: isDarkMode
            ? AppColors.surfaceDarker
            : AppColors.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: TextStyle(
        color: isDarkMode ? Colors.white : AppColors.textPrimary,
      ),
    );
  }
}

// ============================================================================
// ENQUIRY DETAIL SCREEN
// ============================================================================

class EnquiryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> interaction;
  final String? accessToken;

  const EnquiryDetailScreen({
    super.key,
    required this.interaction,
    this.accessToken,
  });

  @override
  State<EnquiryDetailScreen> createState() => _EnquiryDetailScreenState();
}

class _EnquiryDetailScreenState extends State<EnquiryDetailScreen>
    with TokenExpiredHandler {
  final TextEditingController messageController = TextEditingController();
  List<Map<String, dynamic>> comments = [];
  bool isLoading = false;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    if (widget.accessToken == null) return;

    setState(() => isLoading = true);

    try {
      await ApiTokenInterceptor.getValidTokenOrThrow();

      final interactionId = widget.interaction['id'] ??
          widget.interaction['no'] ??
          widget.interaction['interactionId'];

      if (interactionId == null) {
        print('⚠️ No interaction ID found');
        return;
      }

      final result = await ApiService.fetchInteractionComments(
        accessToken: widget.accessToken!,
        interactionId: interactionId.toString(),
      );

      setState(() {
        comments = result;
      });

      print('💬 Loaded ${comments.length} comments');
    } on TokenExpiredException catch (e) {
      print('Token expired: $e');
      if (mounted) {
        handleTokenExpired();
      }
    } catch (e) {
      print('Error loading comments: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendComment() async {
    if (messageController.text.trim().isEmpty) return;
    if (widget.accessToken == null) return;

    setState(() => isSending = true);

    try {
      await ApiTokenInterceptor.getValidTokenOrThrow();

      final interactionId = widget.interaction['id'] ??
          widget.interaction['no'] ??
          widget.interaction['interactionId'];

      if (interactionId == null) {
        throw Exception('No interaction ID found');
      }

      final success = await ApiService.addInteractionComment(
        accessToken: widget.accessToken!,
        interactionId: interactionId.toString(),
        comment: messageController.text.trim(),
      );

      if (success) {
        messageController.clear();
        await _loadComments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on TokenExpiredException catch (e) {
      print('Token expired: $e');
      if (mounted) {
        handleTokenExpired();
      }
    } catch (e) {
      print('Error sending comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      setState(() => isSending = false);
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final message = widget.interaction['message'] ?? 'No Message';
    final status = widget.interaction['status']?.toString().trim() ?? 'Open';
    final dateRaised = widget.interaction['dateRaised'] ?? '';
    final clientName = widget.interaction['clientName'] ?? '';

    final statusColor = StatusUtils.getStatusColor(status);
    final displayStatus = StatusUtils.formatStatus(status);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDarkMode ? Colors.white : AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Back',
          style: TextStyle(
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (clientName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: isDarkMode ? Colors.white54 : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          clientName,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (dateRaised.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isDarkMode ? Colors.white54 : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateRaised,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildCommentsSection(isDarkMode, theme),
                ],
              ),
            ),
          ),
          _buildMessageInput(isDarkMode, theme),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(bool isDarkMode, ThemeData theme) {
    if (isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ExpressiveLoadingIndicator(
            color: isDarkMode ? Colors.red[300] : Colors.red,
          ),
        ),
      );
    }

    if (comments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No comments yet',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white54 : AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: comments.map((comment) {
        final commentText = comment['comment'] ?? '';
        final commentDate =
            comment['createdAt'] ?? comment['dateCreated'] ?? 'Unknown Date';
        final isSupport =
            comment['isAdminComment'] == true || comment['userId'] != null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildChatBubble(
            message: commentText,
            time: commentDate,
            isUser: !isSupport,
            isDarkMode: isDarkMode,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageInput(bool isDarkMode, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000).withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              enabled: !isSending,
              decoration: InputDecoration(
                hintText: 'Write your message',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : AppColors.textTertiary,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? AppColors.surfaceDarker
                    : AppColors.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: ExpressiveLoadingIndicator(
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: isSending ? null : _sendComment,
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
    required bool isDarkMode,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
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
              color: isUser
                  ? AppColors.primary
                  : (isDarkMode ? AppColors.surfaceDarker : Colors.white),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isUser
                    ? Colors.white
                    : (isDarkMode ? Colors.white : AppColors.textPrimary),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: isUser ? 0 : 36),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.white54 : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}