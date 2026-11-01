/// Où mène chaque type de notification : la même règle pour l'écran des notifications et pour un appui
/// sur une notification push.
String notificationDestination(String type) {
  if (type.startsWith('VERIFICATION_')) return '/profile';
  switch (type) {
    case 'NEW_ATTENDEE':
      return '/my-events';
    case 'NEW_ORGANIZER_REQUEST':
      return '/moderation';
    case 'ORGANIZER_APPROVED':
    case 'ORGANIZER_REJECTED':
      return '/profile';
    case 'WAITLIST_PROMOTED':
    case 'EVENT_REMINDER':
    case 'EVENT_CROSSED':
      return '/events';
    default:
      // NEW_MATCH, NEW_MESSAGE, NEW_REQUEST : les messages (les demandes y sont en haut)
      return '/chat';
  }
}
