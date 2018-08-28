# https://cloud.google.com/translate/docs/reference/libraries#client-libraries-install-nodejs
# export GOOGLE_APPLICATION_CREDENTIALS=/opt/googleCredential/Traduction-ECTS-478b71d14d3a.json

Translate = require "@google-cloud/translate"
projectId = 'traduction-ects-1535444608932'

translate = new Translate
  projectId: projectId

options =
  from: 'fr'
  to: 'en'

unless process.argv[2]?
  console.log "Lancement : coffee ./traductionCatalogue <fichierVol.json>"
  process.exit(0)

courses = require process.argv[2]

courses.forEach (departement) ->
  departement.semestres.forEach (semestre) ->
    semestre.ecs.forEach (ec) ->
      Promise.all [
        translate.translate(ec.detail.nom, options)
        translate.translate(ec.detail.competencesBrutes, options)
      ]
      .then ([nomAnglais, CompetenceAnglais]) ->
        console.log "---------------------------"
        console.log "#{ec.detail.code}"
        console.log "#{ec.detail.nom}\n"
        console.log "#{ec.detail.competencesBrutes}"
        console.log "---"
        console.log "#{nomAnglais[0]}\n"
        console.log "#{CompetenceAnglais[0]}"
        console.log()
      .catch (err) ->
        console.error('ERREUR : ', err)
