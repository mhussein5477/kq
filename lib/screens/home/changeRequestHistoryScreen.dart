import 'package:flutter/material.dart';
import 'package:kq/screens/auth/login.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';
import 'package:kq/services/interceptor.dart';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

// Change Requests History Screen
class ChangeRequestsHistoryScreen extends StatefulWidget {
  const ChangeRequestsHistoryScreen({super.key});

  @override
  State<ChangeRequestsHistoryScreen> createState() =>
      _ChangeRequestsHistoryScreenState();
}

class _ChangeRequestsHistoryScreenState
    extends State<ChangeRequestsHistoryScreen> {
  List<Map<String, dynamic>> changeRequests = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadChangeRequests();
  }

  Future<void> _loadChangeRequests() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // ✅ Check token validity first
      await ApiTokenInterceptor.getValidTokenOrThrow();

      final accessToken = await SecureStorageService.getAccessToken();
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      if (accessToken == null || memberNo == null || memberNo.isEmpty) {
        throw Exception('Authentication token or member number missing');
      }

      // Fetch change requests from API
      final requests = await ApiService.fetchChangeRequestsHistory(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      setState(() {
        changeRequests = requests;
        isLoading = false;
      });
    } on TokenExpiredException catch (e) {  // ✅ Catch token expiry
      print('Token expired: $e');
      if (mounted) {
        _handleTokenExpired();
      }
    } catch (e) {
      setState(() {
        error = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  void _handleTokenExpired() {
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
                Navigator.of(context).pop(); // Close dialog
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

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '—';
    
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return dateValue.toString();
      }
      
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      appBar: AppBar( 
        elevation: 0,
            backgroundColor: Colors.white,
        foregroundColor: Colors.black, 
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Change Requests History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: ExpressiveLoadingIndicator(color: Color(0xFFE31E24)),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load change requests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadChangeRequests,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31E24),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : changeRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No Change Requests',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You haven\'t made any change requests yet',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadChangeRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: changeRequests.length,
                        itemBuilder: (context, index) {
                          final request = changeRequests[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildChangeRequestCard(request),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildChangeRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'Open';
    final changeType = request['changeType'] ?? 'Profile Update';
    final changeRequestNo = request['changeRequestNo'] ?? request['no'] ?? '—';
    final dateRaised = _formatDate(request['createdAt'] ?? request['dateRaised']);

    // Status color mapping
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'posted':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
      case 'open':
        statusColor = const Color(0xFFFFA500);
        statusIcon = Icons.schedule;
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.info;
    }

    return InkWell(
      onTap: () => _showRequestDetails(request),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              changeRequestNo,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        changeType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF999999)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Submitted: $dateRaised',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDetails(Map<String, dynamic> request) async {
    // Fetch full details if needed
    try {
      // ✅ Check token validity first
      await ApiTokenInterceptor.getValidTokenOrThrow();
      
      final accessToken = await SecureStorageService.getAccessToken();
      final changeRequestNo = request['changeRequestNo'] ?? request['no'];
      
      if (accessToken == null || changeRequestNo == null) {
        throw Exception('Missing authentication data');
      }
      
      final fullDetails = await ApiService.getChangeRequestDetails(
        accessToken: accessToken,
        changeRequestNo: changeRequestNo,
        includeNOKChanges: true,
        includeBeneficiaryChanges: true,
        includeSpouseChanges: true,
        includeGuardianChanges: true,
      );
      
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ChangeRequestDetailsModal(
            request: fullDetails.isNotEmpty ? fullDetails : request,
          ),
        );
      }
    } on TokenExpiredException catch (e) {  // ✅ Catch token expiry
      print('Token expired while fetching details: $e');
      if (mounted) {
        _handleTokenExpired();
      }
    } catch (e) {
      print('Error fetching full details: $e');
      // Show basic details if full fetch fails
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ChangeRequestDetailsModal(request: request),
        );
      }
    }
  }
}
 

// Change Request Details Modal with Formatted Nested Data
class ChangeRequestDetailsModal extends StatelessWidget {
  final Map<String, dynamic> request;

