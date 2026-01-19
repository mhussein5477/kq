import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kq/screens/auth/login.dart';
import 'package:kq/screens/home/changeRequestHistoryScreen.dart';
import 'package:kq/screens/home/editBeneficiaries.dart';
import 'package:kq/screens/home/editNextOfKin.dart';
import 'package:kq/screens/home/editProfile.dart';
import 'package:kq/screens/home/editSpouses.dart';
import 'package:kq/screens/home/settings.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/interceptor.dart';
import 'package:kq/services/secure_storage_service.dart';

// ============================================================================
// THEME & COLOR CONSTANTS
// ============================================================================

class AppColors {
  static const primary = Color(0xFFE31E24);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFFFA500);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const textTertiary = Color(0xFF999999);
  static const backgroundLight = Color(0xFFF5F5F8);
  static const backgroundDark = Color(0xFF121212);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const surfaceDarker = Color(0xFF2A2A2A);
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
// PROFILE SCREEN
// ============================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TokenExpiredHandler {
  Map<String, dynamic>? _memberData;
  int _selectedTabIndex = 0;
  int _trusteesTabIndex = 0;
  List<Map<String, dynamic>> _spouses = [];
  List<Map<String, dynamic>> _guardians = [];
  List<Map<String, dynamic>> _beneficiaries = [];
  List<Map<String, dynamic>> _nextOfKin = [];
  
  bool _isSpousesLoading = true;
  bool _isGuardiansLoading = true;
  bool _isTrusteesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrusteesData();
    _loadMemberDetails();
    _loadSpousesAndGuardians();
  }

  Future<void> _loadSpousesAndGuardians() async {
    try {
      await ApiTokenInterceptor.getValidTokenOrThrow();

      final accessToken = await SecureStorageService.getAccessToken();
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      if (accessToken == null || memberNo == null) {
        throw Exception('Missing auth data');
      }

      final spouses = await ApiService.fetchMemberSpouses(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      final guardians = await ApiService.fetchMemberGuardians(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      setState(() {
        _spouses = spouses;
        _guardians = guardians;
        _isSpousesLoading = false;
        _isGuardiansLoading = false;
      });
    } on TokenExpiredException catch (e) {
      print('Token expired: $e');
      if (mounted) {
        handleTokenExpired();
      }
    } catch (e) {
      debugPrint('Spouses/Guardians load error: $e');
      setState(() {
        _isSpousesLoading = false;
        _isGuardiansLoading = false;
      });
    }
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
      final member = decodedValue['values'][0][0];

      setState(() {
        _memberData = member;
      });
    } on TokenExpiredException catch (e) {
      print('Token expired: $e');
      if (mounted) {
        handleTokenExpired();
      }
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _loadTrusteesData() async {
    try {
      await ApiTokenInterceptor.getValidTokenOrThrow();

      final accessToken = await SecureStorageService.getAccessToken();
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      if (accessToken == null || memberNo == null) {
        throw Exception('Missing auth data');
      }

      final beneficiaries = await ApiService.fetchMemberBeneficiaries(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      final nextOfKin = await ApiService.fetchMemberNextOfKin(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      setState(() {
        _beneficiaries = beneficiaries;
        _nextOfKin = nextOfKin;
        _isTrusteesLoading = false;
      });
    } on TokenExpiredException catch (e) {
      print('Token expired: $e');
      if (mounted) {
        handleTokenExpired();
      }
    } catch (e) {
      debugPrint('Trustees load error: $e');
      setState(() => _isTrusteesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(isDarkMode),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: _buildTabContent(isDarkMode, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE31E24), Color.fromARGB(255, 77, 10, 10)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 56),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 24, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _memberData?['name'] ?? '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Member ID: ${_memberData?['no'] ?? '—'}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangeRequestsHistoryScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'View Change Requests',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTabPill('Personal', 0)),
                Expanded(child: _buildTabPill('Spouses / Guardians', 1)),
                Expanded(child: _buildTabPill('Beneficiaries / Kin', 2)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabPill(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 223, 238, 255)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.black,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryTab(String label, int index) {
    final isSelected = _trusteesTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _trusteesTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black54,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDarkMode, ThemeData theme) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildPersonalTab(isDarkMode, theme);
      case 1:
        return _buildSpousesGuardiansTab(isDarkMode, theme);
      case 2:
        return _buildTrusteesTab(isDarkMode, theme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPersonalTab(bool isDarkMode, ThemeData theme) {
    final member = _memberData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'These are details about you.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        _buildInfoField(
          'Full Name',
          member != null
              ? '${member['firstName'] ?? ''} ${member['otherName'] ?? ''} ${member['lastName'] ?? ''}'
                  .trim()
              : '—',
          isDarkMode,
        ),
        _buildInfoField('ID Number', member?['idNo'] ?? '—', isDarkMode),
        _buildInfoField('KRA PIN', member?['pin'] ?? '—', isDarkMode),
        _buildInfoField('Date of Birth', member?['dateOfBirth'] ?? '—', isDarkMode),
        _buildInfoField('Gender', member?['gender'] ?? '—', isDarkMode),
        _buildInfoField('Email', member?['emailAddress'] ?? '—', isDarkMode),
        _buildInfoField('Phone Number', member?['phoneNo'] ?? '—', isDarkMode),
        _buildInfoField(
          'Postal Address',
          member != null
              ? '${member['address'] ?? ''}, ${member['city'] ?? ''}, ${member['country'] ?? ''}'
                  .replaceAll(RegExp(r'(^,|,$)'), '')
              : '—',
          isDarkMode,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpousesGuardiansTab(bool isDarkMode, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spouses & Guardians',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'These are your registered spouses and guardians.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
        Text(
          'Spouses',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _isSpousesLoading
            ? const Center(child: CircularProgressIndicator())
            : _spouses.isEmpty
                ? Text(
                    'No spouses found',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  )
                : Column(
                    children: _spouses.map((s) {
                      final fullName =
                          [s['firstName'], s['otherNames'], s['surName']]
                              .where((e) => e != null && e.toString().isNotEmpty)
                              .join(' ');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildGenericCard(
                          name: fullName.isNotEmpty ? fullName : '—',
                          relationship: s['relationship'] ?? '—',
                          phone: s['phoneNo']?.toString().isNotEmpty == true
                              ? s['phoneNo']
                              : '—',
                          email: s['emailAddress']?.toString().isNotEmpty == true
                              ? s['emailAddress']
                              : '—',
                          address: s['address']?.toString().isNotEmpty == true
                              ? s['address']
                              : '—',
                          isDarkMode: isDarkMode,
                          theme: theme,
                        ),
                      );
                    }).toList(),
                  ),
        const SizedBox(height: 20),
        Text(
          'Guardians',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _isGuardiansLoading
            ? const Center(child: CircularProgressIndicator())
            : _guardians.isEmpty
                ? Text(
                    'No guardians found',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  )
                : Column(
                    children: _guardians.map((g) {
                      final fullName =
                          [g['firstName'], g['otherNames'], g['surName']]
                              .where((e) => e != null && e.toString().isNotEmpty)
                              .join(' ');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildGenericCard(
                          name: fullName.isNotEmpty ? fullName : '—',
                          relationship: g['relationship'] ?? '—',
                          phone: g['phoneNo']?.toString().isNotEmpty == true
                              ? g['phoneNo']
                              : '—',
                          email: g['emailAddress']?.toString().isNotEmpty == true
                              ? g['emailAddress']
                              : '—',
                          address: g['address']?.toString().isNotEmpty == true
                              ? g['address']
                              : '—',
                          isDarkMode: isDarkMode,
                          theme: theme,
                        ),
                      );
                    }).toList(),
                  ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditSpousesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Spouses'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrusteesTab(bool isDarkMode, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildSecondaryTab('Beneficiaries', 0)),
              const SizedBox(width: 12),
              Expanded(child: _buildSecondaryTab('Next of Kin', 1)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _trusteesTabIndex == 0
              ? _buildBeneficiariesContent(isDarkMode, theme)
              : _buildNextOfKinContent(isDarkMode, theme),
        ),
      ],
    );
  }

  Widget _buildBeneficiariesContent(bool isDarkMode, ThemeData theme) {
    if (_isTrusteesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Widget> content = [];

    if (_beneficiaries.isEmpty) {
      content.add(
        Text(
          'No beneficiaries found',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      );
    } else {
      content.addAll(
        _beneficiaries.map((b) {
          final fullName = [b['firstName'], b['otherNames'], b['surName']]
              .where((e) => e != null && e.toString().isNotEmpty)
              .join(' ');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBeneficiaryCard(
              name: fullName.isNotEmpty ? fullName : '—',
              relationship: b['relationship'] ?? '—',
              phone: b['phoneNo']?.toString().isNotEmpty == true ? b['phoneNo'] : '—',
              allocation: '${b['percentageBenefit'] ?? 0}%',
              isPrimary: false,
              isDarkMode: isDarkMode,
              theme: theme,
            ),
          );
        }).toList(),
      );
    }

    content.add(const SizedBox(height: 16));
    content.add(
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditBeneficiariesScreen(),
              ),
            );
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Beneficiaries'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }

  Widget _buildNextOfKinContent(bool isDarkMode, ThemeData theme) {
    if (_isTrusteesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Widget> content = [];

    if (_nextOfKin.isEmpty) {
      content.add(
        Text(
          'No next of kin found',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
      );
    } else {
      content.addAll(
        _nextOfKin.map((k) {
          final fullName = [k['firstName'], k['otherNames'], k['surName']]
              .where((e) => e != null && e.toString().isNotEmpty)
              .join(' ');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildGenericCard(
              name: fullName.isNotEmpty ? fullName : '—',
              relationship: k['relationship']?.toString().isNotEmpty == true
                  ? k['relationship']
                  : '—',
              phone: k['phoneNo']?.toString().isNotEmpty == true ? k['phoneNo'] : '—',
              email: k['emailAddress']?.toString().isNotEmpty == true
                  ? k['emailAddress']
                  : '—',
              address: k['address']?.toString().isNotEmpty == true ? k['address'] : '—',
              isDarkMode: isDarkMode,
              theme: theme,
            ),
          );
        }).toList(),
      );
    }

    content.add(const SizedBox(height: 16));
    content.add(
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditNOKScreen(),
              ),
            );
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Next of Kin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }

  Widget _buildInfoField(String label, String value, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppColors.surfaceDarker
            : const Color.fromARGB(255, 234, 234, 255),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white54 : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryCard({
    required String name,
    required String relationship,
    required String phone,
    required String allocation,
    required bool isPrimary,
    required bool isDarkMode,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
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
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Primary',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      relationship,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    allocation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Allocation',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.phone, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Phone Number',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            phone,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericCard({
    required String name,
    required String relationship,
    required String phone,
    required String email,
    required String address,
    required bool isDarkMode,
    required ThemeData theme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Relationship: $relationship',
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Phone: $phone',
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Email: $email',
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Address: $address',
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}