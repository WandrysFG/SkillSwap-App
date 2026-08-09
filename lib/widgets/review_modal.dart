import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_theme.dart';
import 'gradient_button.dart';

class ReviewModal extends StatefulWidget {
  final String exchangeId;
  final String evaluatedId;
  final String evaluatedName;

  const ReviewModal({
    super.key,
    required this.exchangeId,
    required this.evaluatedId,
    required this.evaluatedName,
  });

  @override
  State<ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends State<ReviewModal> {
  final _client = Supabase.instance.client;
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una calificación (1 a 5 estrellas).')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final myId = _client.auth.currentUser!.id;
      
      await _client.from('reviews').insert({
        'exchange_id': widget.exchangeId,
        'evaluator_id': myId,
        'evaluated_id': widget.evaluatedId,
        'rating': _rating,
        'comment': _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
      });

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Reseña enviada! Recuerda que es ciega y se publicará pronto.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      
      if (e.toString().contains('unique constraint') || e.toString().contains('duplicate key')) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya habías evaluado este intercambio anteriormente.')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar la reseña. Intenta de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Text(
                'Califica a ${widget.evaluatedName}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu reseña será ciega: la otra persona no la verá hasta que también te califique a ti.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: index < _rating ? Colors.amber : Colors.black26,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 250,
                decoration: InputDecoration(
                  hintText: 'Cuéntanos cómo fue tu experiencia... (opcional)',
                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              GradientButton(
                label: 'Enviar Reseña',
                loading: _isSubmitting,
                onPressed: _submitReview,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}