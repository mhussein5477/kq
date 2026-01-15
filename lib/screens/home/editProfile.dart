import 'dart:convert';

import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';
import 'package:kq/services/upload_service.dart';

class Beneficiary {
  String id;
  String firstName;
  String otherNames;
  String surName;
  String relationship;
  String phoneNo;
  String emailAddress;
  String address;
  double percentageBenefit;
  bool isPrimary;

  Beneficiary({
    required this.id,
    required this.firstName,
    required this.otherNames,
    required this.surName,
    required this.relationship,
    required this.phoneNo,
    required this.emailAddress,
    required this.address,
    required this.percentageBenefit,
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
      'percentageBenefit': percentageBenefit,
      'isPrimary': isPrimary,
    };
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _kraPinController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _postalAddressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _changeRequestNo;
  String? _changeRequestId;
  Map<String, dynamic>? _memberData;

  // Upload state
  UploadFile? _profilePicture;
  UploadFile? _idDocument;
  UploadFile? _kraDocument;

  // Beneficiaries list
  List<Beneficiary> _beneficiaries = [];

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    try {
      setState(() => _isLoading = true);

      final accessToken = await SecureStorageService.getAccessToken();
      final memberDetails = await SecureStorageService.getMemberDetails();
      final memberNo = memberDetails['memberNo'];

      if (accessToken == null || memberNo == null) {
        throw Exception('Authentication data missing');
      }

      final response = await ApiService.fetchMemberDetails(
        accessToken: accessToken,
        memberNo: memberNo,
      );

      final decodedValue = jsonDecode(response['value']);
      final member = decodedValue['values'][0][0];

      setState(() {
        _memberData = member;

        _fullNameController.text =
            '${member['firstName'] ?? ''} ${member['otherName'] ?? ''} ${member['lastName'] ?? ''}'
                .trim();
        _idNumberController.text = member['idNo'] ?? '';
        _kraPinController.text = member['pin'] ?? '';
        _emailController.text = member['emailAddress'] ?? '';
        _phoneController.text = member['phoneNo'] ?? '';
        _postalAddressController.text = member['address'] ?? '';

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading member data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load member data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickProfilePicture() async {
    final file = await UploadService.showImageSourceDialog(context);

    if (file != null) {
      final error = file.getValidationError(
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        maxSizeMB: 5.0,
      );

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _profilePicture = file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture selected: ${file.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _pickIdDocument() async {
    final file = await UploadService.pickDocument(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (file != null) {
      final error = file.getValidationError(maxSizeMB: 5.0);

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _idDocument = file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ID document selected: ${file.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _pickKraDocument() async {
    final file = await UploadService.pickDocument(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (file != null) {
      final error = file.getValidationError(maxSizeMB: 5.0);

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _kraDocument = file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('KRA document selected: ${file.fileName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  bool _validateDocumentRequirements() {
    final idChanged = _idNumberController.text != _memberData?['idNo'];
    final kraChanged = _kraPinController.text != _memberData?['pin'];

    if (idChanged && _idDocument == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'ID card document is required when changing ID number'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return false;
    }

    if (kraChanged && _kraDocument == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KRA certificate is required when changing KRA PIN'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return false;
    }

    return true;
  }

  Future<void> _initiateChangeRequest() async {
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
    );

    setState(() {
      _changeRequestNo = changeRequestNo;
      _changeRequestId = fullDetails['id'];
    });

    if (_changeRequestId == null) {
      throw Exception('Could not extract ID from change request details');
    }
  }

Future<void> _saveChanges() async {
  if (!_validateDocumentRequirements()) return;

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

    // STEP 2: Fetch beneficiaries from existing change request
    final crDetails = await ApiService.getChangeRequestDetails(
      accessToken: accessToken,
      changeRequestNo: _changeRequestNo!,
    );

    // Extract current beneficiaries from the change request
    final crValues = crDetails['values']?[0]['values'] as List<dynamic>?;

    if (crValues == null || crValues.isEmpty) {
      throw Exception('No beneficiaries found in change request');
    }

    _beneficiaries = crValues.map((b) {
      return Beneficiary(
        id: b['id'],
        firstName: b['firstName'] ?? '',
        otherNames: b['otherName'] ?? '',
        surName: b['lastName'] ?? '',
        relationship: b['relationship'] ?? '',
        phoneNo: b['phoneNo'] ?? '',
        emailAddress: b['emailAddress'] ?? '',
        address: b['address'] ?? '',
        percentageBenefit: (b['percentageBenefit'] ?? 0).toDouble(),
        isPrimary: b['isPrimary'] ?? false,
      );
    }).toList();

    // STEP 3: Update each beneficiary
    for (final beneficiary in _beneficiaries) {
      final payload = beneficiary.toMap();
      payload['changeRequestNo'] = _changeRequestNo;

      debugPrint('📝 PATCH BENEFICIARY PAYLOAD: ${jsonEncode(payload)}');

      final success = await ApiService.updateBeneficiaryChanges(
        accessToken: accessToken,
        beneficiary: payload,
      );

      if (!success) {
        throw Exception('Failed to update beneficiary ${beneficiary.fullName}');
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
                'Beneficiary changes submitted successfully',
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
    debugPrint('❌ Error saving beneficiaries: $e');
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
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    _kraPinController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _postalAddressController.dispose();
    super.dispose();
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
          ? const Center(
              child: ExpressiveLoadingIndicator(color: Colors.red),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Profile',
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
                                'Changes to ID Number and KRA PIN require document upload for verification. All changes will be submitted for approval.',
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
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFE31E24),
                                      width: 3,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: _profilePicture != null
                                        ? MemoryImage(_profilePicture!.fileBytes)
                                        : null,
                                    child: _profilePicture == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickProfilePicture,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE31E24),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_profilePicture != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _profilePicture!.fileName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${_profilePicture!.fileSizeInMB.toStringAsFixed(2)} MB',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField('Full Name', _fullNameController),
                      _buildTextField('ID Number', _idNumberController),
                      _buildUploadButton(
                        'Upload ID Card',
                        icon: Icons.upload_file,
                        uploaded: _idDocument != null,
                        fileName: _idDocument?.fileName,
                        onPressed: _pickIdDocument,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('KRA PIN', _kraPinController),
                      _buildUploadButton(
                        'Upload KRA Certificate',
                        icon: Icons.upload_file,
                        uploaded: _kraDocument != null,
                        fileName: _kraDocument?.fileName,
                        onPressed: _pickKraDocument,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Email',
                        _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        'Phone Number',
                        _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        'Postal Address',
                        _postalAddressController,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),
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
                                  child: ExpressiveLoadingIndicator(
                                    color: Colors.white,
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
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
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
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(
    String label, {
    required IconData icon,
    required bool uploaded,
    String? fileName,
    required VoidCallback onPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(uploaded ? 'Change Document' : label),
          style: OutlinedButton.styleFrom(
            foregroundColor: uploaded ? Colors.green : const Color(0xFFE31E24),
            side: BorderSide(
              color: uploaded ? Colors.green : const Color(0xFFE31E24),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
        if (uploaded && fileName != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
