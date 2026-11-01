/// Les photos sont stockées sur Cloudinary en grande taille (jusqu'à 1600 px). Pour un écran de téléphone,
/// on demande à Cloudinary une version réduite et recompressée : l'image arrive plusieurs fois plus vite,
/// et reste nette. Le format d'origine est gardé (jpg reste jpg).
///
/// Les autres adresses (photos locales, autres hébergeurs) sont renvoyées telles quelles.
String optimizedImageUrl(String url, {int width = 900}) {
  const marker = '/image/upload/';
  if (!url.contains('res.cloudinary.com') || !url.contains(marker)) return url;

  final cut = url.indexOf(marker) + marker.length;
  final rest = url.substring(cut);

  // Déjà transformée (par exemple « c_limit,w_900/... ») : on ne la double pas.
  // Une version commence par « v123/ » et n'est pas une transformation.
  final startsWithVersion = RegExp(r'^v\d+/').hasMatch(rest);
  final startsWithTransform = RegExp(r'^[a-z]{1,3}_[^/]*/').hasMatch(rest);
  if (startsWithTransform && !startsWithVersion) return url;

  final w = width.clamp(100, 1600);
  return '${url.substring(0, cut)}c_limit,w_$w,q_auto/$rest';
}
