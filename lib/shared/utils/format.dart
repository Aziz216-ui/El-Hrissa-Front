const _weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

String _two(int n) => n.toString().padLeft(2, '0');

/// « 14h30 » aujourd'hui, « Hier », nom du jour dans la semaine, sinon « 12/03 ».
String formatChatTime(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '${_two(dt.hour)}h${_two(dt.minute)}';
  if (diff == 1) return 'Hier';
  if (diff < 7) return _weekdays[dt.weekday - 1];
  return '${_two(dt.day)}/${_two(dt.month)}';
}

/// « Sam. 21 mars, 21h00 »
String formatEventDate(DateTime? dt) {
  if (dt == null) return 'Date à confirmer';
  return '${_weekdays[dt.weekday - 1]}. ${dt.day} ${_months[dt.month - 1]}, ${_two(dt.hour)}h${_two(dt.minute)}';
}

/// « Il y a 5 min », « Il y a 2 h », « Hier »…
String formatRelative(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  return formatChatTime(dt);
}
