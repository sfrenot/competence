Lancement initial
------------------
export GOOGLE_APPLICATION_CREDENTIALS=/opt/googleCredential/Traduction-ECTS-478b71d14d3a.json
export PATH=$PATH:/opt/googleCredential/google-cloud-sdk/bin

Pas de 'gcloud init' -> A vérifier la prochaine fois


curl -s -X POST -H "Content-Type: application/json" \
     -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
     --data "{
   'q': 'The Great Pyramid of Giza (also known as the Pyramid of Khufu or the
         Pyramid of Cheops) is the oldest and largest of the three pyramids in
         the Giza pyramid complex.',
   'source': 'en',
   'target': 'es',
   'format': 'text'
 }" "https://translation.googleapis.com/language/translate/v2"


======================

https://cloud.google.com/translate/docs/quickstart

- Créer un compte google (gratuit pour 300$)
- Récupérer la clé d'accès
- Placer la variable d'environnement
export GOOGLE_APPLICATION_CREDENTIALS=/opt/googleCredential/Traduction-ECTS-478b71d14d3a.json

- Installer gcloud sdk
- -> gcloud init
curl -s -X POST -H "Content-Type: application/json" \
     -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
     --data "{
   'q': 'The Great Pyramid of Giza (also known as the Pyramid of Khufu or the
         Pyramid of Cheops) is the oldest and largest of the three pyramids in
         the Giza pyramid complex.',
   'source': 'en',
   'target': 'es',
   'format': 'text'
 }" "https://translation.googleapis.com/language/translate/v2"
