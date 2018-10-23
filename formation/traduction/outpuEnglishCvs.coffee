# https://cloud.google.com/translate/docs/reference/libraries#client-libraries-install-nodejs
# export GOOGLE_APPLICATION_CREDENTIALS=/opt/googleCredential/Traduction-ECTS-478b71d14d3a.json
_ = require "lodash"
refs = require "../refCompetences.coffee"
DPTINSA = 'GEN'

unless process.argv[2]?
  console.log "Lancement : coffee ./outpuEnglishCvs <fichierEn.json>"
  process.exit(0)

courses = require process.argv[2]

courses.forEach (matiere) ->
  console.log("#{matiere.detail.code} ****************************")
  console.log("This EC is part of the teaching unit #{matiere.UEAnglais} and contributes to the following skills:            \n")
  matiere.detail.listeComp.forEach (competence) ->
    if competence.code.startsWith('C')
      ref = "#{DPTINSA}-#{competence.code}"
    else
      ref = competence.code
    console.log("#{competence.code} #{refs[ref].valAnglais}")

    if matiere.detail.competenceToCapaciteEtConnaissance[ref]
      matiere.detail.competenceToCapaciteEtConnaissance[ref].forEach (capa) ->
        console.log '->', capa
        process.exit()
        idx = _.findIndex matiere.detail.capacite, (o) -> o is capa
        if idx > -1
          console.log "  #{matiere.detail.capaciteAnglais[idx]}"
        idx = _.findIndex matiere.detail.connaissance, (o) -> o is capa
        if idx > -1
          console.log "  #{matiere.detail.connaissanceAnglais[idx]}"
      console.log()

  if DPTINSA is 'GEN'
    unless _.isEmpty(matiere.detail.capaciteAnglais)
      matiere.detail.capaciteAnglais.forEach (capa) ->
        console.log "  #{capa}"
    unless _.isEmpty(matiere.detail.connaissanceAnglais)
      matiere.detail.connaissanceAnglais.forEach (capa) ->
        console.log "  #{capa}"

  if not _.isEmpty(matiere.detail.listeCompMobilise)
    console.log("\nIn addition, it requires the following skills:\n")
    matiere.detail.listeCompMobilise.forEach (competenceM) ->

      if competenceM.code.startsWith('C')
        ref = "#{DPTINSA}-#{competenceM.code}"
      else
        ref = competenceM.code
      console.log("#{competenceM.code} #{refs[ref].valAnglais}")
