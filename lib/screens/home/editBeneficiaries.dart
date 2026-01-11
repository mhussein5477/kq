import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kq/services/api_service.dart';
import 'package:kq/services/secure_storage_service.dart';

// Edit Beneficiaries Screen
class EditBeneficiariesScreen extends StatefulWidget {
  const EditBeneficiariesScreen({super.key});

  @override
  State<EditBeneficiariesScreen> createState() =>
      _EditBeneficiariesScreenState();
}

class _EditBeneficiariesScreenState extends State<EditBeneficiariesScreen> {
  final List<Map<String, dynamic>> beneficiaries = [
    {
      'fullName': 'Jane Doe',
      'relationship': 'Spouse',
      'phone': '+254 712 345 678',
      'allocation': '60',
      'isPrimary': true,
    },
    {
      'fullName': 'James Mwangi',
      'relationship': 'Father',
      'phone': '+254 712 345 678',
      'allocation': '40',
      'isPrimary': false,
    },
  ];

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
      body: SingleChildScrollView(
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
                        'Changes to beneficiary information require document upload for verification.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Primary Beneficiary
              const Text(
                'Primary Beneficiary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildBeneficiaryForm(beneficiaries[0]),

              const SizedBox(height: 24),

              // Secondary Beneficiary
              const Text(
                'Secondary Beneficiary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildBeneficiaryForm(beneficiaries[1]),

              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {},
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

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Beneficiaries updated successfully'),
                        backgroundColor: Color(0xFFE31E24),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31E24),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeneficiaryForm(Map<String, dynamic> beneficiary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildFormField('Full Name', beneficiary['fullName']),
          _buildFormField('Relationship', beneficiary['relationship']),
          _buildFormField('Phone Number', beneficiary['phone']),
          _buildFormField('Allocation (%)', beneficiary['allocation']),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('Upload Supporting Document'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE31E24),
              side: const BorderSide(color: Color(0xFFE31E24)),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String initialValue) {
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
            initialValue: initialValue,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
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
}
