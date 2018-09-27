csv = require 'csvtojson'
Promise = require 'bluebird'
_ = require 'lodash'

currentMat = {}
ec = undefined

matieres = []
currentComp = ''

insertDetail = () ->
  setAndCheckMatiere = (data) ->
    if data.field3 is '' and data.field5 isnt '' then return
    if data.field3 isnt ''
      if not _.isEmpty(currentMat)
        # console.log '->', currentMat
        matieres.push(currentMat)
        currentMat = {}
      currentMat.nom = data.field3
      currentMat.ueCode = data.field1
      currentMat.ueName = data.field2

    if _.isEmpty(currentMat.competencesC)
      currentMat.competencesC = []
    if _.isEmpty(currentMat.competencesM)
      currentMat.competencesM = []

    if data.field7 is 'M'
      currentMat.competencesM.push(data.field6.replace(/"/g,''))
    else
      currentMat.competencesC.push("#{data.field6.replace(/"/g,'')} (niveau #{data.field7})")
      currentComp = data.field6.split(' ')[0]

  addCompetenceOrConnaissance = (data) ->
    if data.field5 is '' then return
    if data.field5 is 'Capacité'
      if _.isEmpty(currentMat.capacites)
        currentMat.capacites = []
      currentMat.capacites.push("#{data.field6} (#{currentComp})")
      return
    if data.field5 is 'Connaissance'
      if _.isEmpty(currentMat.connaissances)
        currentMat.connaissances = []
      currentMat.connaissances.push("#{data.field6} (#{currentComp})")
      return
    console.error('ERREUR', data)

  readCsv = ->
    new Promise (resolve, reject) ->
      datas = []

      csv({flatKeys: true, delimiter: ";", noheader: true})
      .fromFile('./DetailCompetences.csv')
      .on 'json', (data) ->
        datas.push data
      .on 'done', (error) ->
        if error
          return reject error
        resolve(datas)

  readCsv()
  .then (datas) ->
    # console.log(datas)
    datas.forEach (data) ->
      setAndCheckMatiere(data)
      addCompetenceOrConnaissance(data)

    Promise.resolve()

insertDetail()
.then () ->
  # console.log(matieres)
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
