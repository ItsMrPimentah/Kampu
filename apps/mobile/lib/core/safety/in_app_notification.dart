/// A notification displayed in the safety inbox.
class InAppNotification {
  /// Creates a notification with its title and body.
  const InAppNotification({required this.title, required this.body});

  /// Notification title.
  final String title;

  /// Notification content.
  final String body;
}
