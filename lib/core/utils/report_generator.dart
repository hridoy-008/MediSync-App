import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../domain/entities/reminder.dart';
import '../../../domain/enums.dart';
import '../utils/recurrence.dart';

class ReportGenerator {
  ReportGenerator._();

  static Future<void> generateAndShare({
    required List<Reminder> reminders,
    required List<ReminderLog> logs,
    required bool isBangla,
  }) async {
    final pdf = pw.Document();
    
    // Load the custom Noto Sans Bengali font from assets for PDF text rendering
    final fontData = await rootBundle.load('assets/fonts/NotoSansBengali-Variable.ttf');
    final ttfFont = pw.Font.ttf(fontData);

    // Calculate stats
    final totalDoses = logs.length;
    final takenDoses = logs.where((l) => l.action == ReminderAction.taken).length;
    final skippedDoses = logs.where((l) => l.action == ReminderAction.skipped).length;
    final missedDoses = logs.where((l) => l.action == ReminderAction.missed).length;
    final compliance = totalDoses == 0 ? 100 : ((takenDoses / totalDoses) * 100).round();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttfFont,
          bold: ttfFont,
        ),
        build: (context) => [
          // Header section
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      isBangla ? 'মেডিসিন্ক রিপোর্ট' : 'MediSync Health Report',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      isBangla ? 'ওষুধ সেবন ও মেনে চলার ট্র্যাকার' : 'Medication Adherence Tracker',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '${isBangla ? 'তারিখ' : 'Date'}: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '${isBangla ? 'মেডিকেশন কমপ্লায়েন্স' : 'Compliance'}: $compliance%',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          // Overview Statistics
          pw.Text(
            isBangla ? 'পরিসংখ্যান' : 'Overview Statistics',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _statBox(isBangla ? 'মোট অনুস্মারক' : 'Total Doses', '$totalDoses', isBangla),
              _statBox(isBangla ? 'গৃহীত ওষুধ' : 'Taken', '$takenDoses', isBangla),
              _statBox(isBangla ? 'বাদ দেওয়া' : 'Skipped', '$skippedDoses', isBangla),
              _statBox(isBangla ? 'ভুলে যাওয়া' : 'Missed', '$missedDoses', isBangla),
            ],
          ),
          pw.SizedBox(height: 20),

          // Active Reminders Table
          pw.Text(
            isBangla ? 'সক্রিয় ওষুধের তালিকা' : 'Active Medications List',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.TableHelper.fromTextArray(
            headers: isBangla 
                ? ['ওষুধের নাম', 'সেবনের নিয়ম', 'মজুদ (পিল)'] 
                : ['Medicine Name', 'Instructions', 'Inventory Left'],
            data: reminders.map((r) {
              final stock = r.stockCount?.toString() ?? (isBangla ? 'লগ করা হয়নি' : 'Not tracked');
              return [r.title, r.subtitle, stock];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
          pw.SizedBox(height: 20),

          // Log History Table
          pw.Text(
            isBangla ? 'ওষুধ সেবনের ইতিহাস (সর্বশেষ ৩০ দিন)' : 'Adherence History (Last 30 Days)',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          if (logs.isEmpty)
            pw.Text(
              isBangla ? 'কোনো ইতিহাস পাওয়া যায়নি।' : 'No log data recorded yet.',
              style: const pw.TextStyle(fontStyle: pw.FontStyle.italic),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: isBangla 
                  ? ['তারিখ ও সময়', 'ওষুধের নাম', 'অবস্থা'] 
                  : ['Date & Time', 'Medicine Name', 'Status'],
              data: logs.map((l) {
                final reminderTitle = reminders.firstWhere((r) => r.id == l.reminderId, orElse: () => Reminder(id: '', type: ReminderType.medicine, title: l.reminderId, recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.daily, timesOfDay: []))).title;
                final statusStr = _logActionName(l.action, isBangla);
                final timeStr = l.scheduledTime.toLocal().toString().substring(0, 16);
                return [timeStr, reminderTitle, statusStr];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            ),
        ],
      ),
    );

    // Share/Print PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'medisync_adherence_report.pdf',
    );
  }

  static pw.Widget _statBox(String label, String value, bool isBangla) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      width: 110,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          ),
        ],
      ),
    );
  }

  static String _logActionName(ReminderAction action, bool isBangla) {
    return switch (action) {
      ReminderAction.taken => isBangla ? 'গৃহীত' : 'Taken',
      ReminderAction.skipped => isBangla ? 'বাদ দেওয়া' : 'Skipped',
      ReminderAction.snoozed => isBangla ? 'স্নুজড' : 'Snoozed',
      ReminderAction.missed => isBangla ? 'ভুলে যাওয়া' : 'Missed',
    };
  }
}
