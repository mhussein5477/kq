import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';
import 'package:kq/services/upload_service.dart';

// Beneficiary Data Model
class BeneficiaryData {
  String? id;
  String? lineNo;
  String firstName;
  String otherNames;
  String surName;
  String relationship;
  String phoneNo;
  String emailAddress;
  String address;
  double percentageBenefit;
  bool isPrimary;
  UploadFile? supportingDocument;
  
  BeneficiaryData({
    this.id,
    this.lineNo,
    required this.firstName,
    this.otherNames = '',
    required this.surName,
    required this.relationship,
    required this.phoneNo,
    this.emailAddress = '',
    this.address = '',
    required this.percentageBenefit,
    this.isPrimary = false,
    this.supportingDocument,
  });

  String get fullName => '$firstName ${otherNames.isNotEmpty ? '$otherNames ' : ''}$surName'.trim();

  factory BeneficiaryData.fromMap(Map<String, dynamic> map) {
    return BeneficiaryData(
      id: map['id'],
      lineNo: map['lineNo']?.toString(),
      firstName: map['firstName'] ?? '',
      otherNames: map['otherNames'] ?? '',
      surName: map['surName'] ?? '',
      relationship: map['relationship'] ?? '',
      phoneNo: map['phoneNo'] ?? '',
      emailAddress: map['emailAddress'] ?? '',
      address: map['address'] ?? '',
      percentageBenefit: (map['percentageBenefit'] ?? 0),
      isPrimary: map['isPrimary'] == true || map['isPrimary'] == 'true',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (lineNo != null) 'lineNo': lineNo,
      'firstName': firstName,
      'otherNames': otherNames,
      'surName': surName,
      'relationship': relationship,
      'phoneNo': phoneNo,
      'emailAddress': emailAddress,
      'address': address,
      'percentageBenefit': percentageBenefit,
      'isPrimary': isPrimary,
    };
  }

  BeneficiaryData copyWith({
    String? id,
    String? lineNo,
    String? firstName,
    String? otherNames,
    String? surName,
    String? relationship,
    String? phoneNo,
    String? emailAddress,
    String? address,
    double? percentageBenefit,
    bool? isPrimary,
    UploadFile? supportingDocument,
  }) {
    return BeneficiaryData(
      id: id ?? this.id,
      lineNo: lineNo ?? this.lineNo,
      firstName: firstName ?? this.firstName,
      otherNames: otherNames ?? this.otherNames,
      surName: surName ?? this.surName,
      relationship: relationship ?? this.relationship,
      phoneNo: phoneNo ?? this.phoneNo,
      emailAddress: emailAddress ?? this.emailAddress,
      address: address ?? this.address,
      percentageBenefit: percentageBenefit ?? this.percentageBenefit,
      isPrimary: isPrimary ?? this.isPrimary,
      supportingDocument: supportingDocument ?? this.supportingDocument,
    );
  }
}

// Edit Beneficiaries Screen
class EditBeneficiariesScreen extends StatefulWidget {
  const EditBeneficiariesScreen({super.key});

  @override
  State<EditBeneficiariesScreen> createState() =>
      _EditBeneficiariesScreenState();
}

