import 'package:flutter/material.dart';

import '../../../data/booking_service.dart';
import '../../../models/booking_model.dart';

class BookingCancelAction extends StatefulWidget {
  final BookingDraft? booking;

  const BookingCancelAction({super.key, this.booking});

  @override
  State<BookingCancelAction> createState() => _BookingCancelActionState();
}

class _BookingCancelActionState extends State<BookingCancelAction> {
  bool _isCancelling = false;

  Future<void> _confirmCancellation() async {
    final booking = widget.booking;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(booking == null ? 'Leave booking?' : 'Cancel booking?'),
        content: Text(
          booking == null
              ? 'Leave this step and return to the previous screen?'
              : 'Cancel booking ${booking.reference} and release its held seats?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(booking == null ? 'Leave' : 'Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      if (booking != null) {
        await BookingService.instance.cancelBooking(
          reference: booking.reference,
        );
      }
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (booking == null) {
        if (navigator.canPop()) navigator.pop();
      } else {
        navigator.popUntil((route) => route.isFirst);
      }
    } on Exception catch (error) {
      _showCancellationError(error);
    } on StateError catch (error) {
      _showCancellationError(error);
    }
  }

  void _showCancellationError(Object error) {
    if (!mounted) return;
    setState(() => _isCancelling = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not cancel booking: $error')));
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _isCancelling ? null : _confirmCancellation,
      style: TextButton.styleFrom(
        foregroundColor:
            Theme.of(context).appBarTheme.foregroundColor ??
            Theme.of(context).colorScheme.error,
      ),
      child: _isCancelling
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Cancel'),
    );
  }
}
