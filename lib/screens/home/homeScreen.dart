import 'dart:convert';

import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';
import 'package:kq/widgets/appBar.dart';

// Home Screen (Dashboard)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAmountVisible = true;
  bool _showBreakdown = true;
  Map<String, dynamic>? _memberData;
  bool _isLoadingData = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadMemberDetails();
  }

  Future<void> _loadMemberDetails() async {
    try {
      final accessToken = await SecureStorageService.getAccessToken();
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      if (accessToken == null || memberNo == null || memberNo.isEmpty) {
        throw Exception('Authentication token or member number missing');
      }

      final response = await ApiService.fetchMemberDetails(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      // 1️⃣ Decode stringified JSON
      final decodedValue = jsonDecode(response['value']);

      // 2️⃣ Extract member object
      final member = decodedValue['values'][0][0];

      setState(() {
        _memberData = member; // ✅ store the actual member object
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString().replaceAll('Exception: ', '');
        _isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = _memberData?['value']?[0];

    if (_isLoadingData) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            height: 70,
            width: 70,
            child: ExpressiveLoadingIndicator(color: Colors.red),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Text(_loadError!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Logo and Notification
            CustomTopBar(),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Profile Icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 28,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Name and Member ID
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _memberData?['name'] ?? '—',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Member ID: ${_memberData?['no'] ?? '—'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_memberData?['designation'] ?? ''} • ${_memberData?['sponsorName'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Arrow Icon to access profile
                          IconButton(
                            onPressed: () {
                              // Navigate to Member Profile
                              print('Navigate to member profile');
                            },
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Total Contributions Card - Prominent
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE31E24), // Kenya Airways red
                            Color(0xFFF44336), // lighter red for vibrancy
                            Color.fromARGB(255, 152, 23, 23), // dark red
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE31E24).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Contributions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              // Eye Icon Toggle
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isAmountVisible = !_isAmountVisible;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _isAmountVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Amount
                          Text(
                            _isAmountVisible ? 'KES 450,000' : '••••••••',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'As of ${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Breakdown Button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showBreakdown = !_showBreakdown;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Amount Breakdown',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFE31E24),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _showBreakdown
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: const Color(0xFFE31E24),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Breakdown Section - Animated
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _showBreakdown
                          ? Column(
                              children: [
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    children: [
                                      _buildContributionCard(
                                        'Employer Contributions',
                                        'Contributions from employer',
                                        'KES 115,000',
                                        Icons.business_outlined,
                                        const Color(0xFFE8F5E9),
                                        const Color(0xFF388E3C),
                                        context,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildContributionCard(
                                        'My Contributions',
                                        'Your personal contributions',
                                        'KES 75,000',
                                        Icons.person_outline,
                                        const Color(0xFFF3E5F5),
                                        const Color(0xFF7B1FA2),
                                        context,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildContributionCard(
                                        'Interest Earned',
                                        'Total interest accumulated',
                                        'KES 30,000',
                                        Icons.trending_up_outlined,
                                        const Color(0xFFFFF3E0),
                                        const Color(0xFFF57C00),
                                        context,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // Yearly Contributions Section
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Yearly Contributions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'This Year',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'KES 130,000',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE31E24),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '6 Contributions',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          // Chart Placeholder
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.show_chart,
                                    size: 48,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Contribution Chart',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFA726),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Contribution',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // View More Button
                    Center(
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        label: const Text(
                          'View More',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                          child: Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 200,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: 3,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 16),
                                  itemBuilder: (context, index) {
                                    final cards = [
                                      OnBoardingCardData(
                                        title: 'Member Profile',
                                        subtitle: 'View & update your info',
                                        imagePath:
                                            'assets/images/memberProfileAction.png',
                                        onTap: () {},
                                      ),
                                      OnBoardingCardData(
                                        title: 'Reports',
                                        subtitle: 'Generate Statements',
                                        imagePath:
                                            'assets/images/reportsAction.png',
                                        onTap: () {},
                                      ),
                                      OnBoardingCardData(
                                        title: 'Inquiries',
                                        subtitle: 'Get to ask anything',
                                        imagePath:
                                            'assets/images/inquiriesAction.png',
                                        onTap: () {},
                                      ),
                                    ];
                                    return SizedBox(
                                      width: 200,
                                      child: _buildQuickActionCard(
                                        title: cards[index].title,
                                        subtitle: cards[index].subtitle,
                                        imagePath: cards[index].imagePath,
                                        onTap: cards[index].onTap,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _buildContributionCard(
    String title,
    String description,
    String amount,
    IconData icon,
    Color bgColor,
    Color iconColor,
    BuildContext context,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
          const Spacer(),
          Text(
            'Amount',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _isAmountVisible ? amount : '••••••••',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE52D27),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'View',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey[800]!, Colors.grey[600]!],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE52D27),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

class OnBoardingCardData {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;

  OnBoardingCardData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });
}
