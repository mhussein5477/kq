import 'dart:convert';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:kq/screens/auth/login.dart';
import 'package:kq/screens/home/enquiriesScreen.dart';
import 'package:kq/screens/home/profile.dart';
import 'package:kq/screens/home/reportScreen.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/pdfParserService.dart';
import 'package:kq/services/secure_storage_service.dart';
import 'package:kq/services/interceptor.dart'; 
import 'package:kq/widgets/appBar.dart';
import 'package:intl/intl.dart';

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
  bool _isLoadingContributions = true;
  String? _loadError;

  // Contribution data from PDF parser
  double _totalContributions = 0.0;
  double _employerContributions = 0.0;
  double _memberContributions = 0.0;
  double _interestEarned = 0.0;
  double _avcContributions = 0.0;
  double _prmfContributions = 0.0;
  double _nssfContributions = 0.0;
  double _yearlyContributions = 0.0;
  int _contributionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMemberDetails();
    _loadContributionDataFromPdf();
  }

  Future<void> _loadMemberDetails() async {
    try {
      await ApiTokenInterceptor.getValidTokenOrThrow();

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

      final decodedValue = jsonDecode(response['value']);
      final values = decodedValue['values'] as List;
      
      if (values.isEmpty || values[0].isEmpty) {
        throw Exception('No member data found');
      }
      
      final member = values[0][0] as Map<String, dynamic>;

      setState(() {
        _memberData = member;
        _isLoadingData = false;
      });
    } on TokenExpiredException catch (e) {
      print('Token expired: $e');
      if (mounted) {
        _handleTokenExpired();
      }
    } catch (e) {
      print('❌ ERROR loading member details: $e');
      setState(() {
        _loadError = e.toString().replaceAll('Exception: ', '');
        _isLoadingData = false;
      });
    }
  }

  Future<void> _loadContributionDataFromPdf() async {
    try {
      print('📊 Loading contribution data from PDF...');
      
      await ApiTokenInterceptor.getValidTokenOrThrow();

      final accessToken = await SecureStorageService.getAccessToken();
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      if (accessToken == null || memberNo == null || memberNo.isEmpty) {
        throw Exception('Authentication token or member number missing');
      }

      final dateFormat = DateFormat('yyyy-MM-dd');
      final startDate = '2020-01-01';
      final endDate = dateFormat.format(DateTime.now());

      print('📄 Fetching member statement PDF...');
      final memberStatementPdf = await ApiService.generateMemberStatement(
        accessToken: accessToken,
        memberNo: memberNo,
        startDate: startDate,
        endDate: endDate,
      );

      print('🔍 Parsing member statement PDF...');
      final contributionData = PdfParserService.parseMemberStatementPdf(
        memberStatementPdf,
      );

      print('📄 Fetching contribution statement PDF...');
      final contributionStatementPdf = await ApiService.generateContributionStatement(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      print('🔍 Parsing contribution statement PDF...');
      final yearlyData = PdfParserService.parseContributionStatementPdf(
        contributionStatementPdf,
      );

      if (mounted) {
        setState(() {
          _employerContributions = contributionData['employerContributions'] ?? 0.0;
          _memberContributions = contributionData['memberContributions'] ?? 0.0;
          _interestEarned = contributionData['interestEarned'] ?? 0.0;
          _avcContributions = contributionData['avcContributions'] ?? 0.0;
          _prmfContributions = contributionData['prmfContributions'] ?? 0.0;
          _nssfContributions = contributionData['nssfContributions'] ?? 0.0;
          _totalContributions = contributionData['totalContributions'] ?? 0.0;
          _yearlyContributions = yearlyData['grandTotal'] ?? 0.0;
          _contributionCount = yearlyData['contributionCount'] ?? 0;
          _isLoadingContributions = false;
        });
      }

      print('✅ Contribution data loaded successfully!');
    } on TokenExpiredException catch (e) {
      print('❌ Token expired while loading contributions: $e');
      if (mounted) {
        _handleTokenExpired();
      }
    } catch (e) {
      print('⚠️ Could not load contribution data from PDF: $e');
      if (mounted) {
        setState(() {
          _isLoadingContributions = false;
        });
      }
    }
  }

  void _handleTokenExpired() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Text(
              'Session Expired',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Your session has expired. Please login again to continue.',
          style: TextStyle(
            fontSize: 15,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
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
              backgroundColor: const Color(0xFFE31E24),
              foregroundColor: Colors.white,
            ),
            child: const Text('Login Again'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'KES ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
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
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _loadError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoadingData = true;
                    _loadError = null;
                  });
                  _loadMemberDetails();
                  _loadContributionDataFromPdf();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            CustomTopBar(),
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
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 28,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _memberData?['name'] ?? '—',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Member ID: ${_memberData?['no'] ?? '—'}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_memberData?['designation'] ?? ''} • ${_memberData?['sponsorName'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[500] : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Total Contributions Card
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE31E24),
                                Color(0xFFF44336),
                                Color.fromARGB(255, 152, 23, 23),
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
                                    'Total Pension Balance',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
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
                              Text(
                                _isAmountVisible 
                                    ? _formatCurrency(_totalContributions)
                                    : '••••••••',
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
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showBreakdown = !_showBreakdown;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'View Breakdown',
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
                        if (_isLoadingContributions)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      height: 30,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Loading contribution data...',
                                      style: TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Breakdown Section - Main Categories
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _showBreakdown
                          ? Column(
                              children: [
                                const SizedBox(height: 16),
                                
                                // Main 3 categories
                                SizedBox(
                                  height: 180,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 1),
                                    children: [
                                      _buildContributionCard(
                                        'Employer Contributions',
                                        'Total from Kenya Airways',
                                        _formatCurrency(_employerContributions),
                                        Icons.business_outlined,
                                        const Color(0xFFE8F5E9),
                                        const Color(0xFF388E3C),
                                        context,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildContributionCard(
                                        'My Contributions',
                                        'Your total contributions',
                                        _formatCurrency(_memberContributions),
                                        Icons.person_outline,
                                        const Color(0xFFF3E5F5),
                                        const Color(0xFF7B1FA2),
                                        context,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildContributionCard(
                                        'Interest Earned',
                                        'Total interest accumulated',
                                        _formatCurrency(_interestEarned),
                                        Icons.trending_up_outlined,
                                        const Color(0xFFFFF3E0),
                                        const Color(0xFFF57C00),
                                        context,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Detailed Breakdown Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  child: Text(
                                    'Special Contributions',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ),
                                
                                // Special contribution types in a row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSmallContributionCard(
                                        'AVC',
                                        _formatCurrency(_avcContributions),
                                        Icons.savings_outlined,
                                        const Color(0xFF2196F3),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSmallContributionCard(
                                        'PRMF',
                                        _formatCurrency(_prmfContributions),
                                        Icons.shield_outlined,
                                        const Color(0xFFFF9800),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSmallContributionCard(
                                        'NSSF Tier II',
                                        _formatCurrency(_nssfContributions),
                                        Icons.verified_user_outlined,
                                        const Color(0xFF00BCD4),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // This Year's Contributions
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'This Year\'s Contributions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${DateTime.now().year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _formatCurrency(_yearlyContributions),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE31E24),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_contributionCount ${_contributionCount == 1 ? 'Month' : 'Months'} with contributions',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey,
                            ),
                          ),
                        ],
                      ),
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black87,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              height: 1.3,
            ),
          ),
          const Spacer(),
          Text(
            'Amount',
            style: TextStyle(
              fontSize: 11,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _isAmountVisible ? amount : '••••••••',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ), 

        ],
      ),
    );
  }

  Widget _buildSmallContributionCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isAmountVisible ? amount : '••••••',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}