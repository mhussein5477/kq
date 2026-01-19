import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kq/services/pdfParserService.dart';
import 'package:kq/widgets/appBar.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';
import 'package:kq/services/interceptor.dart'; 
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:intl/intl.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  bool _isLoadingData = true;
  bool _isLoadingContributions = true;
  String? _loadError;
  Map<String, dynamic>? _memberData;

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
    _loadTrendsData();
  }

  Future<void> _loadTrendsData() async {
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

      _loadContributionDataFromPdf(accessToken, memberNo);
    } catch (e) {
      print('❌ TRENDS - ERROR: $e');
      setState(() {
        _loadError = e.toString().replaceAll('Exception: ', '');
        _isLoadingData = false;
        _isLoadingContributions = false;
      });
    }
  }

  Future<void> _loadContributionDataFromPdf(String accessToken, String memberNo) async {
    try {
      print('📊 TRENDS - Loading contribution data from PDF...');

      final dateFormat = DateFormat('yyyy-MM-dd');
      final startDate = '2020-01-01';
      final endDate = dateFormat.format(DateTime.now());

      final memberStatementPdf = await ApiService.generateMemberStatement(
        accessToken: accessToken,
        memberNo: memberNo,
        startDate: startDate,
        endDate: endDate,
      );

      final contributionData = PdfParserService.parseMemberStatementPdf(
        memberStatementPdf,
      );

      final contributionStatementPdf = await ApiService.generateContributionStatement(
        accessToken: accessToken,
        memberNo: memberNo,
      );

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

      print('✅ TRENDS - Contribution data loaded successfully!');
    } catch (e) {
      print('⚠️ TRENDS - Could not load contribution data: $e');
      if (mounted) {
        setState(() {
          _isLoadingContributions = false;
        });
      }
    }
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
        body: SafeArea(
          child: Column(
            children: [
              CustomTopBar(),
              Expanded(
                child: Center(
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
                            _isLoadingContributions = true;
                            _loadError = null;
                          });
                          _loadTrendsData();
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pension Trends',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    if (_isLoadingContributions)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode 
                              ? const Color(0xFF1E3A4F) 
                              : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDarkMode ? Colors.blue[300] : Colors.blue[900],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Loading pension data...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode ? Colors.blue[200] : Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (_isLoadingContributions) const SizedBox(height: 20),
                    
                    _buildQuickStatsGrid(),
                    const SizedBox(height: 24),
                    _buildContributionCompositionCard(),
                    const SizedBox(height: 24),
                    _buildDetailedBreakdownCard(),
                    const SizedBox(height: 24),
                    _buildThisYearCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Balance',
          _formatCurrency(_totalContributions),
          Icons.account_balance_wallet_outlined,
          const Color(0xFFE31E24),
        ),
        _buildStatCard(
          'My Contributions',
          _formatCurrency(_memberContributions),
          Icons.person_outline,
          const Color(0xFF9C27B0),
        ),
        _buildStatCard(
          'Employer Contributions',
          _formatCurrency(_employerContributions),
          Icons.business_outlined,
          const Color(0xFF4CAF50),
        ),
        _buildStatCard(
          'Interest',
          _formatCurrency(_interestEarned),
          Icons.trending_up,
          const Color(0xFFFF9800),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String amount,
    IconData icon,
    Color iconColor,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
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
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionCompositionCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    // Calculate percentages
    final total = _totalContributions > 0 ? _totalContributions : 1;
    final employerPercentage = (_employerContributions / total) * 100;
    final employeePercentage = (_memberContributions / total) * 100;
    final interestPercentage = (_interestEarned / total) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Composition',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(_totalContributions),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE31E24),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: CustomPaint(
                        painter: DonutChartPainter(
                          employerPercentage: employerPercentage,
                          employeePercentage: employeePercentage,
                          interestPercentage: interestPercentage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      'Employer',
                      const Color(0xFF4CAF50),
                      '${employerPercentage.toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'Employee',
                      const Color(0xFF9C27B0),
                      '${employeePercentage.toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      'Interest',
                      const Color(0xFFFF9800),
                      '${interestPercentage.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedBreakdownCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
          Text(
            'Contribution Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildBreakdownItem(
            'Employer Contributions',
            _formatCurrency(_employerContributions),
            Icons.business_center_outlined,
            const Color(0xFF4CAF50),
          ),
          Divider(
            height: 24,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          _buildBreakdownItem(
            'Member Contributions',
            _formatCurrency(_memberContributions),
            Icons.account_circle_outlined,
            const Color(0xFF9C27B0),
          ),
          Divider(
            height: 24,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          _buildBreakdownItem(
            'Additional Voluntary Contributions (AVC)',
            _formatCurrency(_avcContributions),
            Icons.savings_outlined,
            const Color(0xFF2196F3),
          ),
          Divider(
            height: 24,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          _buildBreakdownItem(
            'PRMF Contributions',
            _formatCurrency(_prmfContributions),
            Icons.shield_outlined,
            const Color(0xFFFF9800),
          ),
          Divider(
            height: 24,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          _buildBreakdownItem(
            'NSSF Tier II Contributions',
            _formatCurrency(_nssfContributions),
            Icons.verified_user_outlined,
            const Color(0xFF00BCD4),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThisYearCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                  borderRadius: BorderRadius.circular(8),
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
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE31E24),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_contributionCount ${_contributionCount == 1 ? 'month' : 'months'} with contributions',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'View Reports for detailed monthly breakdown',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double employerPercentage;
  final double employeePercentage;
  final double interestPercentage;

  DonutChartPainter({
    required this.employerPercentage,
    required this.employeePercentage,
    required this.interestPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 25.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final employerAngle = (employerPercentage / 100) * 6.283185307179586;
    final employeeAngle = (employeePercentage / 100) * 6.283185307179586;
    final interestAngle = (interestPercentage / 100) * 6.283185307179586;

    double startAngle = -1.57;

    // Employer (Green)
    paint.color = const Color(0xFF4CAF50);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      employerAngle,
      false,
      paint,
    );
    startAngle += employerAngle;

    // Employee (Purple)
    paint.color = const Color(0xFF9C27B0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      employeeAngle,
      false,
      paint,
    );
    startAngle += employeeAngle;

    // Interest (Orange)
    paint.color = const Color(0xFFFF9800);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      interestAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}