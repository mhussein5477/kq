import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kq/services/secure_storage_service.dart';
import 'package:kq/widgets/appBar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:kq/services/api_service.dart';

// Main Reports Screen
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Top Bar
            CustomTopBar(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reports',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Report Cards
                    ReportCard(
                      icon: Icons.description_outlined,
                      title: 'Member Statement',
                      subtitle: 'Detailed Statement of your Account',
                      iconColor: const Color(0xFFE63946),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportDetailScreen(
                              reportType: ReportType.memberStatement,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    ReportCard(
                      icon: Icons.trending_up,
                      title: 'Contribution Statement',
                      subtitle: 'Summary of all contributions',
                      iconColor: const Color(0xFFE63946),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportDetailScreen(
                              reportType: ReportType.contributionStatement,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    ReportCard(
                      icon: Icons.card_membership_outlined,
                      title: 'Member Certificate',
                      subtitle: 'Official member certificate',
                      iconColor: const Color(0xFFE63946),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportDetailScreen(
                              reportType: ReportType.memberCertificate,
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
}

// Report Card Widget
class ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const ReportCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// Report Types Enum
enum ReportType { memberStatement, contributionStatement, memberCertificate }

// Report Detail Screen (Reusable for all three scenarios)
class ReportDetailScreen extends StatefulWidget {
  final ReportType reportType;

  const ReportDetailScreen({super.key, required this.reportType});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  DateTime? startDate;
  DateTime? endDate;
  bool isGenerating = false;

  String get title {
    switch (widget.reportType) {
      case ReportType.memberStatement:
        return 'Member Statement';
      case ReportType.contributionStatement:
        return 'Contribution Statement';
      case ReportType.memberCertificate:
        return 'Member Certificate';
    }
  }

  String get subtitle {
    switch (widget.reportType) {
      case ReportType.memberStatement:
        return 'Detailed statement of your account';
      case ReportType.contributionStatement:
        return 'Summary of all contributions';
      case ReportType.memberCertificate:
        return 'Official membership certificate';
    }
  }

  bool get requiresDateRange {
    return widget.reportType == ReportType.memberStatement;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE63946),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  /// Decode and decompress the base64 gzipped report
  Uint8List _decodeGzipReport(String base64GzipData) {
    try {
      // Decode from base64
      final gzipBytes = base64Decode(base64GzipData);

      print('📦 Gzip bytes length: ${gzipBytes.length}');

      // Decompress gzip
      final decompressed = GZipDecoder().decodeBytes(gzipBytes);

      print('📄 Decompressed PDF length: ${decompressed.length}');

      return Uint8List.fromList(decompressed);
    } catch (e) {
      print('❌ Error decoding/decompressing: $e');
      rethrow;
    }
  }

  /// Save the PDF file and share it
  Future<void> _savePdfAndShare(Uint8List pdfBytes, String fileName) async {
    try {
      // Get the temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';

      print('💾 Saving PDF to: $filePath');

      // Write the file
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      print('✅ PDF saved successfully, size: ${pdfBytes.length} bytes');

      // Share the file
      await Share.shareXFiles([
        XFile(filePath),
      ], text: 'Report generated from KQ Member Portal');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving/sharing PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _generateReport() async {
    // Validate date range for Member Statement
    if (requiresDateRange) {
      if (startDate == null || endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both start and end dates'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (startDate!.isAfter(endDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Start date must be before end date'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      isGenerating = true;
    });

    try {
      print('🔐 Fetching credentials...');

      // Fetch access token from secure storage
      final accessToken = await SecureStorageService.getAccessToken();

      // Fetch member details from secure storage
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      print('👤 Member No: $memberNo');

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token not found. Please log in again.');
      }

      if (memberNo == null || memberNo.isEmpty) {
        throw Exception('Member number not found.');
      }

      String base64GzipReport;
      String fileName;

      print('📊 Generating ${widget.reportType.toString().split('.').last}...');

      switch (widget.reportType) {
        case ReportType.memberStatement:
          final dateFormat = DateFormat('yyyy-MM-dd');

          base64GzipReport = await ApiService.generateMemberStatement(
            accessToken: accessToken,
            memberNo: memberNo,
            startDate: dateFormat.format(startDate!),
            endDate: dateFormat.format(endDate!),
          );

          fileName =
              'member_statement_${dateFormat.format(DateTime.now())}.pdf';
          break;

        case ReportType.contributionStatement:
          base64GzipReport = await ApiService.generateContributionStatement(
            accessToken: accessToken,
            memberNo: memberNo,
          );

          fileName =
              'contribution_statement_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
          break;

        case ReportType.memberCertificate:
          base64GzipReport = await ApiService.generateMemberCertificate(
            accessToken: accessToken,
            memberNo: memberNo,
          );

          fileName =
              'member_certificate_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
          break;
      }

      print('✅ Received base64 report, length: ${base64GzipReport.length}');

      // Decode and decompress
      final pdfBytes = _decodeGzipReport(base64GzipReport);

      // Save and share
      await _savePdfAndShare(pdfBytes, fileName);
    } catch (e) {
      print('❌ Report generation failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text('Back', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Date Range Selection (only for Member Statement)
                    if (requiresDateRange) ...[
                      _buildDateField(
                        label: 'Start Date',
                        date: startDate,
                        onTap: () => _selectDate(context, true),
                      ),
                      const SizedBox(height: 20),
                      _buildDateField(
                        label: 'End Date',
                        date: endDate,
                        onTap: () => _selectDate(context, false),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Info Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FD),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Note:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  requiresDateRange
                                      ? 'Reports are generated from external system and may take a few moments to process. The report will be compressed and ready for download.'
                                      : 'Reports are generated from external system  and may take a few moments to process. The report will be compressed and ready for download.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isGenerating
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFFE63946)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFE63946),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isGenerating ? null : _generateReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE63946),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40),
                              ),
                              elevation: 0,
                            ),
                            child: isGenerating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: ExpressiveLoadingIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.download,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Generate',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
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

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null ? dateFormat.format(date) : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      color: date != null ? Colors.black : Colors.grey[500],
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
