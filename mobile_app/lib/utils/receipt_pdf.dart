import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ReceiptPdf {
  static String get baseUrl => '${ApiService.baseUrl}/api/tenant';

  // Fetch receipt data from backend then generate PDF
  static Future<void> fetchAndGenerate({
    required BuildContext context,
    required String token,
    required int paymentId,
  }) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Call backend
      final response = await http.get(
        Uri.parse('$baseUrl/rent/receipt/$paymentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Close loading
      if (context.mounted) Navigator.pop(context);

      if (response.statusCode != 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not fetch receipt. Try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final data = jsonDecode(response.body)['data']['receipt'];

      // Generate PDF with real data
      await generateAndShow(
        context: context,
        tenantName: data['name'] ?? '',
        roomNo: data['room_no'] ?? '',
        pgName: data['pg_name'] ?? '',
        month: data['month'] ?? '',
        amount: 'Rs. ${data['amount']}',
        status: data['status'] ?? '',
        transactionId: data['transaction_id'] ?? 'N/A',
        receiptNumber: data['receipt_number'] ?? 'N/A',
        paymentDate: data['payment_date']?.toString().split('T')[0] ?? '',
        paymentMethod: data['payment_method'] ?? '',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> generateAndShow({
    required BuildContext context,
    required String tenantName,
    required String roomNo,
    required String pgName,
    required String month,
    required String amount,
    required String status,
    required String transactionId,
    required String receiptNumber,
    required String paymentDate,
    required String paymentMethod,
  }) async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#2563EB'),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(pgName,
                        style: pw.TextStyle(
                            font: fontBold,
                            color: PdfColors.white,
                            fontSize: 22)),
                    pw.SizedBox(height: 4),
                    pw.Text('Payment Receipt',
                        style: pw.TextStyle(
                            font: font,
                            color: PdfColors.white,
                            fontSize: 14)),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Receipt No.',
                          style: pw.TextStyle(
                              font: font,
                              color: PdfColors.grey,
                              fontSize: 11)),
                      pw.Text(receiptNumber,
                          style: pw.TextStyle(font: fontBold, fontSize: 13)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Payment Date',
                          style: pw.TextStyle(
                              font: font,
                              color: PdfColors.grey,
                              fontSize: 11)),
                      pw.Text(paymentDate,
                          style: pw.TextStyle(font: fontBold, fontSize: 13)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),

              pw.Text('Tenant Details',
                  style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                      color: PdfColor.fromHex('#1E293B'))),
              pw.SizedBox(height: 12),
              _buildRow('Name', tenantName, font, fontBold),
              _buildRow('Room', roomNo, font, fontBold),
              _buildRow('PG', pgName, font, fontBold),
              _buildRow('Month', month, font, fontBold),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),

              pw.Text('Payment Details',
                  style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                      color: PdfColor.fromHex('#1E293B'))),
              pw.SizedBox(height: 12),
              _buildRow('Amount', amount, font, fontBold),
              _buildRow('Method', paymentMethod.toUpperCase(), font, fontBold),
              _buildRow('Transaction ID', transactionId, font, fontBold),
              _buildRow('Status', status.toUpperCase(), font, fontBold),

              pw.SizedBox(height: 24),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EFF6FF'),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(
                      color: PdfColor.fromHex('#BFDBFE'), width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Paid',
                        style: pw.TextStyle(font: fontBold, fontSize: 16)),
                    pw.Text(amount,
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 22,
                            color: PdfColor.fromHex('#2563EB'))),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Thank you for your payment!',
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 13,
                            color: PdfColor.fromHex('#16A34A'))),
                    pw.SizedBox(height: 4),
                    pw.Text('This is a computer generated receipt.',
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: PdfColors.grey)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Receipt_$receiptNumber.pdf',
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Receipt_$receiptNumber.pdf');
      await file.writeAsBytes(pdfBytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receipt saved: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Receipt_$receiptNumber.pdf',
      );
    }
  }

  static pw.Widget _buildRow(
      String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: font, color: PdfColors.grey, fontSize: 12)),
          pw.Text(value,
              style: pw.TextStyle(font: fontBold, fontSize: 12)),
        ],
      ),
    );
  }
}