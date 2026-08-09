class Review {
  final String id;
  final String exchangeId;
  final String evaluatorId;
  final String evaluatedId;
  final int rating;
  final String? comment;
  final String? reply;
  final bool isReported;
  final DateTime createdAt;

  final String? evaluatorName;
  final String? evaluatorAvatarUrl;

  Review({
    required this.id,
    required this.exchangeId,
    required this.evaluatorId,
    required this.evaluatedId,
    required this.rating,
    this.comment,
    this.reply,
    required this.isReported,
    required this.createdAt,
    this.evaluatorName,
    this.evaluatorAvatarUrl,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final evaluator = json['evaluator'] as Map<String, dynamic>?;

    return Review(
      id: json['id'] as String,
      exchangeId: json['exchange_id'] as String,
      evaluatorId: json['evaluator_id'] as String,
      evaluatedId: json['evaluated_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      reply: json['reply'] as String?,
      isReported: json['is_reported'] == true,
      createdAt: DateTime.parse(json['created_at'] as String),
      evaluatorName: evaluator?['nombre'] as String?,
      evaluatorAvatarUrl: evaluator?['avatar_url'] as String?,
    );
  }
}