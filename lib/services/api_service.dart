import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://api.lunapackagingltd.co.ke/kq/api/v1';
  static const String _erpBaseUrl =
      'https://kq-erp.defttech.co.ke:5648/KQ/ODataV4';

  static const companyId = 'd205f47c-2dc8-f011-9c69-000d3addc14a';

  static Future<Map<String, dynamic>> verifyMember({
    required String emailAddress,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/verifyMember');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"emailAddress": emailAddress}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Verification failed',
      );
    }
  }

  static Future<Map<String, dynamic>> verifyMemberOTP({
    required String emailAddress,
    required int otp,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/verifyMemberOTP');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"emailAddress": emailAddress, "otp": otp}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Invalid OTP');
    }
  }

  static Future<Map<String, dynamic>> signUp({
    required String emailAddress,
    required String password,
  }) async {
 
    final url = Uri.parse('$_baseUrl/auth/signUp');
   

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"emailAddress": emailAddress, "password": password}),
    );

    print('SIGN UP STATUS: ${response.statusCode}');
    print('SIGN UP RESPONSE: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Signup failed');
    }
  }

// FIXED: signIn method with better error handling
// Replace your existing signIn method with this:

  static Future<Map<String, dynamic>> signIn({
    required String emailAddress,
    required String password,
  }) async {
    print('$_baseUrl/auth/signIn');
    final url = Uri.parse('$_baseUrl/auth/signIn');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"emailAddress": emailAddress, "password": password}),
      );

      print('Login Status Code: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      final decoded = jsonDecode(response.body);
      print('Login Decoded: $decoded');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if success field exists and is true, or just return if status is 200/201
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('success')) {
            if (decoded['success'] == true) {
              return decoded;
            } else {
              throw Exception(decoded['message'] ?? 'Login failed');
            }
          } else {
            // If no success field, assume success based on status code
            return decoded;
          }
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        final errorMessage = decoded is Map<String, dynamic> 
            ? (decoded['message'] ?? 'Login failed')
            : 'Login failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        print('Format Exception: ${e.toString()}');
        throw Exception('Invalid response format from server');
      }
      rethrow;
    }
  }
  static Future<Map<String, dynamic>> verifyMfa({
    required String emailAddress,
    required int otp,
    required String mfaToken,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/verify');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'X-Mfa-Token': mfaToken},
      body: jsonEncode({"emailAddress": emailAddress, "otp": otp}),
    );

    final decoded = jsonDecode(response.body);
    print('MFA VERIFY STATUS: ${response.statusCode}');
    print('MFA VERIFY RESPONSE: $decoded');

    if (response.statusCode == 200 && decoded['success'] == true) {
      return decoded;
    } else {
      throw Exception(decoded['message'] ?? 'MFA verification failed');
    }
  }

  static Future<Map<String, dynamic>> fetchMemberDetails({
    required String accessToken,
    required String memberNo,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_memberDetails?company=$companyId',
    );

    final body = jsonEncode({
      "request": "[{\"requestId\":01,\"requestBody\":{\"no\":\"$memberNo\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to fetch member details (${response.statusCode})',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMemberBeneficiaries({
    required String accessToken,
    required String memberNo,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_memberBeneficiaries?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"requestBody\":{\"memberNo\":\"$memberNo\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    final outer = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch beneficiaries');
    }

    final inner = jsonDecode(outer['value']);
    final values = inner['values'];

    if (values == null || values.isEmpty) return [];

    final first = values.first;

    if (first is List) {
      return List<Map<String, dynamic>>.from(first);
    }

    if (first is Map<String, dynamic>) {
      return [first];
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchMemberNextOfKin({
    required String accessToken,
    required String memberNo,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_memberNextOfKins?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"requestBody\":{\"memberNo\":\"$memberNo\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    final outer = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch next of kin');
    }

    final inner = jsonDecode(outer['value']);
    final values = inner['values'];

    if (values == null || values.isEmpty) return [];

    final first = values.first;

    if (first is List) {
      return List<Map<String, dynamic>>.from(first);
    }

    if (first is Map<String, dynamic>) {
      return [first];
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchMemberSpouses({
    required String accessToken,
    required String memberNo,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_memberSpouses?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"requestBody\":{\"memberNo\":\"$memberNo\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    final outer = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch member spouses');
    }

    final inner = jsonDecode(outer['value']);
    final values = inner['values'];

    if (values == null || values.isEmpty) return [];

    final first = values.first;

    if (first is List) {
      return List<Map<String, dynamic>>.from(first);
    }

    if (first is Map<String, dynamic>) {
      return [first];
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchMemberGuardians({
    required String accessToken,
    required String memberNo,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_memberGuardians?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"requestBody\":{\"memberNo\":\"$memberNo\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    final outer = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch member guardians');
    }

    final inner = jsonDecode(outer['value']);
    final values = inner['values'];

    if (values == null || values.isEmpty) return [];

    final first = values.first;

    if (first is List) {
      return List<Map<String, dynamic>>.from(first);
    }

    if (first is Map<String, dynamic>) {
      return [first];
    }

    return [];
  }

  // ==================== CHANGE REQUEST MANAGEMENT ====================

  /// Initiate a change request for a member
  /// Returns the change request document details
  static Future<Map<String, dynamic>> initiateChangeRequest({
    required String accessToken,
    required String memberNo,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_IniateChangeRequest?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"requestBody\":{\"memberNo\":\"$memberNo\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('📝 INITIATE CHANGE REQUEST STATUS: ${response.statusCode}');
    print('📝 INITIATE CHANGE REQUEST RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);
      
      print('🔍 Parsed inner response: $inner');
      
      // Handle the actual response structure
      // Response format: {"values": [{"requestId": "1", "values": {"changeRequestNo": "CHG-08"}}]}
      if (inner['values'] != null && inner['values'] is List && inner['values'].isNotEmpty) {
        final valuesArray = inner['values'] as List;
        final firstItem = valuesArray[0];
        
        print('🔍 First item: $firstItem');
        
        if (firstItem is Map<String, dynamic>) {
          // Check if there's a nested 'values' object containing the changeRequestNo
          if (firstItem['values'] != null && firstItem['values'] is Map) {
            final changeRequestData = firstItem['values'] as Map<String, dynamic>;
            final changeRequestNo = changeRequestData['changeRequestNo'];
            
            print('✅ Found changeRequestNo: $changeRequestNo');
            
            // Return with both 'no' and 'changeRequestNo' for compatibility
            return {
              'no': changeRequestNo,
              'changeRequestNo': changeRequestNo,
              // Note: The API doesn't return an 'id', so we'll use the changeRequestNo
              // for identification. We'll need to fetch the full details using getChangeRequestDetails
              // if we need the actual system ID
              'needsFullDetails': true,
            };
          }
          
          // Fallback to returning the first item as-is
          return firstItem;
        }
      }
      
      throw Exception('Invalid change request response structure: $inner');
    } else {
      throw Exception(
        'Failed to initiate change request (${response.statusCode})',
      );
    }
  }

  /// Get change request details with optional related data
  /// includeNOKChanges: Include next of kin changes
  /// includeBeneficiaryChanges: Include beneficiary changes
  /// includeSpouseChanges: Include spouse changes
  /// includeGuardianChanges: Include guardian changes
  static Future<Map<String, dynamic>> getChangeRequestDetails({
    required String accessToken,
    required String changeRequestNo,
    bool includeNOKChanges = false,
    bool includeBeneficiaryChanges = false,
    bool includeSpouseChanges = false,
    bool includeGuardianChanges = false,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_MemberChanges?company=$companyId',
    );

    // Build request body with optional flags
    final requestBody = <String, dynamic>{
      'changeRequestNo': changeRequestNo,
    };
    
    if (includeNOKChanges) requestBody['includeNOKChanges'] = 'True';
    if (includeBeneficiaryChanges) {
      requestBody['includeBeneficiaryChanges'] = 'True';
    }
    if (includeSpouseChanges) requestBody['includeSpouseChanges'] = 'True';
    if (includeGuardianChanges) requestBody['includeGuardianChanges'] = 'True';

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"GET\",\"requestBody\":${jsonEncode(requestBody)}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('🔍 GET CHANGE REQUEST STATUS: ${response.statusCode}');

    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);
      
      print('🔍 Parsed inner: $inner');
      
      // Response structure: 
      // {
      //   "message": "...",
      //   "values": [{
      //     "requestId": "1",
      //     "status": "success", 
      //     "values": [
      //       {"id": "...", "changeType": "Change Value", ...},
      //       {"id": "...", "changeType": "Previous Value", ...}
      //     ]
      //   }]
      // }
      
      if (inner['values'] != null && inner['values'] is List) {
        final outerValuesArray = inner['values'] as List;
        
        if (outerValuesArray.isNotEmpty) {
          final responseWrapper = outerValuesArray[0];
          
          // Now get the actual change request data from the nested 'values'
          if (responseWrapper is Map<String, dynamic> && 
              responseWrapper['values'] != null && 
              responseWrapper['values'] is List) {
            
            final changeRequestArray = responseWrapper['values'] as List;
            
            if (changeRequestArray.isNotEmpty) {
              final firstChangeRequest = changeRequestArray[0];
              
              if (firstChangeRequest is Map<String, dynamic>) {
                print('🔍 Found change request: ${firstChangeRequest['changeType']} - ID: ${firstChangeRequest['id']}');
                return firstChangeRequest;
              }
            }
          }
        }
      }
      
      print('⚠️ Unexpected response structure');
      return {};
    } else {
      throw Exception(
        'Failed to get change request details (${response.statusCode})',
      );
    }
  }

  /// Update member change request (PATCH)
  /// This updates the main member details in a change request
  static Future<Map<String, dynamic>> updateMemberChanges({
    required String accessToken,
    required String changeRequestId,
    required Map<String, dynamic> changes,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_MemberChanges?company=$companyId',
    );

    final requestBody = {
      'id': changeRequestId,
      ...changes,
    };

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"PATCH\",\"requestBody\":${jsonEncode(requestBody)}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('✏️ UPDATE MEMBER CHANGES STATUS: ${response.statusCode}');

    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);
      
      if (inner['values'] != null && inner['values'].isNotEmpty) {
        final values = inner['values'];
        final firstValue = values[0];
        
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue[0] as Map<String, dynamic>;
        } else if (firstValue is Map<String, dynamic>) {
          return firstValue;
        }
      }
      
      return {};
    } else {
      throw Exception('Failed to update member changes (${response.statusCode})');
    }
  }

  /// Submit member changes for approval
  /// This finalizes the change request and sends it for approval
  static Future<bool> submitMemberChanges({
    required String accessToken,
    required String changeRequestId,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_SubmitMemberChanges?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"GET\",\"requestBody\":{\"id\":\"$changeRequestId\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('✅ SUBMIT MEMBER CHANGES STATUS: ${response.statusCode}');
    print('✅ SUBMIT MEMBER CHANGES RESPONSE: ${response.body}');

    return response.statusCode == 200;
  }

  /// Upload member picture change as base64
  static Future<bool> uploadMemberPicture({
    required String accessToken,
    required String changeRequestId,
    required String fileName,
    required String pictureBase64,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_MemberChangeImage?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"GET\",\"requestBody\":{\"id\":\"$changeRequestId\",\"fileName\":\"$fileName\",\"pictureBase64\":\"$pictureBase64\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('📸 UPLOAD PICTURE STATUS: ${response.statusCode}');
    return response.statusCode == 200;
  }

  /// Fetch relationships (for dropdown lists)
static Future<List<Map<String, dynamic>>> fetchRelationships({
  required String accessToken,
}) async {
  final url = Uri.parse(
    '$_erpBaseUrl/MSSIntegration_Relationships?company=$companyId',
  );

  final body = jsonEncode({
    "request": "[{\"requestId\":01,\"method\":\"GET\",\"requestBody\":{}}]",
  });

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: body,
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch relationships (${response.statusCode})');
  }

  final outer = jsonDecode(response.body);
  final inner = jsonDecode(outer['value']);

  final List values = inner['values'];
  if (values.isEmpty) return [];

  // 🔥 THIS is the missing step
  final Map<String, dynamic> first = values.first;

  final List relationships = first['values'] ?? [];

  return List<Map<String, dynamic>>.from(relationships);
}

  /// Fetch banks (for dropdown lists)
  static Future<List<Map<String, dynamic>>> fetchBanks({
    required String accessToken,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_Banks?company=$companyId',
    );

    final body = jsonEncode({
      "request": "[{\"requestId\":01,\"method\":\"GET\",\"requestBody\":{}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);
      final values = inner['values'];

      if (values == null || values.isEmpty) return [];

      final first = values.first;

      if (first is List) {
        return List<Map<String, dynamic>>.from(first);
      }

      if (first is Map<String, dynamic>) {
        return [first];
      }

      return [];
    } else {
      throw Exception('Failed to fetch banks (${response.statusCode})');
    }
  }

  // ==================== REPORTS ====================

  /// Generate Member Statement (Benefit Statement)
  /// Returns base64 encoded gzipped PDF report
  static Future<String> generateMemberStatement({
    required String accessToken,
    required String memberNo,
    required String startDate, // Format: "YYYY-MM-DD"
    required String endDate, // Format: "YYYY-MM-DD"
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_GenerateMemberStatement?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"GET\",\"requestBody\":{\"memberNo\":\"$memberNo\",\"startDate\":\"$startDate\",\"endDate\":\"$endDate\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('📊 MEMBER STATEMENT STATUS: ${response.statusCode}');

    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final innerJson = jsonDecode(outer['value']);

      if (innerJson['values'] != null && innerJson['values'].isNotEmpty) {
        final valuesList = innerJson['values'];
        final firstValue = valuesList[0];
        final base64Report = firstValue['base64GzipReport'] as String? ?? '';

        if (base64Report.isEmpty) {
          throw Exception('Base64 report data is empty');
        }

        return base64Report;
      }

      throw Exception('Report data not found in response structure');
    } else {
      throw Exception(
        'Failed to generate member statement (${response.statusCode})',
      );
    }
  }

  /// Generate Contribution Statement
  /// Returns base64 encoded gzipped PDF report
  static Future<String> generateContributionStatement({
    required String accessToken,
    required String memberNo,
    String? startDate,
    String? endDate,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_GenerateContributionStatement?company=$companyId',
    );

    final requestBody = <String, String>{'memberNo': memberNo};
    if (startDate != null) requestBody['startDate'] = startDate;
    if (endDate != null) requestBody['endDate'] = endDate;

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"GET\",\"requestBody\":${jsonEncode(requestBody)}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('📊 CONTRIBUTION STATEMENT STATUS: ${response.statusCode}');

    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final innerJson = jsonDecode(outer['value']);

      if (innerJson['values'] != null && innerJson['values'].isNotEmpty) {
        final valuesList = innerJson['values'];
        final firstValue = valuesList[0];
        final base64Report = firstValue['base64GzipReport'] as String? ?? '';

        if (base64Report.isEmpty) {
          throw Exception('Base64 report data is empty');
        }

        return base64Report;
      }

      throw Exception('Report data not found in response structure');
    } else {
      throw Exception(
        'Failed to generate contribution statement (${response.statusCode})',
      );
    }
  }

  /// Generate Member Certificate
  /// Returns base64 encoded gzipped PDF report
  static Future<String> generateMemberCertificate({
    required String accessToken,
    required String memberNo,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_GenerateMemberCertificate?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"GET\",\"requestBody\":{\"memberNo\":\"$memberNo\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('📊 MEMBER CERTIFICATE STATUS: ${response.statusCode}');

    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final innerJson = jsonDecode(outer['value']);

      if (innerJson['values'] != null && innerJson['values'].isNotEmpty) {
        final valuesList = innerJson['values'];
        final firstValue = valuesList[0];
        final base64Report = firstValue['base64GzipReport'] as String? ?? '';

        if (base64Report.isEmpty) {
          throw Exception('Base64 report data is empty');
        }

        return base64Report;
      }

      throw Exception('Report data not found in response structure');
    } else {
      throw Exception(
        'Failed to generate member certificate (${response.statusCode})',
      );
    }
  }


  // Add these methods to your ApiService class

  /// Fetch beneficiary change requests for a member
  static Future<List<Map<String, dynamic>>> fetchBeneficiaryChanges({
    required String accessToken,
    required String changeRequestNo,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_MemberBeneficiaryChanges?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"GET\",\"requestBody\":{\"changeRequestNo\":\"$changeRequestNo\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('📋 FETCH BENEFICIARY CHANGES STATUS: ${response.statusCode}');

    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);

      if (inner['values'] != null && inner['values'] is List) {
        final outerValuesArray = inner['values'] as List;
        
        if (outerValuesArray.isNotEmpty) {
          final responseWrapper = outerValuesArray[0];
          
          if (responseWrapper is Map<String, dynamic> && 
              responseWrapper['values'] != null && 
              responseWrapper['values'] is List) {
            
            final beneficiariesArray = responseWrapper['values'] as List;
            return beneficiariesArray
                .whereType<Map<String, dynamic>>()
                .toList();
          }
        }
      }
      
      return [];
    } else {
      throw Exception('Failed to fetch beneficiary changes (${response.statusCode})');
    }
  }

  /// Add or update beneficiary in change request
static Future<bool> updateBeneficiaryChanges({
  required String accessToken,
  required Map<String, dynamic> beneficiary, // SINGLE object
}) async {
  final url = Uri.parse(
    '$_erpBaseUrl/MSSIntegration_MemberBeneficiaryChanges?company=$companyId',
  );

  final requestList = [
    {
      "requestId": 1,
      "method": "PATCH",
      "requestBody": beneficiary, // must include 'id' + 'changeRequestNo'
    }
  ];

  final body = jsonEncode({
    "request": jsonEncode(requestList).replaceAll(RegExp(r'\s+'), ''),
  });

  print('📝 UPDATE BENEFICIARY REQUEST BODY: $body');

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: body,
  );

  print('📝 UPDATE BENEFICIARY STATUS: ${response.statusCode}');
  print('📝 UPDATE BENEFICIARY RESPONSE: ${response.body}');

  return response.statusCode == 200;
}

  /// Delete beneficiary from change request
  static Future<bool> deleteBeneficiaryChange({
    required String accessToken,
    required String changeRequestId,
    required String beneficiaryLineNo,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_MemberBeneficiaryChanges?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"DELETE\",\"requestBody\":{\"changeRequestId\":\"$changeRequestId\",\"lineNo\":\"$beneficiaryLineNo\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('🗑️ DELETE BENEFICIARY STATUS: ${response.statusCode}');

    return response.statusCode == 200;
  }

  /// Fetch available relationships for beneficiaries
  static Future<List<Map<String, dynamic>>> fetchBeneficiaryRelationships({
    required String accessToken,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_Relationships?company=$companyId',
    );

    final body = jsonEncode({
      "request": "[{\"requestId\":01,\"method\":\"GET\"}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);

      if (inner['values'] != null && inner['values'] is List) {
        final outerArray = inner['values'] as List;
        if (outerArray.isNotEmpty && outerArray[0]['values'] is List) {
          return (outerArray[0]['values'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }
      
      return [];
    } else {
      throw Exception('Failed to fetch relationships');
    }
  }

  // Add these methods to your ApiService class

/// Fetch Next of Kin change requests for a member
static Future<List<Map<String, dynamic>>> fetchNOKChanges({
  required String accessToken,
  required String changeRequestNo,
}) async {
  final url = Uri.parse(
    '$_erpBaseUrl/MSSIntegration_MemberNOKChanges?company=$companyId',
  );

  final body = jsonEncode({
    "request":
        "[{\"requestId\":01,\"method\":\"GET\",\"requestBody\":{\"changeRequestNo\":\"$changeRequestNo\"}}]",
  });

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: body,
  );

  print('📋 FETCH NOK CHANGES STATUS: ${response.statusCode}');

  if (response.statusCode == 200) {
    final outer = jsonDecode(response.body);
    final inner = jsonDecode(outer['value']);

    if (inner['values'] != null && inner['values'] is List) {
      final outerValuesArray = inner['values'] as List;
      
      if (outerValuesArray.isNotEmpty) {
        final responseWrapper = outerValuesArray[0];
        
        if (responseWrapper is Map<String, dynamic> && 
            responseWrapper['values'] != null && 
            responseWrapper['values'] is List) {
          
          final nokArray = responseWrapper['values'] as List;
          return nokArray
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }
    }
    
    return [];
  } else {
    throw Exception('Failed to fetch NOK changes (${response.statusCode})');
  }
}

/// Update Next of Kin in change request
static Future<bool> updateNOKChanges({
  required String accessToken,
  required Map<String, dynamic> nextOfKin, // SINGLE object
}) async {
  final url = Uri.parse(
    '$_erpBaseUrl/MSSIntegration_MemberNOKChanges?company=$companyId',
  );

  final requestList = [
    {
      "requestId": 1,
      "method": "PATCH",
      "requestBody": nextOfKin, // must include 'id' + 'changeRequestNo'
    }
  ];

  final body = jsonEncode({
    "request": jsonEncode(requestList).replaceAll(RegExp(r'\s+'), ''),
  });

  print('📝 UPDATE NOK REQUEST BODY: $body');

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: body,
  );

  print('📝 UPDATE NOK STATUS: ${response.statusCode}');
  print('📝 UPDATE NOK RESPONSE: ${response.body}');

  return response.statusCode == 200;
}

/// Delete Next of Kin from change request
static Future<bool> deleteNOKChange({
  required String accessToken,
  required String changeRequestId,
  required String nokLineNo,
}) async {
  final url = Uri.parse(
    '$_erpBaseUrl/MSSIntegration_MemberNOKChanges?company=$companyId',
  );

  final body = jsonEncode({
    "request":
        "[{\"requestId\":01,\"method\":\"DELETE\",\"requestBody\":{\"changeRequestId\":\"$changeRequestId\",\"lineNo\":\"$nokLineNo\"}}]",
  });

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: body,
  );

  print('🗑️ DELETE NOK STATUS: ${response.statusCode}');

  return response.statusCode == 200;
}
}