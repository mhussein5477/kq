import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kq/screens/home/settings.dart';
import 'package:kq/screens/home/test.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';

// Profile Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _memberData;

  int _selectedTabIndex = 0;
  int _trusteesTabIndex = 0;
  List<Map<String, dynamic>> _spouses = [];
  List<Map<String, dynamic>> _guardians = [];
  bool _isSpousesLoading = true;
  bool _isGuardiansLoading = true;

  List<Map<String, dynamic>> _beneficiaries = [];
  List<Map<String, dynamic>> _nextOfKin = [];
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
      final accessToken = await SecureStorageService.getAccessToken();
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      if (accessToken == null || memberNo == null)
        throw Exception('Missing auth data');

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
      });
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _loadTrusteesData() async {
    try {
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
    } catch (e) {
      debugPrint('Trustees load error: $e');
      setState(() => _isTrusteesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
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
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Member ID: ${_memberData?['no'] ?? '—'}',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Tab Pills
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
                        Expanded(
                          child: _buildTabPill('Spouses / Guardians', 1),
                        ),
                        Expanded(
                          child: _buildTabPill('Beneficiaries / Kin', 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Content Area BELOW
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: _buildTabContent(),
            ),
          ],
        ),
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
            color: isSelected
                ? const Color.fromARGB(255, 0, 0, 0)
                : Colors.black,
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
      onTap: () {
        setState(() {
          _trusteesTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFFE31E24) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? const Color(0xFFE31E24) : Colors.black54,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildPersonalTab();
      case 1:
        return _buildSpousesGuardiansTab();
      case 2:
        return _buildTrusteesTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPersonalTab() {
    final member = _memberData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
        ),
        _buildInfoField('ID Number', member?['idNo'] ?? '—'),
        _buildInfoField('KRA PIN', member?['pin'] ?? '—'),
        _buildInfoField('Date of Birth', member?['dateOfBirth'] ?? '—'),
        _buildInfoField('Gender', member?['gender'] ?? '—'),
        _buildInfoField('Email', member?['emailAddress'] ?? '—'),
        _buildInfoField('Phone Number', member?['phoneNo'] ?? '—'),
        _buildInfoField(
          'Postal Address',
          member != null
              ? '${member['address'] ?? ''}, ${member['city'] ?? ''}, ${member['country'] ?? ''}'
                    .replaceAll(RegExp(r'(^,|,$)'), '')
              : '—',
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
              backgroundColor: const Color(0xFFE31E24),
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

  Widget _buildSpousesGuardiansTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spouses & Guardians',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'These are your registered spouses and guardians.',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        // Spouses List
        const Text('Spouses', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _isSpousesLoading
            ? const Center(child: CircularProgressIndicator())
            : _spouses.isEmpty
            ? const Text('No spouses found')
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
                    ),
                  );
                }).toList(),
              ),

        const SizedBox(height: 20),
        // Guardians List
        const Text('Guardians', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _isGuardiansLoading
            ? const Center(child: CircularProgressIndicator())
            : _guardians.isEmpty
            ? const Text('No guardians found')
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
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildTrusteesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Secondary Tabs
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

        // Tab Content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _trusteesTabIndex == 0
              ? _buildBeneficiariesContent()
              : _buildNextOfKinContent(),
        ),
      ],
    );
  }

  Widget _buildBeneficiariesContent() {
    if (_isTrusteesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Widget> content = [];

    if (_beneficiaries.isEmpty) {
      content.add(const Text('No beneficiaries found'));
    } else {
      content.addAll(
        _beneficiaries.map((b) {
          final fullName = [
            b['firstName'],
            b['otherNames'],
            b['surName'],
          ].where((e) => e != null && e.toString().isNotEmpty).join(' ');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBeneficiaryCard(
              name: fullName.isNotEmpty ? fullName : '—',
              relationship: b['relationship'] ?? '—',
              phone: b['phoneNo']?.toString().isNotEmpty == true
                  ? b['phoneNo']
                  : '—',
              allocation: '${b['percentageBenefit'] ?? 0}%',
              isPrimary: false, // backend does not provide this
            ),
          );
        }).toList(),
      );
    }

    // Add Edit Beneficiaries button
    content.add(const SizedBox(height: 16));
    content.add(
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigate to edit beneficiaries screen
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Beneficiaries'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE31E24),
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

  Widget _buildNextOfKinContent() {
    if (_isTrusteesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Widget> content = [];

    if (_nextOfKin.isEmpty) {
      content.add(const Text('No next of kin found'));
    } else {
      content.addAll(
        _nextOfKin.map((k) {
          final fullName = [
            k['firstName'],
            k['otherNames'],
            k['surName'],
          ].where((e) => e != null && e.toString().isNotEmpty).join(' ');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : '—',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Relationship: ${k['relationship']?.toString().isNotEmpty == true ? k['relationship'] : '—'}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phone: ${k['phoneNo']?.toString().isNotEmpty == true ? k['phoneNo'] : '—'}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Email: ${k['emailAddress']?.toString().isNotEmpty == true ? k['emailAddress'] : '—'}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Address: ${k['address']?.toString().isNotEmpty == true ? k['address'] : '—'}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    // Add Edit Next of Kin button
    content.add(const SizedBox(height: 16));
    content.add(
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO: Navigate to edit next of kin screen
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Next of Kin'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE31E24),
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

  Widget _buildInfoField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 234, 234, 255),
        borderRadius: BorderRadius.circular(10),
      ),
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
              color: Colors.black87,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
                              color: const Color(0xFFE31E24),
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
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                      color: Color(0xFFE31E24),
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
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
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
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Relationship: $relationship',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Phone: $phone',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Email: $email',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Address: $address',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
