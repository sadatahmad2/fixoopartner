
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://dhvcetaohokhcvtjvymq.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRodmNldGFvaG9raGN2dGp2eW1xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5Mjk3MzQsImV4cCI6MjA5MjUwNTczNH0.FM3mWB3_MOMrzfMC5pquUbCU0jVLD4aUJo3zDHcveZM',
  );

  try {
    print('Checking profiles table columns...');
    final response = await supabase.from('profiles').select().limit(1).maybeSingle();
    if (response != null) {
      print('Columns found: ${response.keys.toList()}');
    } else {
      print('Table is empty, trying to fetch columns via RPC or dummy select...');
      // If table is empty, we can try a select with a non-existent column to see the error or just list
      final all = await supabase.from('profiles').select().limit(1);
      if (all.isNotEmpty) {
        print('Columns found: ${all[0].keys.toList()}');
      } else {
        print('Table is empty. Please add a row manually to check columns or run the SQL.');
      }
    }
  } catch (e) {
    print('Error checking table: $e');
  }
}
