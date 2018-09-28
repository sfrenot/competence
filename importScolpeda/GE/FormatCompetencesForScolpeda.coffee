fs = require 'fs'
csv = require 'csvtojson'
Promise = require 'bluebird'
_ = require 'lodash'
refCompetences = require './refCompetences'

currentMat = {}
ec = undefined

matieres = []
currentComp = ''

insertDetail = () ->
  setAndCheckMatiere = (data) ->

    if data.field3 is "Intitulé de l'EC"
      if not _.isEmpty(currentMat)
        # console.log '->', currentMat
        matieres.push(currentMat)
        currentMat = {}
      currentMat.nom = data.field5
      currentMat.ueCode = data.field4
      currentMat.ueName = ''

    if _.isEmpty(currentMat.competencesC)
      currentMat.competencesC = []
    if _.isEmpty(currentMat.competencesM)
      currentMat.competencesM = []

    if data.field1.trim().startsWith("Compétence")
      for i in [11..20]
        if data["field#{i}"]?.trim()?.match(/^[CM]$/)
          if data["field#{i}"] is 'M'
            currentMat.competencesM.push(data.field3.replace(/"/g,''))
          else
            compName = data.field3.replace(/"/g,'').replace('œ', 'oe').replace(/  /g, ' ').trim()
            refComp = refCompetences[compName]
            unless refComp
              console.error("COMPETENCE ERREUR", currentMat.ueCode, JSON.stringify compName,null, 2)
              refComp = ''
            currentMat.competencesC.push("#{refComp} #{compName} (niveau #{data["field#{i-1}"]})")
            currentComp = refComp
          break

  addCompetenceOrConnaissance = (data) ->
    if data.field2 is 'Capacité' and data.field3?.trim()
      if _.isEmpty(currentMat.capacites)
        currentMat.capacites = []
      currentMat.capacites.push("#{data.field3} (#{currentComp})")
      return
    if data.field2 is 'Connaissance' and data.field3?.trim()
      if _.isEmpty(currentMat.connaissances)
        currentMat.connaissances = []
      currentMat.connaissances.push("#{data.field3} (#{currentComp})")
      return

  readCsv = ->
    files = fs.readdirSync('./sources').filter((name) -> name.endsWith('.csv'))
    Promise.map files, (file) ->
      new Promise (resolve, reject) ->
        datas = []
        csv({flatKeys: true, delimiter: ",", noheader: true})
        .fromFile("./sources/#{file}")
        .on 'json', (data) ->
          datas.push data
        .on 'done', (error) ->
          if error
            return reject error
          resolve(datas)

  readCsv()
  .then (datas) ->
    datas = _.flatten(datas)
    datas.forEach (data) ->
      setAndCheckMatiere(data)
      addCompetenceOrConnaissance(data)

    Promise.resolve()

insertDetail()
.then () ->

  # console.log(matieres)
  # process.exit()
  matieres.forEach (matiere) ->
    console.log("#{matiere.nom} ****************************")
    console.log("Cet EC relève de l'unité d'enseignement #{matiere.ueName} (#{matiere.ueCode}) et
contribue aux compétences suivantes :            \n")
    matiere.competencesC.forEach (competence) ->
      console.log(competence)

    if not _.isEmpty(matiere.competencesM)
      console.log("\nDe plus, elle nécessite de mobiliser les compétences suivantes :\n")
      matiere.competencesM.forEach (competenceM) ->
        console.log(competenceM)

    if not _.isEmpty(matiere.connaissances)
      console.log("\nEn permettant à l'étudiant de travailler et d'être évalué sur les connaissances suivantes :\n")
      matiere.connaissances.forEach (connaissance) ->
        console.log("- #{connaissance}")

    if not _.isEmpty(matiere.capacites)
      console.log("\nEn permettant à l'étudiant de travailler et d'être évalué sur les capacités suivantes :")
      matiere.capacites.forEach (capacite) ->
        console.log("- #{capacite}")

.catch (err) ->
  console.log("erreur", err)
