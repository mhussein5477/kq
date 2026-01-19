import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';

// ============================================================================
// COLORS & CONSTANTS
// ============================================================================

class AppColors {
  static const primary = Color(0xFFE31E24);
  static const surfaceDarker = Color(0xFF2A2A2A);
}

// ============================================================================
// SPOUSE DATA MODEL
// ============================================================================

class SpouseData {
  String? id;
  String firstName;
  String otherNames;
  String surName;
  String phoneNo;
  String emailAddress;
  String dateOfBirth;
  String gender;

  SpouseData({
    this.id,
    required this.firstName,
    this.otherNames = '',
    required this.surName,
    required this.phoneNo,
    this.emailAddress = '',
    required this.dateOfBirth,
    required this.gender,
  });

  String get fullName =>
      '$firstName ${otherNames.isNotEmpty ? '$otherNames ' : ''}$surName'.trim();

  factory SpouseData.fromMap(Map<String, dynamic> map) {
    return SpouseData(
      id: map['id'],
      firstName: map['firstName'] ?? '',
      otherNames: map['otherNames'] ?? map['otherName'] ?? '',
      surName: map['surName'] ?? map['lastName'] ?? '',
      phoneNo: map['phoneNo'] ?? '',
      emailAddress: map['emailAddress'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'firstName': firstName,
      'otherNames': otherNames,
      'surName': surName,
      'phoneNo': phoneNo,
      'emailAddress': emailAddress,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
    };
  }

  SpouseData copyWith({
    String? id,
    String? firstName,
    String? otherNames,
    String? surName,
    String? phoneNo,
    String? emailAddress,
    String? dateOfBirth,
    String? gender,
  }) {
    return SpouseData(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      otherNames: otherNames ?? this.otherNames,
      surName: surName ?? this.surName,
      phoneNo: phoneNo ?? this.phoneNo,
      emailAddress: emailAddress ?? this.emailAddress,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
    );
  }
}

// ============================================================================
// EDIT SPOUSES SCREEN
// ============================================================================

class EditSpousesScreen extends StatefulWidget {
  const EditSpousesScreen({super.key});

  @override
  State<EditSpousesScreen> createState() => _EditSpousesScreenState();
}

class _EditSpousesScreenState extends State<EditSpousesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _changeRequestNo;
  String? _changeRequestId;

