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

refs = require '../refCompetences.coffee'

Promise.all _.map refs, (ref, id) ->
  new Promise (resolve, reject) ->
    translate.translate(ref.val, options)
    .then (res) ->
      ref.valAnglais = res[0]
      ref.id = id
      resolve(ref)

.then (result) ->
  console.log _.keyBy(result, 'id')
