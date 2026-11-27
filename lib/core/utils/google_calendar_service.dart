import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarEvent {
  const GoogleCalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;

  factory GoogleCalendarEvent.fromMap(Map<String, dynamic> map) {
    final start = map['start']?['dateTime'] ?? map['start']?['date'];
    final end = map['end']?['dateTime'] ?? map['end']?['date'];
    return GoogleCalendarEvent(
      id: map['id'] ?? '',
      title: map['summary'] ?? 'Untitled Event',
      startTime: start != null ? DateTime.parse(start).toLocal() : DateTime.now(),
      endTime: end != null ? DateTime.parse(end).toLocal() : DateTime.now(),
      description: map['description'],
    );
  }
}

class GoogleCalendarService {
  GoogleCalendarService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/calendar.readonly'],
  );

  static GoogleSignInAccount? _currentUser;
  static GoogleSignInAccount? get currentUser => _currentUser;

  static Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (e) {
      debugPrint('[GoogleCalendar] Sign-in error: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  static Future<List<GoogleCalendarEvent>> fetchEventsForDay(DateTime day) async {
    try {
      _currentUser ??= await _googleSignIn.signInSilently();
      if (_currentUser == null) return [];

      final authHeaders = await _currentUser!.authHeaders;
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final url = Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/primary/events?'
        'timeMin=${startOfDay.toIso8601String()}&'
        'timeMax=${endOfDay.toIso8601String()}&'
        'singleEvents=true&orderBy=startTime',
      );

      final response = await http.get(url, headers: authHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];
        return items
            .map((e) => GoogleCalendarEvent.fromMap(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('[GoogleCalendar] Fetch error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('[GoogleCalendar] Error fetching events: $e');
      return [];
    }
  }
}