  List<SpouseData> _spouses = [];
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadSpouses();
  }

  Future<void> _loadSpouses() async {
    try {
      setState(() => _isLoading = true);

      final accessToken = await SecureStorageService.getAccessToken();
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      if (accessToken == null || memberNo == null) {
        throw Exception('Authentication data missing');
      }

      final spousesData = await ApiService.fetchMemberSpouses(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      setState(() {
        _spouses = spousesData.map((s) => SpouseData.fromMap(s)).toList();
        _isLoading = false;
      });

      debugPrint('✅ Loaded ${_spouses.length} spouses');
    } catch (e) {
      debugPrint('❌ Error loading spouses: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load spouses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initiateChangeRequest() async {
    debugPrint('\n🚀 === INITIATING SPOUSE CHANGE REQUEST ===');

    try {
      final accessToken = await SecureStorageService.getAccessToken();
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      if (accessToken == null || memberNo == null) {
        throw Exception('Authentication data missing');
      }

      final changeRequest = await ApiService.initiateChangeRequest(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      final changeRequestNo =
          changeRequest['no'] ?? changeRequest['changeRequestNo'];

      if (changeRequestNo == null) {
        throw Exception('Change request number not found in response');
      }

      final fullDetails = await ApiService.getChangeRequestDetails(
        accessToken: accessToken,
        changeRequestNo: changeRequestNo,
        includeSpouseChanges: true,
      );

      setState(() {
        _changeRequestNo = changeRequestNo;
        _changeRequestId = fullDetails['id'];
      });

      debugPrint('✅ Change request ready: $_changeRequestNo (ID: $_changeRequestId)');
    } catch (e) {
      debugPrint('❌ Error initiating change request: $e');
      throw Exception('Failed to initiate change request: $e');
    }
  }

  void _addSpouse() {
    setState(() {
      _spouses.add(SpouseData(
        firstName: '',
        surName: '',
        phoneNo: '',
        dateOfBirth: '',
        gender: 'Male',
      ));
    });
  }

  void _removeSpouse(int index) {
    setState(() {
      _spouses.removeAt(index);
    });
  }

  bool _validateSpouses() {
    if (_spouses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one spouse'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    for (var i = 0; i < _spouses.length; i++) {
      final spouse = _spouses[i];
      if (spouse.firstName.isEmpty ||
          spouse.surName.isEmpty ||
          spouse.phoneNo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all required fields for spouse ${i + 1}'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _saveChanges() async {
    if (!_validateSpouses()) return;

    setState(() => _isSaving = true);

    try {
      final accessToken = await SecureStorageService.getAccessToken();
      if (accessToken == null) throw Exception('No access token found');

      debugPrint('🚀 Creating new change request for spouse changes...');
      await _initiateChangeRequest();

      if (_changeRequestId == null || _changeRequestNo == null) {
        throw Exception('Failed to get change request ID or number');
      }

      debugPrint('✅ Change request created: $_changeRequestNo (ID: $_changeRequestId)');

      final spouseChanges = await ApiService.fetchSpouseChanges(
        accessToken: accessToken,
        changeRequestNo: _changeRequestNo!,
      );

      if (spouseChanges.isEmpty) {
        throw Exception('No spouse changes found in change request');
      }

      debugPrint('📋 Found ${spouseChanges.length} spouse changes');

      for (final spouseChange in spouseChanges) {
        final payload = {
          'id': spouseChange['id'],
          'firstName': spouseChange['firstName'] ?? '',
          'otherNames': spouseChange['otherName'] ?? '',
          'surName': spouseChange['lastName'] ?? '',
          'phoneNo': spouseChange['phoneNo'] ?? '',
          'emailAddress': spouseChange['emailAddress'] ?? '',
          'dateOfBirth': spouseChange['dateOfBirth'] ?? '',
          'gender': spouseChange['gender'] ?? '',
          'changeRequestNo': _changeRequestNo,
        };

        debugPrint('📝 PATCH SPOUSE CHANGE PAYLOAD: ${jsonEncode(payload)}');

        final success = await ApiService.updateSpouseChanges(
          accessToken: accessToken,
          spouse: payload,
        );

        if (!success) {
          final name =
              '${payload['firstName']} ${payload['otherNames']} ${payload['surName']}'
                  .trim();
          throw Exception('Failed to update spouse change for $name');
        }
      }

      final submitted = await ApiService.submitMemberChanges(
        accessToken: accessToken,
        changeRequestId: _changeRequestId!,
      );

      setState(() => _isSaving = false);

      if (submitted && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spouse changes submitted successfully',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Change Request No: $_changeRequestNo',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your changes will be reviewed and applied after approval.',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        throw Exception('Submission failed');
      }
    } catch (e) {
      debugPrint('❌ Error saving spouse changes: $e');
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, int index) async {
    final initialDate = DateTime.now().subtract(const Duration(days: 18 * 365));
    final firstDate = DateTime(1900);
    final lastDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _spouses[index] = _spouses[index].copyWith(
          dateOfBirth: picked.toIso8601String().split('T')[0],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Spouses',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Spouses',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.blue[900]!.withOpacity(0.3)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: isDarkMode ? Colors.blue[300] : Colors.blue[900],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Update your spouse information. All changes will be submitted for approval.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.blue[200]
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_spouses.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Icon(
                              Icons.favorite_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No spouses added yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      )
                    else
                      ..._spouses.asMap().entries.map((entry) {
                        final index = entry.key;
                        final spouse = entry.value;
                        return _buildSpouseCard(spouse, index, isDarkMode, theme);
                      }).toList(),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _addSpouse,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Spouse'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSpouseCard(
    SpouseData spouse,
    int index,
    bool isDarkMode,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spouse ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeSpouse(index),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'First Name',
            value: spouse.firstName,
            isDarkMode: isDarkMode,
            onChanged: (value) {
              setState(() => spouse.firstName = value);
            },
          ),
          _buildTextField(
            label: 'Other Names',
            value: spouse.otherNames,
            isDarkMode: isDarkMode,
            onChanged: (value) {
              setState(() => spouse.otherNames = value);
            },
          ),
          _buildTextField(
            label: 'Surname',
            value: spouse.surName,
            isDarkMode: isDarkMode,
            onChanged: (value) {
              setState(() => spouse.surName = value);
            },
          ),
          _buildTextField(
            label: 'Phone Number',
            value: spouse.phoneNo,
            isDarkMode: isDarkMode,
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              setState(() => spouse.phoneNo = value);
            },
          ),
          _buildTextField(
            label: 'Email Address (Optional)',
            value: spouse.emailAddress,
            isDarkMode: isDarkMode,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              setState(() => spouse.emailAddress = value);
            },
          ),
          _buildDateField(
            label: 'Date of Birth',
            value: spouse.dateOfBirth,
            isDarkMode: isDarkMode,
            onTap: () => _selectDate(context, index),
          ),
          _buildDropdownField(
            label: 'Gender',
            value: spouse.gender,
            items: _genderOptions,
            isDarkMode: isDarkMode,
            onChanged: (value) {
              setState(() => spouse.gender = value ?? 'Male');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required bool isDarkMode,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDarkMode ? AppColors.surfaceDarker : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDarker : Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value.isEmpty ? 'Select date' : value,
                    style: TextStyle(
                      color: value.isEmpty
                          ? Colors.grey[600]
                          : (isDarkMode ? Colors.white : Colors.black87),
                      fontSize: 14,
                    ),
                  ),
                  const Icon(Icons.calendar_today, size: 20,
                      color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required bool isDarkMode,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : null,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDarkMode ? AppColors.surfaceDarker : Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}