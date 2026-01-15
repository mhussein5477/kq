import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';

class NextOfKin {
  String id;
  String firstName;
  String otherNames;
  String surName;
  String relationship;
  String phoneNo;
  String emailAddress;
  String address;
  bool isPrimary;

  NextOfKin({
    required this.id,
    required this.firstName,
    required this.otherNames,
    required this.surName,
    required this.relationship,
    required this.phoneNo,
    required this.emailAddress,
    required this.address,
    required this.isPrimary,
  });

  String get fullName => '$firstName $otherNames $surName'.trim();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'otherNames': otherNames,
      'surName': surName,
      'relationship': relationship,
      'phoneNo': phoneNo,
      'emailAddress': emailAddress,
      'address': address,
      'isPrimary': isPrimary,
    };
  }
}

class EditNOKScreen extends StatefulWidget {
  const EditNOKScreen({super.key});

  @override
  State<EditNOKScreen> createState() => _EditNOKScreenState();
}

class _EditNOKScreenState extends State<EditNOKScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  List<NextOfKin> _nextOfKin = [];
  List<String> _availableRelationships = [];
  
  String? _changeRequestNo;
  String? _changeRequestId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final accessToken = await SecureStorageService.getAccessToken();
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      if (accessToken == null || memberNo == null) {
        throw Exception('Authentication data missing');
      }

      // Load relationships for dropdown
      final relationships = await ApiService.fetchRelationships(
        accessToken: accessToken,
      );

      // Load existing next of kin
      final nokData = await ApiService.fetchMemberNextOfKin(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      setState(() {
        _availableRelationships = relationships
            .map((r) => r['code']?.toString() ?? '')
            .where((code) => code.isNotEmpty)
            .toList();

        _nextOfKin = nokData.map((nok) {
          return NextOfKin(
            id: nok['id']?.toString() ?? '',
            firstName: nok['firstName']?.toString() ?? '',
            otherNames: nok['otherNames']?.toString() ?? '',
            surName: nok['surName']?.toString() ?? '',
            relationship: nok['relationship']?.toString() ?? '',
            phoneNo: nok['phoneNo']?.toString() ?? '',
            emailAddress: nok['emailAddress']?.toString() ?? '',
            address: nok['address']?.toString() ?? '',
            isPrimary: nok['isPrimary'] == true,
          );
        }).toList();
 
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading NOK data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initiateChangeRequest() async {
    final accessToken = await SecureStorageService.getAccessToken();
    final memberDetails = await SecureStorageService.getMemberDetails();
    final memberNo = memberDetails['memberNo'];

    if (accessToken == null || memberNo == null) {
      throw Exception('Authentication data missing');
    }

    debugPrint('🚀 === INITIATING NOK CHANGE REQUEST ===');

    final changeRequest = await ApiService.initiateChangeRequest(
      accessToken: accessToken,
      memberNo: memberNo,
    );

    final changeRequestNo =
        changeRequest['no'] ?? changeRequest['changeRequestNo'];

    if (changeRequestNo == null) {
      throw Exception('Change request number not found in response');
    }

    debugPrint('✅ Change request initiated: $changeRequestNo');

    // Fetch full details to get the ID
    final fullDetails = await ApiService.getChangeRequestDetails(
      accessToken: accessToken,
      changeRequestNo: changeRequestNo,
      includeNOKChanges: true,
    );

    setState(() {
      _changeRequestNo = changeRequestNo;
      _changeRequestId = fullDetails['id'];
    });

    debugPrint('✅ Change request ready: $_changeRequestNo (ID: $_changeRequestId)');

    if (_changeRequestId == null) {
      throw Exception('Could not extract ID from change request details');
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final accessToken = await SecureStorageService.getAccessToken();
      if (accessToken == null) throw Exception('No access token found');

      // STEP 1: Initiate change request if none exists
      if (_changeRequestId == null) {
        await _initiateChangeRequest();
      }
      if (_changeRequestId == null || _changeRequestNo == null) {
        throw Exception('Failed to get change request ID or number');
      }

      // STEP 2: Fetch NOK changes from the change request
      final nokChanges = await ApiService.fetchNOKChanges(
        accessToken: accessToken,
        changeRequestNo: _changeRequestNo!,
      );

      if (nokChanges.isEmpty) {
        throw Exception('No NOK changes found in change request');
      }

      debugPrint('📋 Found ${nokChanges.length} NOK changes');

      // STEP 3: Update each NOK change with current data
      for (int i = 0; i < nokChanges.length && i < _nextOfKin.length; i++) {
        final nokChange = nokChanges[i];
        final currentNOK = _nextOfKin[i];

        final payload = {
          'id': nokChange['id'], // Change record ID
          'firstName': currentNOK.firstName,
          'otherNames': currentNOK.otherNames,
          'surName': currentNOK.surName,
          'relationship': currentNOK.relationship,
          'phoneNo': currentNOK.phoneNo,
          'emailAddress': currentNOK.emailAddress,
          'address': currentNOK.address,
          'isPrimary': currentNOK.isPrimary,
          'changeRequestNo': _changeRequestNo,
        };

        debugPrint('📝 PATCH NOK CHANGE PAYLOAD: ${jsonEncode(payload)}');

        final success = await ApiService.updateNOKChanges(
          accessToken: accessToken,
          nextOfKin: payload,
        );

        if (!success) {
          throw Exception('Failed to update NOK change for ${currentNOK.fullName}');
        }
      }

      // STEP 4: Submit change request
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
                  'Next of Kin changes submitted successfully',
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
            backgroundColor: const Color(0xFFE31E24),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        throw Exception('Submission failed');
      }
    } catch (e) {
      debugPrint('❌ Error saving NOK changes: $e');
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

  void _addNewNOK() {
    setState(() {
      _nextOfKin.add(
        NextOfKin(
          id: '', // Will be generated by backend
          firstName: '',
          otherNames: '',
          surName: '',
          relationship: _availableRelationships.isNotEmpty 
              ? _availableRelationships.first 
              : '',
          phoneNo: '',
          emailAddress: '',
          address: '',
          isPrimary: false,
        ),
      );
    });
  }

  void _removeNOK(int index) {
    setState(() {
      _nextOfKin.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Next of Kin',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next of Kin',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Color(0xFF1976D2),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Update your next of kin information. All changes will be submitted for approval.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // List of Next of Kin
                    if (_nextOfKin.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No next of kin added yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      )
                    else
                      ..._nextOfKin.asMap().entries.map((entry) {
                        final index = entry.key;
                        final nok = entry.value;
                        return _buildNOKCard(nok, index);
                      }).toList(),

                    const SizedBox(height: 16),

                    // Add New NOK Button
                    OutlinedButton.icon(
                      onPressed: _addNewNOK,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Next of Kin'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE31E24),
                        side: const BorderSide(color: Color(0xFFE31E24)),
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

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31E24),
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

  Widget _buildNOKCard(NextOfKin nok, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                'Next of Kin ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE31E24),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeNOK(index),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // First Name
          _buildTextField(
            label: 'First Name',
            value: nok.firstName,
            onChanged: (value) {
              setState(() => nok.firstName = value);
            },
          ),

          // Other Names
          _buildTextField(
            label: 'Other Names',
            value: nok.otherNames,
            onChanged: (value) {
              setState(() => nok.otherNames = value);
            },
          ),

          // Surname
          _buildTextField(
            label: 'Surname',
            value: nok.surName,
            onChanged: (value) {
              setState(() => nok.surName = value);
            },
          ),

          // Relationship Dropdown
          _buildDropdownField(
            label: 'Relationship',
            value: nok.relationship,
            items: _availableRelationships,
            onChanged: (value) {
              setState(() => nok.relationship = value ?? '');
            },
          ),

          // Phone Number
          _buildTextField(
            label: 'Phone Number',
            value: nok.phoneNo,
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              setState(() => nok.phoneNo = value);
            },
          ),

          // Email Address
          _buildTextField(
            label: 'Email Address',
            value: nok.emailAddress,
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              setState(() => nok.emailAddress = value);
            },
          ),

          // Address
          _buildTextField(
            label: 'Address',
            value: nok.address,
            maxLines: 2,
            onChanged: (value) {
              setState(() => nok.address = value);
            },
          ),

          // Is Primary Checkbox
          CheckboxListTile(
            title: const Text(
              'Set as Primary',
              style: TextStyle(fontSize: 14),
            ),
            value: nok.isPrimary,
            onChanged: (value) {
              setState(() {
                // Only one can be primary
                if (value == true) {
                  for (var n in _nextOfKin) {
                    n.isPrimary = false;
                  }
                }
                nok.isPrimary = value ?? false;
              });
            },
            activeColor: const Color(0xFFE31E24),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
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
                borderSide: const BorderSide(color: Color(0xFFE31E24)),
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
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
                borderSide: const BorderSide(color: Color(0xFFE31E24)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}