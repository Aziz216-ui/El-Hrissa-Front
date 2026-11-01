import 'package:flutter_test/flutter_test.dart';

import 'package:el_hrissa_front/shared/utils/image_url.dart';
import 'package:el_hrissa_front/shared/widgets/network_photo.dart';

void main() {
  const original = 'https://res.cloudinary.com/demo/image/upload/v1730000000/profiles/16/abc.jpg';

  group('photos Cloudinary', () {
    test('une photo est demandée en version réduite, le reste de l\'adresse est intact', () {
      expect(
        optimizedImageUrl(original),
        'https://res.cloudinary.com/demo/image/upload/c_limit,w_900,q_auto/v1730000000/profiles/16/abc.jpg',
      );
    });

    test('la largeur est ajustée, entre 100 et 1600', () {
      expect(optimizedImageUrl(original, width: 300), contains('w_300'));
      expect(optimizedImageUrl(original, width: 5000), contains('w_1600'));
      expect(optimizedImageUrl(original, width: 10), contains('w_100'));
    });

    test('une adresse déjà transformée n\'est pas transformée deux fois', () {
      const done = 'https://res.cloudinary.com/demo/image/upload/c_limit,w_900,q_auto/v1730000000/abc.jpg';
      expect(optimizedImageUrl(done), done);
    });

    test('sans numéro de version, la photo est quand même réduite', () {
      expect(
        optimizedImageUrl('https://res.cloudinary.com/demo/image/upload/profiles/abc.jpg'),
        'https://res.cloudinary.com/demo/image/upload/c_limit,w_900,q_auto/profiles/abc.jpg',
      );
    });
  });

  group('autres adresses', () {
    test('les photos locales et les autres hébergeurs ne sont pas touchés', () {
      expect(optimizedImageUrl('https://el-hrissa.onrender.com/uploads/profiles/1/a.png'), 'https://el-hrissa.onrender.com/uploads/profiles/1/a.png');
      expect(optimizedImageUrl('https://i.pravatar.cc/600?img=49'), 'https://i.pravatar.cc/600?img=49');
      expect(optimizedImageUrl(''), '');
    });
  });

  group('NetworkPhoto.sourceFor', () {
    test('une grande carte demande 900 px', () {
      expect(NetworkPhoto.sourceFor(original), contains('w_900'));
    });

    test('un petit avatar demande trois fois sa taille (écrans denses)', () {
      expect(NetworkPhoto.sourceFor(original, width: 56), contains('w_168'));
    });

    test('la taille demandée explicitement l\'emporte', () {
      expect(NetworkPhoto.sourceFor(original, width: 56, maxWidth: 400), contains('w_400'));
    });
  });
}
