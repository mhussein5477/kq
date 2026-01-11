import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://75.119.147.13:9090/api/v1';
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
    final url = Uri.parse('$_baseUrl/auth/signIn');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"emailAddress": emailAddress, "password": password}),
    );

    final decoded = jsonDecode(response.body);
    print('LOGIN RESPONSE: $decoded');

    if (response.statusCode == 200 && decoded['success'] == true) {
      return decoded;
    } else {
      throw Exception(decoded['message'] ?? 'Login failed');
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
      // Parse outer JSON
      final outer = jsonDecode(response.body);
      print('🔍 Outer keys: ${outer.keys}');

      // Parse the nested JSON string in 'value'
      final innerJson = jsonDecode(outer['value']);
      print('🔍 Inner JSON: $innerJson');
      print('🔍 Inner keys: ${innerJson.keys}');

      // Extract from values array
      if (innerJson['values'] != null && innerJson['values'].isNotEmpty) {
        final valuesList = innerJson['values'];
        print('🔍 Values list type: ${valuesList.runtimeType}');
        print('🔍 Values list length: ${valuesList.length}');

        // Get first item from values array
        final firstValue = valuesList[0];
        print('🔍 First value type: ${firstValue.runtimeType}');
        print('🔍 First value keys: ${firstValue.keys}');

        // Extract base64GzipReport directly from the first object
        final base64Report = firstValue['base64GzipReport'] as String? ?? '';

        if (base64Report.isEmpty) {
          print('❌ base64GzipReport field is empty');
          print('🔍 Available keys in first value: ${firstValue.keys}');
          throw Exception('Base64 report data is empty');
        }

        print('✅ Extracted base64 report, length: ${base64Report.length}');
        return base64Report;
      }

      print('❌ No values found in response');
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
    String? startDate, // Optional: Format "YYYY-MM-DD"
    String? endDate, // Optional: Format "YYYY-MM-DD"
  }) async {
    final url = Uri.parse(
      '$_erpBaseUrl/MSSIntegration_GenerateContributionStatement?company=$companyId',
    );

    // Build request body with optional dates
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
      // Parse outer JSON
      final outer = jsonDecode(response.body);
      print('🔍 Outer keys: ${outer.keys}');

      // Parse the nested JSON string in 'value'
      final innerJson = jsonDecode(outer['value']);
      print('🔍 Inner JSON: $innerJson');
      print('🔍 Inner keys: ${innerJson.keys}');

      // Extract from values array
      if (innerJson['values'] != null && innerJson['values'].isNotEmpty) {
        final valuesList = innerJson['values'];
        print('🔍 Values list type: ${valuesList.runtimeType}');
        print('🔍 Values list length: ${valuesList.length}');

        // Get first item from values array
        final firstValue = valuesList[0];
        print('🔍 First value type: ${firstValue.runtimeType}');
        print('🔍 First value keys: ${firstValue.keys}');

        // Extract base64GzipReport directly from the first object
        final base64Report = firstValue['base64GzipReport'] as String? ?? '';

        if (base64Report.isEmpty) {
          print('❌ base64GzipReport field is empty');
          print('🔍 Available keys in first value: ${firstValue.keys}');
          throw Exception('Base64 report data is empty');
        }

        print('✅ Extracted base64 report, length: ${base64Report.length}');
        return base64Report;
      }

      print('❌ No values found in response');
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
      // Parse outer JSON
      final outer = jsonDecode(response.body);
      print('🔍 Outer keys: ${outer.keys}');

      // Parse the nested JSON string in 'value'
      final innerJson = jsonDecode(outer['value']);
      print('🔍 Inner JSON: $innerJson');
      print('🔍 Inner keys: ${innerJson.keys}');

      // Extract from values array
      if (innerJson['values'] != null && innerJson['values'].isNotEmpty) {
        final valuesList = innerJson['values'];
        print('🔍 Values list type: ${valuesList.runtimeType}');
        print('🔍 Values list length: ${valuesList.length}');

        // Get first item from values array
        final firstValue = valuesList[0];
        print('🔍 First value type: ${firstValue.runtimeType}');
        print('🔍 First value keys: ${firstValue.keys}');

        // Extract base64GzipReport directly from the first object
        final base64Report = firstValue['base64GzipReport'] as String? ?? '';

        if (base64Report.isEmpty) {
          print('❌ base64GzipReport field is empty');
          print('🔍 Available keys in first value: ${firstValue.keys}');
          throw Exception('Base64 report data is empty');
        }

        print('✅ Extracted base64 report, length: ${base64Report.length}');
        return base64Report;
      }

      print('❌ No values found in response');
      throw Exception('Report data not found in response structure');
    } else {
      throw Exception(
        'Failed to generate member certificate (${response.statusCode})',
      );
    }
  }
}