class _EditBeneficiariesScreenState extends State<EditBeneficiariesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _changeRequestNo;
  String? _changeRequestId;
  
  List<BeneficiaryData> _beneficiaries = [];
  List<BeneficiaryData> _originalBeneficiaries = [];
  List<Map<String, dynamic>> _relationships = [];
  
  // Fallback relationships in case API fails
  final List<Map<String, dynamic>> _fallbackRelationships = [
    {'code': 'SPOUSE', 'description': 'Spouse'},
    {'code': 'CHILD', 'description': 'Child'},
    {'code': 'SON', 'description': 'Son'},
    {'code': 'DAUGHTER', 'description': 'Daughter'},
    {'code': 'FATHER', 'description': 'Father'},
    {'code': 'MOTHER', 'description': 'Mother'},
    {'code': 'PARENT', 'description': 'Parent'},
    {'code': 'GUARDIAN', 'description': 'Guardian'},
    {'code': 'SIBLING', 'description': 'Sibling'},
    {'code': 'BROTHER', 'description': 'Brother'},
    {'code': 'SISTER', 'description': 'Sister'},
    {'code': 'GRANDCHILD', 'description': 'Grandchild'},
    {'code': 'GRANDSON', 'description': 'Grandson'},
    {'code': 'GRANDDAUGHTER', 'description': 'Granddaughter'},
    {'code': 'GRANDPARENT', 'description': 'Grandparent'},
    {'code': 'UNCLE', 'description': 'Uncle'},
    {'code': 'AUNT', 'description': 'Aunt'},
    {'code': 'NEPHEW', 'description': 'Nephew'},
    {'code': 'NIECE', 'description': 'Niece'},
    {'code': 'COUSIN', 'description': 'Cousin'},
    {'code': 'OTHER', 'description': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBeneficiariesAndRelationships();
  }

  Future<void> _loadBeneficiariesAndRelationships() async {
    try {
      setState(() => _isLoading = true);

      final accessToken = await SecureStorageService.getAccessToken();
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      if (accessToken == null || memberNo == null) {
        throw Exception('Authentication data missing');
      }

      // Fetch current beneficiaries
      final beneficiaries = await ApiService.fetchMemberBeneficiaries(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      // Fetch available relationships with fallback
      List<Map<String, dynamic>> relationships = [];
      try {
        relationships = await ApiService.fetchRelationships(
          accessToken: accessToken,
        );
        debugPrint('✅ Loaded ${relationships.length} relationships from API');
      } catch (e) {
        debugPrint('⚠️ Failed to load relationships from API: $e');
        debugPrint('📋 Using fallback relationships');
        relationships = _fallbackRelationships;
      }

      // If API returns empty list, use fallback
      if (relationships.isEmpty) {
        debugPrint('⚠️ API returned empty relationships list');
        debugPrint('📋 Using fallback relationships');
        relationships = _fallbackRelationships;
      }

      setState(() {
        _beneficiaries = beneficiaries
            .map((b) => BeneficiaryData.fromMap(b))
            .toList();
        _originalBeneficiaries = _beneficiaries
            .map((b) => BeneficiaryData.fromMap(b.toMap()))
            .toList();
        _relationships = relationships;
        _isLoading = false;
      });
      
      debugPrint('✅ Loaded ${_beneficiaries.length} beneficiaries');
      debugPrint('✅ Using ${_relationships.length} relationship options');
    } catch (e) {
      debugPrint('❌ Error loading beneficiaries: $e');
      setState(() {
        _relationships = _fallbackRelationships; // Ensure we have relationships even on error
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load beneficiaries: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initiateChangeRequest() async {
    debugPrint('\n🚀 === INITIATING BENEFICIARY CHANGE REQUEST ===');
    
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

      final changeRequestNo = changeRequest['no'] ?? changeRequest['changeRequestNo'];
      
      if (changeRequestNo == null) {
        throw Exception('Change request number not found in response');
      }

      final fullDetails = await ApiService.getChangeRequestDetails(
        accessToken: accessToken,
        changeRequestNo: changeRequestNo,
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

  void _addBeneficiary() {
    setState(() {
      _beneficiaries.add(BeneficiaryData(
        firstName: '',
        surName: '',
        relationship: '', // Keep this empty - the dropdown will show hint text
        phoneNo: '',
        percentageBenefit: 0,
      ));
    });
  }

  void _removeBeneficiary(int index) {
    setState(() {
      _beneficiaries.removeAt(index);
    });
  }

  bool _validateBeneficiaries() {
    if (_beneficiaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one beneficiary'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    for (var i = 0; i < _beneficiaries.length; i++) {
      final ben = _beneficiaries[i];
      if (ben.firstName.isEmpty || ben.surName.isEmpty || ben.relationship.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all required fields for beneficiary ${i + 1}'),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    }

    // Check total allocation
    final totalAllocation = _beneficiaries.fold<double>(
      0,
      (sum, b) => sum + b.percentageBenefit,
    );

    if (totalAllocation != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Total allocation must be 100%. Current: ${totalAllocation.toStringAsFixed(1)}%'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return false;
    }

    return true;
  }

// KEY FIX: Replace the _saveChanges method with this corrected version

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

    // STEP 2: Fetch beneficiary CHANGES (not original beneficiaries)
    // This is the key fix - we need to fetch from MemberBeneficiaryChanges, not MemberChanges
    final beneficiaryChanges = await ApiService.fetchBeneficiaryChanges(
      accessToken: accessToken,
      changeRequestNo: _changeRequestNo!,
    );

    if (beneficiaryChanges.isEmpty) {
      throw Exception('No beneficiary changes found in change request');
    }

    debugPrint('📋 Found ${beneficiaryChanges.length} beneficiary changes');

    // STEP 3: Update each beneficiary change
    for (final beneficiaryChange in beneficiaryChanges) {
      // The ID here is the change record ID, not the original beneficiary ID
      final payload = {
        'id': beneficiaryChange['id'], // This is the change record ID
        'firstName': beneficiaryChange['firstName'] ?? '',
        'otherNames': beneficiaryChange['otherName'] ?? '',
        'surName': beneficiaryChange['lastName'] ?? '',
        'relationship': beneficiaryChange['relationship'] ?? '',
        'phoneNo': beneficiaryChange['phoneNo'] ?? '',
        'emailAddress': beneficiaryChange['emailAddress'] ?? '',
        'address': beneficiaryChange['address'] ?? '',
        'percentageBenefit': (beneficiaryChange['percentageBenefit'] ?? 0),
        'isPrimary': beneficiaryChange['isPrimary'] ?? false,
        'changeRequestNo': _changeRequestNo,
      };

      debugPrint('📝 PATCH BENEFICIARY CHANGE PAYLOAD: ${jsonEncode(payload)}');

      final success = await ApiService.updateBeneficiaryChanges(
        accessToken: accessToken,
        beneficiary: payload,
      );

      if (!success) {
        final name = '${payload['firstName']} ${payload['otherNames']} ${payload['surName']}'.trim();
        throw Exception('Failed to update beneficiary change for $name');
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
                'Changes submitted successfully',
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
    debugPrint('❌ Error saving changes: $e');
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
          'Back',
          style: TextStyle(color: Colors.black, fontSize: 16),
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
                    const Text(
                      'Edit Beneficiaries',
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
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Note: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Total allocation must equal 100%. Changes require approval.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Total Allocation Indicator
                    _buildAllocationIndicator(),
                    const SizedBox(height: 24),

                    // Beneficiaries List
                    ..._beneficiaries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final beneficiary = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildBeneficiaryCard(index, beneficiary),
                      );
                    }).toList(),

                    // Add Beneficiary Button
                    OutlinedButton.icon(
                      onPressed: _addBeneficiary,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Beneficiary'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE31E24),
                        side: const BorderSide(color: Color(0xFFE31E24)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                        minimumSize: const Size(double.infinity, 0),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE31E24),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
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

  Widget _buildAllocationIndicator() {
    final totalAllocation = _beneficiaries.fold<double>(
      0,
      (sum, b) => sum + b.percentageBenefit,
    );
    
    final isValid = totalAllocation == 100;
    final color = isValid ? Colors.green : (totalAllocation > 100 ? Colors.red : Colors.orange);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Allocation',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${totalAllocation.toStringAsFixed(1)}% / 100%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryCard(int index, BeneficiaryData beneficiary) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Beneficiary ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (_beneficiaries.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _removeBeneficiary(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildTextField('First Name', beneficiary.firstName, (value) {
            setState(() {
              _beneficiaries[index] = beneficiary.copyWith(firstName: value);
            });
          }),
          
          _buildTextField('Other Names (Optional)', beneficiary.otherNames, (value) {
            setState(() {
              _beneficiaries[index] = beneficiary.copyWith(otherNames: value);
            });
          }),
          
          _buildTextField('Surname', beneficiary.surName, (value) {
            setState(() {
              _beneficiaries[index] = beneficiary.copyWith(surName: value);
            });
          }),
          
          _buildRelationshipDropdown(index, beneficiary),
          
          _buildTextField('Phone Number', beneficiary.phoneNo, (value) {
            setState(() {
              _beneficiaries[index] = beneficiary.copyWith(phoneNo: value);
            });
          }, keyboardType: TextInputType.phone),
          
          _buildTextField('Email (Optional)', beneficiary.emailAddress, (value) {
            setState(() {
              _beneficiaries[index] = beneficiary.copyWith(emailAddress: value);
            });
          }, keyboardType: TextInputType.emailAddress),
          
          _buildTextField('Allocation (%)', beneficiary.percentageBenefit.toString(), (value) {
            final percentage = double.tryParse(value) ?? 0;
            setState(() {
              _beneficiaries[index] = beneficiary.copyWith(percentageBenefit: percentage);
            });
          }, keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F8),
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
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipDropdown(int index, BeneficiaryData beneficiary) {
    // Find a valid relationship code or use null if not found
    String? validRelationship;
    if (beneficiary.relationship.isNotEmpty) {
      // Check if the relationship exists in the list
      final exists = _relationships.any((rel) => rel['code'] == beneficiary.relationship);
      if (exists) {
        validRelationship = beneficiary.relationship;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Relationship',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: validRelationship, // This can now be null safely
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F8),
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
                horizontal: 12,
                vertical: 12,
              ),
            ),
            hint: const Text('Select Relationship'), // Add hint text
            items: _relationships.map((rel) {
              return DropdownMenuItem<String>(
                value: rel['code'],
                child: Text(rel['code'] ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _beneficiaries[index] = beneficiary.copyWith(relationship: value);
                });
              }
            },
          ),
        ],
      ),
    );
  }
}