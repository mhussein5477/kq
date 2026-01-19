import 'dart:convert';
import 'package:archive/archive.dart';

class PdfParserService {
  /// Parse member statement PDF to extract contribution data
  /// Returns a map with total contributions broken down by type
  static Map<String, dynamic> parseMemberStatementPdf(String base64GzipPdf) {
    try {
      // Decompress the gzipped base64 PDF
      final gzipBytes = base64Decode(base64GzipPdf);
      final pdfBytes = GZipDecoder().decodeBytes(gzipBytes);

      // Convert PDF bytes to string (basic text extraction)
      // Note: This is a simplified approach. In production, use a proper PDF parser
      final pdfText = String.fromCharCodes(pdfBytes);

      print('🔍 Parsing member statement PDF...');
      print('📄 PDF text length: ${pdfText.length}');

      // Initialize totals
      double totalEmployeeReg = 0.0;
      double totalEmployerReg = 0.0;
      double totalAVC = 0.0;
      double totalEmployeePRMF = 0.0;
      double totalEmployerPRMF = 0.0;
      double totalEmployeeNSSF = 0.0;
      double totalEmployerNSSF = 0.0;
      double totalInterest = 0.0;

      // Parse the CLOSING BALANCES row from the PDF
      // The PDF structure has columns: EMPLOYEE, EMPLOYER, AVC, etc.
      final closingBalancesRegex = RegExp(
        r'CLOSING BALANCES\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)',
      );

      final match = closingBalancesRegex.firstMatch(pdfText);
      if (match != null) {
        totalEmployeeReg = double.tryParse(match.group(1) ?? '0') ?? 0.0;
        totalEmployerReg = double.tryParse(match.group(2) ?? '0') ?? 0.0;
        totalAVC = double.tryParse(match.group(3) ?? '0') ?? 0.0;
        totalEmployeePRMF = double.tryParse(match.group(4) ?? '0') ?? 0.0;
        totalEmployerPRMF = double.tryParse(match.group(5) ?? '0') ?? 0.0;
        totalEmployeeNSSF = double.tryParse(match.group(6) ?? '0') ?? 0.0;
        totalEmployerNSSF = double.tryParse(match.group(7) ?? '0') ?? 0.0;

        print('✅ Found closing balances:');
        print('   Employee Reg: $totalEmployeeReg');
        print('   Employer Reg: $totalEmployerReg');
        print('   AVC: $totalAVC');
        print('   Employee PRMF: $totalEmployeePRMF');
        print('   Employer PRMF: $totalEmployerPRMF');
        print('   Employee NSSF: $totalEmployeeNSSF');
        print('   Employer NSSF: $totalEmployerNSSF');
      }

      // Extract quarterly interest entries
      final interestRegex = RegExp(r'Q\d Interest\s+([\d.]+)');
      final interestMatches = interestRegex.allMatches(pdfText);
      for (final match in interestMatches) {
        final interest = double.tryParse(match.group(1) ?? '0') ?? 0.0;
        totalInterest += interest;
      }

      print('💰 Total Interest: $totalInterest');

      // Calculate totals
      final totalEmployeeContributions = totalEmployeeReg + 
                                        totalEmployeePRMF + 
                                        totalEmployeeNSSF + 
                                        totalAVC;
      
      final totalEmployerContributions = totalEmployerReg + 
                                        totalEmployerPRMF + 
                                        totalEmployerNSSF;
      
      final grandTotal = totalEmployeeContributions + 
                        totalEmployerContributions + 
                        totalInterest;

      return {
        'employeeRegistered': totalEmployeeReg,
        'employerRegistered': totalEmployerReg,
        'avc': totalAVC,
        'employeePRMF': totalEmployeePRMF,
        'employerPRMF': totalEmployerPRMF,
        'employeeNSSF': totalEmployeeNSSF,
        'employerNSSF': totalEmployerNSSF,
        'totalEmployeeContributions': totalEmployeeContributions,
        'totalEmployerContributions': totalEmployerContributions,
        'interestEarned': totalInterest,
        'totalContributions': grandTotal,
      };
    } catch (e) {
      print('❌ Error parsing member statement PDF: $e');
      return {
        'employeeRegistered': 0.0,
        'employerRegistered': 0.0,
        'avc': 0.0,
        'employeePRMF': 0.0,
        'employerPRMF': 0.0,
        'employeeNSSF': 0.0,
        'employerNSSF': 0.0,
        'totalEmployeeContributions': 0.0,
        'totalEmployerContributions': 0.0,
        'interestEarned': 0.0,
        'totalContributions': 0.0,
      };
    }
  }

  /// Parse contribution statement PDF to extract yearly contribution data
  /// Returns a map with monthly breakdown and grand total
  static Map<String, dynamic> parseContributionStatementPdf(String base64GzipPdf) {
    try {
      // Decompress the gzipped base64 PDF
      final gzipBytes = base64Decode(base64GzipPdf);
      final pdfBytes = GZipDecoder().decodeBytes(gzipBytes);

      final pdfText = String.fromCharCodes(pdfBytes);

      print('🔍 Parsing contribution statement PDF...');

      // Extract the grand total from the TOTALS row
      // Looking for pattern: TOTALS followed by monthly amounts and grand total
      final totalsRegex = RegExp(
        r'TOTALS\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)',
      );

      final match = totalsRegex.firstMatch(pdfText);
      double grandTotal = 0.0;
      int contributionCount = 0;

      if (match != null) {
        // Last group is the grand total
        grandTotal = double.tryParse(match.group(13) ?? '0') ?? 0.0;
        
        // Count non-zero monthly contributions
        for (int i = 1; i <= 12; i++) {
          final monthlyAmount = double.tryParse(match.group(i) ?? '0') ?? 0.0;
          if (monthlyAmount > 0) {
            contributionCount++;
          }
        }

        print('✅ Yearly grand total: $grandTotal');
        print('✅ Contribution count: $contributionCount months');
      }

      // Extract individual contribution types (EE, ER, AVC, etc.)
      final eeRegex = RegExp(r'EE\s+([\d.]+).*?([\d.]+)\s*$', multiLine: true);
      final erRegex = RegExp(r'ER\s+([\d.]+).*?([\d.]+)\s*$', multiLine: true);
      final avcRegex = RegExp(r'AVC\s+([\d.]+).*?([\d.]+)\s*$', multiLine: true);

      double totalEE = 0.0;
      double totalER = 0.0;
      double totalAVC = 0.0;

      final eeMatch = eeRegex.firstMatch(pdfText);
      final erMatch = erRegex.firstMatch(pdfText);
      final avcMatch = avcRegex.firstMatch(pdfText);

      if (eeMatch != null) {
        totalEE = double.tryParse(eeMatch.group(2) ?? '0') ?? 0.0;
      }
      if (erMatch != null) {
        totalER = double.tryParse(erMatch.group(2) ?? '0') ?? 0.0;
      }
      if (avcMatch != null) {
        totalAVC = double.tryParse(avcMatch.group(2) ?? '0') ?? 0.0;
      }

      return {
        'grandTotal': grandTotal,
        'contributionCount': contributionCount,
        'totalEE': totalEE,
        'totalER': totalER,
        'totalAVC': totalAVC,
      };
    } catch (e) {
      print('❌ Error parsing contribution statement PDF: $e');
      return {
        'grandTotal': 0.0,
        'contributionCount': 0,
        'totalEE': 0.0,
        'totalER': 0.0,
        'totalAVC': 0.0,
      };
    }
  }
}