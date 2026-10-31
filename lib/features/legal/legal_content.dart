// Textes légaux d'Elahrisa.
// À faire relire par un juriste avant la publication sur les stores.

const legalContactEmail = 'melkimohamedaziz1@gmail.com';
const legalLastUpdate = '31 octobre 2026';

class LegalSection {
  final String title;
  final List<String> paragraphs;
  const LegalSection(this.title, this.paragraphs);
}

const termsSections = <LegalSection>[
  LegalSection('Qui peut utiliser Elahrisa', [
    'Elahrisa est réservée aux personnes de 18 ans révolus. En créant un compte, vous confirmez avoir au moins 18 ans et que les informations que vous donnez (nom, date de naissance, genre, photos) sont exactes.',
    'Vous ne pouvez avoir qu\'un seul compte, et vous ne devez jamais vous faire passer pour une autre personne.',
  ]),
  LegalSection('Votre compte', [
    'Vous êtes responsable de la confidentialité de votre mot de passe et de ce qui se passe depuis votre compte. Si vous pensez que quelqu\'un y a accédé, changez votre mot de passe via « Mot de passe oublié ? » et prévenez-nous.',
  ]),
  LegalSection('Comportement attendu', [
    'Elahrisa est faite pour des rencontres et des sorties respectueuses. Il est interdit de harceler, menacer ou insulter, de publier des contenus violents, haineux, pornographiques ou illégaux, de demander de l\'argent, de faire de la publicité ou de la prospection, et d\'utiliser des photos qui ne sont pas les vôtres.',
    'Vous restez propriétaire de vos photos et textes. En les publiant, vous nous autorisez à les afficher aux autres membres dans l\'application, pour le seul besoin du service.',
  ]),
  LegalSection('Signalement et modération', [
    'Vous pouvez signaler ou bloquer un membre à tout moment. Notre équipe examine les signalements et peut avertir un membre, supprimer un contenu ou désactiver un compte qui ne respecte pas ces conditions, sans préavis en cas de comportement grave.',
    'Le badge « profil vérifié » indique qu\'un selfie a été comparé à vos photos. Il ne garantit pas l\'honnêteté d\'une personne.',
  ]),
  LegalSection('Votre sécurité', [
    'Restez prudent : pour un premier rendez-vous, choisissez un lieu public, prévenez un proche, ne donnez ni votre adresse ni vos informations bancaires, et méfiez-vous de toute demande d\'argent. Nous ne pouvons pas vérifier l\'identité ni les intentions de chaque membre.',
  ]),
  LegalSection('Événements', [
    'Les événements affichés sont proposés par des organisateurs ou importés de sources publiques. Elahrisa n\'organise pas ces événements et n\'est pas responsable de leur déroulement, de leur annulation ni de leurs prix : vérifiez les informations auprès de l\'organisateur.',
  ]),
  LegalSection('Disponibilité et responsabilité', [
    'Nous faisons notre possible pour que l\'application soit disponible, mais elle peut être interrompue pour maintenance ou en cas de problème technique. Elahrisa est fournie « en l\'état » : dans les limites permises par la loi, nous ne sommes pas responsables des échanges ni des rencontres entre membres.',
  ]),
  LegalSection('Fin du compte', [
    'Vous pouvez supprimer votre compte à tout moment depuis Profil, « Supprimer mon compte ». Votre profil, vos photos, vos matchs et vos messages sont alors effacés définitivement.',
  ]),
  LegalSection('Modifications et droit applicable', [
    'Nous pouvons modifier ces conditions ; en cas de changement important, nous vous en informerons dans l\'application. Ces conditions sont soumises au droit tunisien.',
  ]),
  LegalSection('Nous contacter', [
    'Pour toute question : $legalContactEmail',
  ]),
];

const privacySections = <LegalSection>[
  LegalSection('Ce que nous collectons', [
    'À l\'inscription : nom, prénom, numéro de CIN, date de naissance, genre, adresse email et mot de passe (conservé uniquement sous forme chiffrée).',
    'Sur votre profil : biographie, centres d\'intérêt, préférences de rencontre et photos.',
    'Votre position, seulement si vous l\'autorisez, pour vous montrer des profils et des sorties proches de vous.',
    'Vos activités : swipes, matchs, messages, événements rejoints, signalements et blocages.',
    'Un selfie, seulement si vous demandez la vérification de votre profil.',
  ]),
  LegalSection('Pourquoi', [
    'Pour créer et sécuriser votre compte, vous proposer des profils et des événements, permettre les échanges entre membres, vérifier les profils, modérer les abus et vous envoyer les emails nécessaires au service (vérification de l\'adresse, réinitialisation du mot de passe).',
    'Nous ne vendons pas vos données et nous n\'affichons pas de publicité ciblée.',
  ]),
  LegalSection('Qui voit quoi', [
    'Les autres membres voient votre prénom, votre âge, vos photos, votre biographie, vos centres d\'intérêt et la distance qui vous sépare. Ils ne voient jamais votre email, votre CIN, votre date de naissance exacte ni votre position précise.',
    'Votre selfie de vérification n\'est visible que de l\'équipe de modération.',
  ]),
  LegalSection('Services qui traitent vos données', [
    'Pour faire fonctionner Elahrisa, nous faisons appel à des prestataires : un hébergeur pour le serveur, un service de base de données, un service de stockage des photos et un service d\'envoi d\'emails. Ils n\'utilisent vos données que pour fournir ce service. Certains peuvent être situés hors de Tunisie.',
  ]),
  LegalSection('Combien de temps', [
    'Nous conservons vos données tant que votre compte existe. Quand vous supprimez votre compte, votre profil, vos photos, vos matchs et vos messages sont effacés définitivement. Les éléments liés à un signalement peuvent être conservés le temps nécessaire à la sécurité des membres.',
  ]),
  LegalSection('Vos droits', [
    'Vous pouvez à tout moment consulter et modifier vos informations dans l\'application, retirer l\'accès à votre position dans les réglages de votre téléphone, et supprimer votre compte. Vous pouvez aussi demander l\'accès à vos données, leur correction ou leur effacement en nous écrivant à $legalContactEmail.',
    'Le traitement des données personnelles en Tunisie est encadré par la loi organique n° 2004-63 du 27 juillet 2004. Vous pouvez vous adresser à l\'Instance nationale de protection des données personnelles (INPDP) si vous estimez que vos droits ne sont pas respectés.',
  ]),
  LegalSection('Sécurité', [
    'Les échanges avec nos serveurs sont chiffrés (HTTPS), les mots de passe sont protégés par un hachage et l\'accès aux données de modération est limité. Aucun système n\'est sûr à 100 % : choisissez un mot de passe solide et unique.',
  ]),
  LegalSection('Mineurs', [
    'Elahrisa est interdite aux moins de 18 ans. Si vous pensez qu\'un mineur s\'est inscrit, signalez-le : nous supprimerons son compte.',
  ]),
  LegalSection('Modifications', [
    'Cette politique peut évoluer. En cas de changement important, nous vous en informerons dans l\'application.',
  ]),
];