  const ChangeRequestDetailsModal({
    super.key,
    required this.request,
  });

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '—';
    
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return dateValue.toString();
      }
      
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateValue.toString();
    }
  }

  List<Map<String, dynamic>> _parseNestedChanges(dynamic data) {
    if (data == null) return [];
    
    try {
      // If it's already a list
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      
      // If it's a JSON string, parse it
      if (data is String) {
        final parsed = jsonDecode(data);
        if (parsed is List) {
          return parsed.whereType<Map<String, dynamic>>().toList();
        }
        if (parsed is Map) {
          return [Map<String, dynamic>.from(parsed)];
        }
      }
      
      // If it's a map
      if (data is Map) {
        return [Map<String, dynamic>.from(data)];
      }
      
      return [];
    } catch (e) {
      print('Error parsing nested changes: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request['status'] ?? request['approvalStatus'] ?? 'Open';
    final changeType = request['changeType'] ?? 'Profile Update';
    final changeRequestNo = request['changeRequestNo'] ?? request['no'] ?? '—';
    final dateRaised = _formatDate(request['createdAt'] ?? request['dateRaised']);
    final dateProcessed = _formatDate(request['updatedAt'] ?? request['dateProcessed']);
    final approvedBy = request['approvedBy'];
    final rejectedBy = request['rejectedBy'];
    final rejectionReason = request['rejectionReason'];

    // Parse nested changes
    final nokChanges = _parseNestedChanges(request['nokChanges']);
    final beneficiaryChanges = _parseNestedChanges(request['beneficiaryChanges']);
    final spouseChanges = _parseNestedChanges(request['spouseChanges']);
    final guardianChanges = _parseNestedChanges(request['guardianChanges']);

    // Status color
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'approved':
      case 'posted':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
      case 'pending approval':
      case 'open':
        statusColor = const Color(0xFFFFA500);
        statusIcon = Icons.schedule;
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = const Color(0xFF3B82F6);
        statusIcon = Icons.info;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            changeRequestNo,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 20, color: statusColor),
                            const SizedBox(width: 8),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Basic Details
                      _buildDetailRow('Change Type', changeType, Icons.edit_document),
                      const SizedBox(height: 16),
                      _buildDetailRow('Date Submitted', dateRaised, Icons.calendar_today),

                      if (dateProcessed != '—') ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Date Processed', dateProcessed, Icons.check_circle_outline),
                      ],

                      if (approvedBy != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Approved By', approvedBy.toString(), Icons.person),
                      ],

                      if (rejectedBy != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Rejected By', rejectedBy.toString(), Icons.person),
                      ],

                      if (rejectionReason != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailRow('Rejection Reason', rejectionReason.toString(), Icons.info_outline),
                      ],

                      // NOK Changes Section
                      if (nokChanges.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Next of Kin Changes', Icons.people, nokChanges.length),
                        const SizedBox(height: 12),
                        ...nokChanges.asMap().entries.map((entry) {
                          return _buildNOKCard(entry.value, entry.key + 1);
                        }).toList(),
                      ],

                      // Beneficiary Changes Section
                      if (beneficiaryChanges.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Beneficiary Changes', Icons.family_restroom, beneficiaryChanges.length),
                        const SizedBox(height: 12),
                        ...beneficiaryChanges.asMap().entries.map((entry) {
                          return _buildBeneficiaryCard(entry.value, entry.key + 1);
                        }).toList(),
                      ],

                      // Spouse Changes Section
                      if (spouseChanges.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Spouse Changes', Icons.favorite, spouseChanges.length),
                        const SizedBox(height: 12),
                        ...spouseChanges.asMap().entries.map((entry) {
                          return _buildSpouseCard(entry.value, entry.key + 1);
                        }).toList(),
                      ],

                      // Guardian Changes Section
                      if (guardianChanges.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        _buildSectionHeader('Guardian Changes', Icons.shield, guardianChanges.length),
                        const SizedBox(height: 12),
                        ...guardianChanges.asMap().entries.map((entry) {
                          return _buildGuardianCard(entry.value, entry.key + 1);
                        }).toList(),
                      ],

                      // Member Profile Changes
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildSectionHeader('Profile Changes', Icons.person, 0),
                      const SizedBox(height: 12),
                      _buildProfileChanges(request),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFE31E24)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE31E24).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE31E24),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNOKCard(Map<String, dynamic> nok, int index) {
    final firstName = nok['firstName'] ?? '';
    final otherNames = nok['otherNames'] ?? nok['otherName'] ?? '';
    final surName = nok['surName'] ?? nok['lastName'] ?? '';
    final fullName = '$firstName $otherNames $surName'.trim();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$index',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fullName.isNotEmpty ? fullName : 'Unnamed',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (nok['isPrimary'] == true || nok['isPrimary'] == 'true')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRIMARY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Relationship', nok['relationship']),
          _buildInfoRow('Phone', nok['phoneNo']),
          if (nok['emailAddress'] != null && nok['emailAddress'].toString().isNotEmpty)
            _buildInfoRow('Email', nok['emailAddress']),
          if (nok['address'] != null && nok['address'].toString().isNotEmpty)
            _buildInfoRow('Address', nok['address']),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryCard(Map<String, dynamic> ben, int index) {
    final firstName = ben['firstName'] ?? '';
    final otherNames = ben['otherNames'] ?? ben['otherName'] ?? '';
    final surName = ben['surName'] ?? ben['lastName'] ?? '';
    final fullName = '$firstName $otherNames $surName'.trim();
    final percentage = ben['percentageBenefit'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$index',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : 'Unnamed',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$percentage% Allocation',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (ben['isPrimary'] == true || ben['isPrimary'] == 'true')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRIMARY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Relationship', ben['relationship']),
          _buildInfoRow('Phone', ben['phoneNo']),
          if (ben['emailAddress'] != null && ben['emailAddress'].toString().isNotEmpty)
            _buildInfoRow('Email', ben['emailAddress']),
          if (ben['address'] != null && ben['address'].toString().isNotEmpty)
            _buildInfoRow('Address', ben['address']),
        ],
      ),
    );
  }

  Widget _buildSpouseCard(Map<String, dynamic> spouse, int index) {
    final firstName = spouse['firstName'] ?? '';
    final otherNames = spouse['otherNames'] ?? spouse['otherName'] ?? '';
    final surName = spouse['surName'] ?? spouse['lastName'] ?? '';
    final fullName = '$firstName $otherNames $surName'.trim();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$index',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fullName.isNotEmpty ? fullName : 'Unnamed',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Phone', spouse['phoneNo']),
          if (spouse['emailAddress'] != null && spouse['emailAddress'].toString().isNotEmpty)
            _buildInfoRow('Email', spouse['emailAddress']),
          if (spouse['dateOfBirth'] != null)
            _buildInfoRow('Date of Birth', _formatDate(spouse['dateOfBirth'])),
          if (spouse['gender'] != null)
            _buildInfoRow('Gender', spouse['gender']),
        ],
      ),
    );
  }

  Widget _buildGuardianCard(Map<String, dynamic> guardian, int index) {
    final firstName = guardian['firstName'] ?? '';
    final otherNames = guardian['otherNames'] ?? guardian['otherName'] ?? '';
    final surName = guardian['surName'] ?? guardian['lastName'] ?? '';
    final fullName = '$firstName $otherNames $surName'.trim();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$index',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE31E24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fullName.isNotEmpty ? fullName : 'Unnamed',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Relationship', guardian['relationship']),
          _buildInfoRow('Phone', guardian['phoneNo']),
          if (guardian['emailAddress'] != null && guardian['emailAddress'].toString().isNotEmpty)
            _buildInfoRow('Email', guardian['emailAddress']),
          if (guardian['address'] != null && guardian['address'].toString().isNotEmpty)
            _buildInfoRow('Address', guardian['address']),
        ],
      ),
    );
  }

  Widget _buildProfileChanges(Map<String, dynamic> data) {
    final excludeFields = {
      'id', 'systemId', 'changeRequestNo', 'no', 'status', 'changeType',
      'createdAt', 'updatedAt', 'dateRaised', 'dateProcessed',
      'approvedBy', 'rejectedBy', 'rejectionReason', 'approvalStatus',
      'nokChanges', 'beneficiaryChanges', 'spouseChanges', 'guardianChanges'
    };

    final fields = data.entries
        .where((e) => !excludeFields.contains(e.key) && e.value != null && e.value.toString().isNotEmpty)
        .toList();

    if (fields.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No profile changes in this request',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: fields.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildInfoRow(_formatFieldName(entry.key), entry.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatFieldName(String fieldName) {
    // Convert camelCase to Title Case
    final result = fieldName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }
}


  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '—';
    
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return dateValue.toString();
      }
      
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateValue.toString();
    }
  }

   
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllFields(Map<String, dynamic> data) {
    final excludeFields = {
      'id', 'systemId', 'changeRequestNo', 'no', 'status', 
      'changeType', 'createdAt', 'updatedAt', 'dateRaised', 
      'dateProcessed', 'approvedBy', 'rejectedBy', 'rejectionReason'
    };

    final fields = data.entries
        .where((e) => !excludeFields.contains(e.key) && e.value != null)
        .toList();

    if (fields.isEmpty) {
      return Text(
        'No additional details available',
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: fields.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatFieldName(entry.key),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatFieldName(String fieldName) {
    // Convert camelCase to Title Case
    final result = fieldName.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }
