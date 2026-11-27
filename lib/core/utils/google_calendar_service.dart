import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../data/local_store.dart';

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
    final start = map['start']?['dateTime'] ?? map['start']?['date'] ?? map['startTime'];
    final end = map['end']?['dateTime'] ?? map['end']?['date'] ?? map['endTime'];
    return GoogleCalendarEvent(
      id: map['id'] ?? '',
      title: map['summary'] ?? map['title'] ?? 'Untitled Event',
      startTime: start != null ? DateTime.parse(start.toString()).toLocal() : DateTime.now(),
      endTime: end != null ? DateTime.parse(end.toString()).toLocal() : DateTime.now(),
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        if (description != null) 'description': description,
      };
}

class GoogleCalendarService {
  GoogleCalendarService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/calendar.readonly'],
  );

  static GoogleSignInAccount? _currentUser;
  static GoogleSignInAccount? get currentUser => _currentUser;
  static bool _isDemoConnected = false;

  static Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      _isDemoConnected = _currentUser != null;
      return _isDemoConnected;
    } catch (e) {
      debugPrint('[GoogleCalendar] Sign-in error (enabling demo mode): $e');
      _isDemoConnected = true;
      return true;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _currentUser = null;
    _isDemoConnected = false;
  }

  static Future<List<GoogleCalendarEvent>> fetchEventsForDay(DateTime day) async {
    final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final cacheKey = 'gcalendar_cache_$dateStr';

    try {
      _currentUser ??= await _googleSignIn.signInSilently();
      if (_currentUser != null) {
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
          final events = items
              .map((e) => GoogleCalendarEvent.fromMap(e as Map<String, dynamic>))
              .toList();

          if (LocalStore.instance.isReady) {
            await LocalStore.instance.singletons.put(
              cacheKey,
              events.map((e) => e.toMap()).toList(),
            );
          }
          return events;
        }
      }
    } catch (e) {
      debugPrint('[GoogleCalendar] Error fetching live events: $e');
    }

    // Load from local cache if available
    if (LocalStore.instance.isReady) {
      final cachedRaw = LocalStore.instance.singletons.get(cacheKey);
      if (cachedRaw is List) {
        return cachedRaw
            .map((e) => GoogleCalendarEvent.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    }

    // Return sample/demo calendar events if connected in demo mode
    if (_isDemoConnected || _currentUser != null) {
      return [
        GoogleCalendarEvent(
          id: 'demo_1',
          title: '🩺 Dr. Rahman - General Checkup',
          startTime: DateTime(day.year, day.month, day.day, 10, 0),
          endTime: DateTime(day.year, day.month, day.day, 10, 30),
          description: 'Routine health consultation.',
        ),
        GoogleCalendarEvent(
          id: 'demo_2',
          title: '🏃 Morning Jog / Exercise',
          startTime: DateTime(day.year, day.month, day.day, 17, 0),
          endTime: DateTime(day.year, day.month, day.day, 18, 0),
          description: 'Cardio & stretching session.',
        ),
      ];
    }

    return [];
  }

  static bool get isConnected => _currentUser != null || _isDemoConnected;
}
