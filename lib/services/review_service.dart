import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';

class UserRatingSummary {
  final double average;
  final int count;

  UserRatingSummary({required this.average, required this.count});
}

class ReviewService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Review>> fetchUserReviews(String userId) async {
    final response = await _client
        .from('reviews')
        .select('''
          *,
          evaluator:evaluator_id(nombre, avatar_url)
        ''')
        .eq('evaluated_id', userId)
        .order('created_at', ascending: false);

    print('RAW RESPONSE: $response');

    final list = response as List<dynamic>;
    return list.map((json) => Review.fromJson(Map<String, dynamic>.from(json as Map))).toList();
  }

  UserRatingSummary summarize(List<Review> reviews) {
    if (reviews.isEmpty) {
      return UserRatingSummary(average: 0.0, count: 0);
    }
    final totalRating = reviews.fold<int>(0, (sum, item) => sum + item.rating);
    return UserRatingSummary(average: totalRating / reviews.length, count: reviews.length);
  }
}