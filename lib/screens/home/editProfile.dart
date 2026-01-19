import 'dart:convert';
import 'package:expressive_loading_indicator/expressive_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';
import 'package:kq/services/upload_service.dart';

// ============================================================================
// COLORS & CONSTANTS
// ============================================================================

class AppColors {
  static const primary = Color(0xFFE31E24);
  static const success = Color(0xFF10B981);
  static const surfaceDarker = Color(0xFF2A2A2A);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF666666);
  static const backgroundLight = Color(0xFFF5F5F8);
}

// ============================================================================
// BENEFICIARY DATA MODEL
// ============================================================================

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

// ============================================================================
// EDIT PROFILE SCREEN
// ============================================================================

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

  UploadFile? _profilePicture;
  UploadFile? _idDocument;
  UploadFile? _kraDocument;

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
            SnackBar(content: Text(error), backgroundColor: Colors.red),
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
            SnackBar(content: Text(error), backgroundColor: Colors.red),
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
            SnackBar(content: Text(error), backgroundColor: Colors.red),
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

      debugPrint('🚀 Creating new change request for profile changes...');
      await _initiateChangeRequest();

      if (_changeRequestId == null || _changeRequestNo == null) {
        throw Exception('Failed to get change request ID or number');
      }

      debugPrint('✅ Change request created: $_changeRequestNo (ID: $_changeRequestId)');

      final crDetails = await ApiService.getChangeRequestDetails(
        accessToken: accessToken,
        changeRequestNo: _changeRequestNo!,
      );

      debugPrint('🔍 Change request details: ${jsonEncode(crDetails)}');

      if (crDetails['id'] == null) {
        throw Exception('No member change record found in change request');
      }

      final fullName = _fullNameController.text.trim();
      final nameParts = fullName.split(' ');

      String firstName = '';
      String otherName = '';
      String lastName = '';

      if (nameParts.length >= 3) {
        firstName = nameParts[0];
        lastName = nameParts.last;
        otherName = nameParts.sublist(1, nameParts.length - 1).join(' ');
      } else if (nameParts.length == 2) {
        firstName = nameParts[0];
        lastName = nameParts[1];
      } else if (nameParts.length == 1) {
        firstName = nameParts[0];
      }

      final updates = {
        'firstName': firstName,
        'otherName': otherName,
        'lastName': lastName,
        'idNo': _idNumberController.text.trim(),
        'kraPin': _kraPinController.text.trim(),
        'emailAddress': _emailController.text.trim(),
        'phoneNo': _phoneController.text.trim(),
        'address': _postalAddressController.text.trim(),
      };

      debugPrint('📝 PATCH MEMBER CHANGES PAYLOAD: ${jsonEncode(updates)}');

      await ApiService.updateMemberChanges(
        accessToken: accessToken,
        changeRequestId: _changeRequestId!,
        changes: updates,
      );

      debugPrint('✅ Member changes updated successfully');

      if (_profilePicture != null) {
        debugPrint('📸 Uploading profile picture...');
        final base64Picture = base64Encode(_profilePicture!.fileBytes);
        await ApiService.uploadMemberPicture(
          accessToken: accessToken,
          changeRequestId: _changeRequestId!,
          fileName: _profilePicture!.fileName,
          pictureBase64: base64Picture,
        );
        debugPrint('✅ Profile picture uploaded');
      }

      if (_idDocument != null) {
        debugPrint('⚠️ ID document selected but upload endpoint not available');
      }
      if (_kraDocument != null) {
        debugPrint('⚠️ KRA document selected but upload endpoint not available');
      }

      debugPrint('✅ Submitting change request for approval...');
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
                  'Profile changes submitted successfully',
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
      debugPrint('❌ Error saving profile changes: $e');
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
          'Back',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: ExpressiveLoadingIndicator(
                color: isDarkMode ? Colors.red[300] : Colors.red,
              ),
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
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoContainer(isDarkMode),
                      const SizedBox(height: 24),
                      _buildProfilePictureSection(isDarkMode),
                      const SizedBox(height: 24),
                      _buildTextField(
                        'Full Name',
                        _fullNameController,
                        isDarkMode,
                      ),
                      _buildTextField(
                        'ID Number',
                        _idNumberController,
                        isDarkMode,
                      ),
                      _buildUploadButton(
                        'Upload ID Card',
                        icon: Icons.upload_file,
                        uploaded: _idDocument != null,
                        fileName: _idDocument?.fileName,
                        onPressed: _pickIdDocument,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'KRA PIN',
                        _kraPinController,
                        isDarkMode,
                      ),
                      _buildUploadButton(
                        'Upload KRA Certificate',
                        icon: Icons.upload_file,
                        uploaded: _kraDocument != null,
                        fileName: _kraDocument?.fileName,
                        onPressed: _pickKraDocument,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Email',
                        _emailController,
                        isDarkMode,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        'Phone Number',
                        _phoneController,
                        isDarkMode,
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(
                        'Postal Address',
                        _postalAddressController,
                        isDarkMode,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
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

  Widget _buildInfoContainer(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.blue[900]!.withOpacity(0.3)
            : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Note: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.blue[300] : const Color(0xFF1976D2),
            ),
          ),
          Expanded(
            child: Text(
              'Changes to ID Number and KRA PIN require document upload for verification. All changes will be submitted for approval.',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.blue[200] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePictureSection(bool isDarkMode) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  backgroundImage: _profilePicture != null
                      ? MemoryImage(_profilePicture!.fileBytes)
                      : null,
                  child: _profilePicture == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey,
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
                      color: AppColors.primary,
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
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
              ),
            ),
            Text(
              '${_profilePicture!.fileSizeInMB.toStringAsFixed(2)} MB',
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? Colors.white54 : Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isDarkMode, {
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDarkMode ? AppColors.surfaceDarker : Colors.white,
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
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(uploaded ? 'Change Document' : label),
          style: OutlinedButton.styleFrom(
            foregroundColor: uploaded ? AppColors.success : AppColors.primary,
            side: BorderSide(
              color: uploaded ? AppColors.success : AppColors.primary,
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
              const Icon(Icons.check_circle, color: AppColors.success, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
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