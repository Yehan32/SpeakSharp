import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';

class ShareExportHelper {
  /// Share analysis results as text
  static Future<void> shareAsText(
      BuildContext context,
      Map<String, dynamic> analysisResults,
      ) async {
    try {
      final text = _generateTextReport(analysisResults);

      await Share.share(
        text,
        subject: 'SpeakSharp - Speech Analysis Results',
      );
    } catch (e) {
      _showError(context, 'Failed to share: $e');
    }
  }

  /// Share analysis as PDF report
  static Future<void> shareAsPDF(
      BuildContext context,
      Map<String, dynamic> analysisResults,
      ) async {
    try {
      final pdf = await _generatePDFReport(analysisResults);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/speech_analysis.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SpeakSharp - Speech Analysis Report',
      );
    } catch (e) {
      _showError(context, 'Failed to generate PDF: $e');
    }
  }

  /// Share screenshot of results
  static Future<void> shareScreenshot(
      BuildContext context,
      ScreenshotController screenshotController,
      ) async {
    try {
      final image = await screenshotController.capture();
      if (image == null) {
        _showError(context, 'Failed to capture screenshot');
        return;
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/speech_analysis.png');
      await file.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SpeakSharp - Speech Analysis',
      );
    } catch (e) {
      _showError(context, 'Failed to share screenshot: $e');
    }
  }

  /// Export transcription only
  static Future<void> exportTranscription(
      BuildContext context,
      String transcription,
      ) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/transcription.txt');
      await file.writeAsString(transcription);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SpeakSharp - Speech Transcription',
      );
    } catch (e) {
      _showError(context, 'Failed to export transcription: $e');
    }
  }

  /// Export full analysis as JSON
  static Future<void> exportAsJSON(
      BuildContext context,
      Map<String, dynamic> analysisResults,
      ) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/speech_analysis.json');
      await file.writeAsString(_generateJSON(analysisResults));

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SpeakSharp - Analysis Data',
      );
    } catch (e) {
      _showError(context, 'Failed to export JSON: $e');
    }
  }

  /// Show share options dialog
  static Future<void> showShareOptions(
      BuildContext context,
      Map<String, dynamic> analysisResults, {
        ScreenshotController? screenshotController,
      }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share Analysis',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildShareOption(
              context,
              Icons.text_snippet,
              'Share as Text',
              'Share summary as text message',
                  () {
                Navigator.pop(context);
                shareAsText(context, analysisResults);
              },
            ),
            _buildShareOption(
              context,
              Icons.picture_as_pdf,
              'Share as PDF',
              'Generate and share PDF report',
                  () {
                Navigator.pop(context);
                shareAsPDF(context, analysisResults);
              },
            ),
            if (screenshotController != null)
              _buildShareOption(
                context,
                Icons.screenshot,
                'Share Screenshot',
                'Share visual summary',
                    () {
                  Navigator.pop(context);
                  shareScreenshot(context, screenshotController);
                },
              ),
            _buildShareOption(
              context,
              Icons.article,
              'Export Transcription',
              'Save transcription as text file',
                  () {
                Navigator.pop(context);
                exportTranscription(
                  context,
                  analysisResults['transcription'] ?? '',
                );
              },
            ),
            _buildShareOption(
              context,
              Icons.code,
              'Export as JSON',
              'Export complete analysis data',
                  () {
                Navigator.pop(context);
                exportAsJSON(context, analysisResults);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _buildShareOption(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60)),
      onTap: onTap,
    );
  }

  /// Generate text report
  static String _generateTextReport(Map<String, dynamic> results) {
    final topic = results['topic'] ?? 'Untitled';
    final overallScore = (results['overall_score'] ?? 0).toDouble();
    final scores = results['scores'] ?? {};
    final transcription = results['transcription'] ?? '';

    return '''
🎤 SpeakSharp - Speech Analysis Report

📝 Topic: $topic
⭐ Overall Score: ${overallScore.toStringAsFixed(1)}/100

📊 Detailed Scores:
• Voice Modulation: ${scores['voice_modulation'] ?? 0}/20
• Grammar & Vocabulary: ${scores['vocabulary'] ?? 0}/50
• Speech Structure: ${scores['speech_development'] ?? 0}/20
• Proficiency: ${scores['proficiency'] ?? 0}/20

📄 Transcription:
$transcription

---
Generated by SpeakSharp
www.speaksharp.com
''';
  }

  /// Generate PDF report
  static Future<pw.Document> _generatePDFReport(
      Map<String, dynamic> results,
      ) async {
    final pdf = pw.Document();
    final topic = results['topic'] ?? 'Untitled';
    final overallScore = (results['overall_score'] ?? 0).toDouble();
    final scores = results['scores'] ?? {};

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                color: PdfColors.blue900,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Speech Analysis Report',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      topic,
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Overall Score
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.blue900),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Overall Score',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${overallScore.toStringAsFixed(1)}/100',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Score Breakdown
              pw.Text(
                'Score Breakdown',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),

              _buildPDFScoreItem(
                'Voice Modulation',
                (scores['voice_modulation'] ?? 0).toDouble(),
                20,
              ),
              _buildPDFScoreItem(
                'Grammar & Vocabulary',
                (scores['vocabulary'] ?? 0).toDouble(),
                50,
              ),
              _buildPDFScoreItem(
                'Speech Structure',
                (scores['speech_development'] ?? 0).toDouble(),
                20,
              ),
              _buildPDFScoreItem(
                'Proficiency',
                (scores['proficiency'] ?? 0).toDouble(),
                20,
              ),

              pw.Spacer(),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Generated by SpeakSharp',
                  style: const pw.TextStyle(
                    color: PdfColors.grey600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildPDFScoreItem(
      String label,
      double score,
      double maxScore,
      ) {
    final percentage = (score / maxScore).clamp(0.0, 1.0);

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
              pw.Text(
                '${score.toStringAsFixed(1)}/$maxScore',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            height: 8,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
                children: [
                    pw.Expanded(
                        flex: (percentage * 100).toInt(),
                        child: pw.Container(
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue900,
                              borderRadius:
                                const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                        ),
                    ),
                ]
            ),
          ),
        ]
      ),
    );
  }

  /// Generate JSON export
  static String _generateJSON(Map<String, dynamic> results) {
    // Convert to JSON string with pretty formatting
    return const JsonEncoder.withIndent('  ').convert(results);
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}