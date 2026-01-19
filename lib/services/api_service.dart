import 'dart:convert';
import 'package:archive/archive.dart';
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

      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      final decoded = jsonDecode(response.body);
      print('Login Decoded: $decoded');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('success')) {
            if (decoded['success'] == true) {
              return decoded;
            } else {
              throw Exception(decoded['message'] ?? 'Login failed');
            }
          } else {
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
    final decoded = jsonDecode(response.body);
    print('MEMBER DETAILS STATUS: ${response.statusCode}');
    print('MEMBER DETAILS: $decoded');
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
      
      if (inner['values'] != null && inner['values'] is List && inner['values'].isNotEmpty) {
        final valuesArray = inner['values'] as List;
        final firstItem = valuesArray[0];
        
        print('🔍 First item: $firstItem');
        
        if (firstItem is Map<String, dynamic>) {
          if (firstItem['values'] != null && firstItem['values'] is Map) {
            final changeRequestData = firstItem['values'] as Map<String, dynamic>;
            final changeRequestNo = changeRequestData['changeRequestNo'];
            
            print('✅ Found changeRequestNo: $changeRequestNo');
            
            return {
              'no': changeRequestNo,
              'changeRequestNo': changeRequestNo,
              'needsFullDetails': true,
            };
          }
          
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
      
      if (inner['values'] != null && inner['values'] is List) {
        final outerValuesArray = inner['values'] as List;
        
        if (outerValuesArray.isNotEmpty) {
          final responseWrapper = outerValuesArray[0];
          
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

    final Map<String, dynamic> first = values.first;

    final List relationships = first['values'] ?? [];

    return List<Map<String, dynamic>>.from(relationships);
  }

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

  static Future<String> generateMemberStatement({
    required String accessToken,
    required String memberNo,
    required String startDate,
    required String endDate,
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

  // ==================== BENEFICIARIES ====================

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

  static Future<bool> updateBeneficiaryChanges({
    required String accessToken,
    required Map<String, dynamic> beneficiary,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_MemberBeneficiaryChanges?company=$companyId',
    );

    final requestList = [
      {
        "requestId": 1,
        "method": "PATCH",
        "requestBody": beneficiary,
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

  // ==================== NEXT OF KIN ====================

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

  static Future<bool> updateNOKChanges({
    required String accessToken,
    required Map<String, dynamic> nextOfKin,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_MemberNOKChanges?company=$companyId',
    );

    final requestList = [
      {
        "requestId": 1,
        "method": "PATCH",
        "requestBody": nextOfKin,
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

  // ==================== INTERACTIONS (ENQUIRIES/COMPLAINTS) ====================

  /// Fetch all interactions for a member
  /// includeComments: Include comments/replies for each interaction
  /// type: Filter by type (Enquiry, Complaint, Feedback, Other)
  static Future<List<Map<String, dynamic>>> fetchInteractions({
    required String accessToken,
    String? memberNo,
    bool includeComments = false,
    String? type,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_Interactions?company=$companyId',
    );

    final requestBody = <String, dynamic>{};
    if (memberNo != null) requestBody['clientNo'] = memberNo; // API uses 'clientNo'
    if (includeComments) requestBody['includeComments'] = 'True';
    if (type != null) requestBody['type'] = type;

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

    print('📋 FETCH INTERACTIONS STATUS: ${response.statusCode}');
    print('📋 FETCH INTERACTIONS RESPONSE: ${response.body}');

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
            
            final interactionsArray = responseWrapper['values'] as List;
            return interactionsArray
                .whereType<Map<String, dynamic>>()
                .toList();
          }
        }
      }
      
      return [];
    } else {
      throw Exception('Failed to fetch interactions (${response.statusCode})');
    }
  }

  /// Create a new interaction (enquiry/complaint/feedback)
  /// type: "Enquiry", "Complaint", "Feedback", "Other"
  /// clientType: "Member", "Sponsor", "Trustee" (default: "Member")
  static Future<Map<String, dynamic>> createInteraction({
    required String accessToken,
    required String memberNo,
    required String type,
    required String subject,
    required String description,
    String clientType = 'Member',
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_Interactions?company=$companyId',
    );

    final requestBody = {
      'clientNo': memberNo, // API uses 'clientNo' not 'memberNo'
      'clientType': clientType,
      'type': type,
      'message': description, // API uses 'message' not 'description'
      'priority': 'Medium', // Default priority
      // Note: API doesn't have a separate 'subject' field, it uses 'message'
    };

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"POST\",\"requestBody\":${jsonEncode(requestBody)}}]",
    });

    print('📝 CREATE INTERACTION REQUEST: $body');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('📝 CREATE INTERACTION STATUS: ${response.statusCode}');
    print('📝 CREATE INTERACTION RESPONSE: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);

      if (inner['values'] != null && inner['values'] is List) {
        final valuesArray = inner['values'] as List;
        if (valuesArray.isNotEmpty) {
          final firstItem = valuesArray[0];
          
          if (firstItem is Map<String, dynamic>) {
            if (firstItem['values'] != null && firstItem['values'] is Map) {
              return firstItem['values'] as Map<String, dynamic>;
            }
            return firstItem;
          }
        }
      }
      
      return {};
    } else {
      throw Exception('Failed to create interaction (${response.statusCode})');
    }
  }

  /// Update an existing interaction
  static Future<bool> updateInteraction({
    required String accessToken,
    required String interactionId,
    Map<String, dynamic>? updates,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_Interactions?company=$companyId',
    );

    final requestBody = {
      'id': interactionId,
      ...?updates,
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

    print('✏️ UPDATE INTERACTION STATUS: ${response.statusCode}');
    return response.statusCode == 200;
  }

  /// Fetch comments for an interaction
  static Future<List<Map<String, dynamic>>> fetchInteractionComments({
    required String accessToken,
    required String interactionId,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_interactionComments?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"GET\",\"requestBody\":{\"interactionId\":\"$interactionId\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('💬 FETCH COMMENTS STATUS: ${response.statusCode}');

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
            
            final commentsArray = responseWrapper['values'] as List;
            return commentsArray
                .whereType<Map<String, dynamic>>()
                .toList();
          }
        }
      }
      
      return [];
    } else {
      throw Exception('Failed to fetch comments (${response.statusCode})');
    }
  }

  /// Add a comment/reply to an interaction
  static Future<bool> addInteractionComment({
    required String accessToken,
    required String interactionId,
    required String comment,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_interactionComments?company=$companyId',
    );

    final requestBody = {
      'interactionId': interactionId,
      'comment': comment,
    };

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"POST\",\"requestBody\":${jsonEncode(requestBody)}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('💬 ADD COMMENT STATUS: ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Delete an interaction
  static Future<bool> deleteInteraction({
    required String accessToken,
    required String interactionId,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_Interactions?company=$companyId',
    );

    final body = jsonEncode({
      "request":
          "[{\"requestId\":01,\"method\":\"DELETE\",\"requestBody\":{\"id\":\"$interactionId\"}}]",
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    print('🗑️ DELETE INTERACTION STATUS: ${response.statusCode}');
    return response.statusCode == 200;
  }


// Add this method to your ApiService class in api_service.dart

static Future<List<Map<String, dynamic>>> fetchChangeRequestsHistory({
  required String accessToken,
  required String memberNo,
}) async {
  final url = Uri.parse(
    '$_erpBaseUrl/MSSIntegration_MemberChanges?company=$companyId',
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

  print('📋 FETCH CHANGE REQUESTS STATUS: ${response.statusCode}');

  if (response.statusCode == 200) {
    try {
      // Level 1: OData response
      final odataResponse = jsonDecode(response.body);
      
      // Level 2: The 'value' field contains a JSON string
      final valueString = odataResponse['value'] as String;
      final valueJson = jsonDecode(valueString);
      
      // Level 3: Get the 'values' array
      if (valueJson['values'] != null && valueJson['values'] is List) {
        final requestWrappers = valueJson['values'] as List;
        
        if (requestWrappers.isNotEmpty) {
          // Level 4: Get the first request wrapper
          final firstWrapper = requestWrappers[0] as Map<String, dynamic>;
          
          // Level 5: Get the actual change requests array
          if (firstWrapper['values'] != null && firstWrapper['values'] is List) {
            final changeRequests = firstWrapper['values'] as List;
            
            print('📋 Successfully fetched ${changeRequests.length} change request(s)');
            
            // Parse each change request and handle nested JSON strings
            final parsedRequests = changeRequests.map((request) {
              if (request is Map<String, dynamic>) {
                final Map<String, dynamic> parsedRequest = Map.from(request);
                
                // Parse nested JSON strings for related changes
                if (parsedRequest['nokChanges'] is String) {
                  try {
                    parsedRequest['nokChanges'] = jsonDecode(parsedRequest['nokChanges']);
                  } catch (e) {
                    print('⚠️ Failed to parse nokChanges: $e');
                  }
                }
                
                if (parsedRequest['beneficiaryChanges'] is String) {
                  try {
                    parsedRequest['beneficiaryChanges'] = jsonDecode(parsedRequest['beneficiaryChanges']);
                  } catch (e) {
                    print('⚠️ Failed to parse beneficiaryChanges: $e');
                  }
                }
                
                if (parsedRequest['spouseChanges'] is String) {
                  try {
                    parsedRequest['spouseChanges'] = jsonDecode(parsedRequest['spouseChanges']);
                  } catch (e) {
                    print('⚠️ Failed to parse spouseChanges: $e');
                  }
                }
                
                if (parsedRequest['guardianChanges'] is String) {
                  try {
                    parsedRequest['guardianChanges'] = jsonDecode(parsedRequest['guardianChanges']);
                  } catch (e) {
                    print('⚠️ Failed to parse guardianChanges: $e');
                  }
                }
                
                return parsedRequest;
              }
              return request;
            }).whereType<Map<String, dynamic>>().toList();
            
            return parsedRequests;
          }
        }
      }
      
      print('⚠️ No change requests found in response');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error parsing change requests: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  } else {
    throw Exception('Failed to fetch change requests history (${response.statusCode})');
  }
}
static Future<Map<String, dynamic>> fetchMemberContributionSummary({
    required String accessToken,
    required String memberNo,
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_MemberContributionSummary?company=$companyId',
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

    print('💰 CONTRIBUTION SUMMARY STATUS: ${response.statusCode}');
    print('💰 CONTRIBUTION SUMMARY RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      final outer = jsonDecode(response.body);
      final inner = jsonDecode(outer['value']);

      if (inner['values'] != null && inner['values'] is List) {
        final valuesArray = inner['values'] as List;
        if (valuesArray.isNotEmpty) {
          final firstItem = valuesArray[0];
          
          if (firstItem is Map<String, dynamic>) {
            return firstItem;
          }
        }
      }
      
      throw Exception('Invalid contribution summary response structure');
    } else {
      throw Exception(
        'Failed to fetch contribution summary (${response.statusCode})',
      );
    }
  }

  /// WORKAROUND: Parse contribution data from member statement PDF
  /// This is a temporary solution until backend provides JSON endpoint
  static Future<Map<String, double>> extractContributionDataFromPDF({
    required String accessToken,
    required String memberNo,
  }) async {
    try {
      // Generate the member statement
      final base64GzipPdf = await ApiService.generateMemberStatement(
        accessToken: accessToken,
        memberNo: memberNo,
        startDate: '2020-01-01', // Adjust based on your needs
        endDate: DateTime.now().toString().split(' ')[0],
      );

      // Decompress the PDF
      final gzipBytes = base64Decode(base64GzipPdf);
      final pdfBytes = GZipDecoder().decodeBytes(gzipBytes);

      // Note: Parsing PDF is complex and error-prone
      // This is why we recommend asking for a JSON endpoint instead
      
      // For now, we'll return the structure based on the PDF format
      // In a real implementation, you'd need a PDF parsing library
      
      print('⚠️ PDF parsing not fully implemented');
      print('📄 PDF size: ${pdfBytes.length} bytes');
      
      // Return zeros for now - this needs proper PDF parsing
      return {
        'employerContributions': 0.0,
        'memberContributions': 0.0,
        'interestEarned': 0.0,
        'avcContributions': 0.0,
        'prmfContributions': 0.0,
        'nssfContributions': 0.0,
        'totalContributions': 0.0,
      };
    } catch (e) {
      print('❌ Error extracting contribution data from PDF: $e');
      rethrow;
    }
  }

  /// Get yearly contribution data from contribution statement
  static Future<Map<String, dynamic>> extractYearlyContributions({
    required String accessToken,
    required String memberNo,
    int? year,
  }) async {
    try {
      final currentYear = year ?? DateTime.now().year;
      
      final base64GzipPdf = await ApiService.generateContributionStatement(
        accessToken: accessToken,
        memberNo: memberNo,
        startDate: '$currentYear-01-01',
        endDate: '$currentYear-12-31',
      );

      // Decompress the PDF
      final gzipBytes = base64Decode(base64GzipPdf);
      final pdfBytes = GZipDecoder().decodeBytes(gzipBytes);

      print('⚠️ Contribution statement PDF parsing not fully implemented');
      print('📄 PDF size: ${pdfBytes.length} bytes');

      // The contribution statement has:
      // - Monthly columns (January - December)
      // - Rows: EE, ER, AVC, EE PRMF, ER PRMF, EE NSSF Tier II, ER NSSF Tier II
      // - Grand Total column
      
      return {
        'year': currentYear,
        'totalEE': 0.0,        // Employee contributions
        'totalER': 0.0,        // Employer contributions
        'totalAVC': 0.0,       // Additional Voluntary Contributions
        'totalPRMF': 0.0,      // PRMF contributions
        'totalNSSF': 0.0,      // NSSF Tier II contributions
        'grandTotal': 0.0,     // Sum of all
        'contributionCount': 0, // Number of months with contributions
      };
    } catch (e) {
      print('❌ Error extracting yearly contributions: $e');
      rethrow;
    }
  }

  // Add these methods to api_service.dart

static Future<List<Map<String, dynamic>>> fetchSpouseChanges({
  required String accessToken,
  required String changeRequestNo,
}) async {
  final url = Uri.parse(
    '$_erpBaseUrl/MSSIntegration_MemberSpouseChanges?company=$companyId',
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

  print('📋 FETCH SPOUSE CHANGES STATUS: ${response.statusCode}');

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
          
          final spousesArray = responseWrapper['values'] as List;
          return spousesArray
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }
    }
    
    return [];
  } else {
    throw Exception('Failed to fetch spouse changes (${response.statusCode})');
  }
}

static Future<bool> updateSpouseChanges({
  required String accessToken,
  required Map<String, dynamic> spouse,
}) async {
  final url = Uri.parse(
    '$_erpBaseUrl/MSSIntegration_MemberSpouseChanges?company=$companyId',
  );

  final requestList = [
    {
      "requestId": 1,
      "method": "PATCH",
      "requestBody": spouse,
    }
  ];

  final body = jsonEncode({
    "request": jsonEncode(requestList).replaceAll(RegExp(r'\s+'), ''),
  });

  print('📝 UPDATE SPOUSE REQUEST BODY: $body');

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: body,
  );

  print('📝 UPDATE SPOUSE STATUS: ${response.statusCode}');
  print('📝 UPDATE SPOUSE RESPONSE: ${response.body}');

  return response.statusCode == 200;
}

// Add these methods to your existing ApiService class in api_service.dart

/// Request password reset OTP
static Future<Map<String, dynamic>> forgotPassword({
  required String emailAddress,
}) async {
  final url = Uri.parse('$_baseUrl/auth/forgotPassword?emailAddress=$emailAddress');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
  );

  print('FORGOT PASSWORD STATUS: ${response.statusCode}');
  print('FORGOT PASSWORD RESPONSE: ${response.body}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception(
      jsonDecode(response.body)['message'] ?? 'Failed to send OTP',
    );
  }
}

/// Verify OTP for password reset
static Future<Map<String, dynamic>> verifyOtp({
  required String emailAddress,
  required int otp,
}) async {
  final url = Uri.parse('$_baseUrl/auth/forgot/verifyOtp');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "emailAddress": emailAddress,
      "otp": otp,
    }),
  );

  print('VERIFY OTP STATUS: ${response.statusCode}');
  print('VERIFY OTP RESPONSE: ${response.body}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception(
      jsonDecode(response.body)['message'] ?? 'Invalid OTP',
    );
  }
}

/// Change password with reset token (for password reset flow)
static Future<Map<String, dynamic>> changePasswordWithToken({
  required String emailAddress,
  required String password,
  required String token,
}) async {
  final url = Uri.parse('$_baseUrl/user/changePassword');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      "emailAddress": emailAddress,
      "password": password,
    }),
  );

  print('CHANGE PASSWORD STATUS: ${response.statusCode}');
  print('CHANGE PASSWORD RESPONSE: ${response.body}');

  if (response.statusCode == 200 || response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception(
      jsonDecode(response.body)['message'] ?? 'Failed to reset password',
    );
  }
}
}