# https://cloud.google.com/translate/docs/reference/libraries#client-libraries-install-nodejs
# export GOOGLE_APPLICATION_CREDENTIALS=/opt/googleCredential/Traduction-ECTS-478b71d14d3a.json
_ = require "lodash"
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

console.log '['
courses.forEach (departement) ->
  departement.semestres.forEach (semestre) ->
    semestre.ecs.forEach (ec) ->
      if not _.isEmpty(ec.detail.capacite) or not _.isEmpty(ec.detail.connaissance)
        Promise.all [
          translate.translate(ec.UE, options)
          translate.translate(ec.detail.nom, options)
          # Promise.resolve([ec.detail.nom])
          if not _.isEmpty(ec.detail.capacite)
            # Promise.resolve(["English"])
            translate.translate(ec.detail.capacite.join("\n"), options)
          else
            Promise.resolve([ec.detail.capacite])
          if not _.isEmpty(ec.detail.connaissance)
            translate.translate(ec.detail.connaissance.join("\n"), options)
          else
            Promise.resolve([ec.detail.connaissance])
        ]
        .then ([ueAnglais, nomAnglais, capacite, connaissance]) ->
          ec.UEAnglais = ueAnglais[0]
          ec.detail.nomAnglais = nomAnglais[0]
          unless _.isEmpty(ec.detail.capacite)
            ec.detail.capaciteAnglais = capacite[0].split('\n')
          unless _.isEmpty(ec.detail.connaissance)
            ec.detail.connaissanceAnglais = connaissance[0].split('\n')
          console.log(JSON.stringify ec, null, 2)
          console.log(',')
        .catch (err) ->
          console.error('ERREUR : ', err)
