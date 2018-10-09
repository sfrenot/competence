csv = require 'csvtojson'
Promise = require 'bluebird'
_ = require 'lodash'

currentMat = {}
currentMat.competencesC = []
currentMat.competencesM = []

ec = undefined

matieres = []
currentComp = ''

insertDetail = () ->
  setAndCheckMatiere = (data) ->
    if data.field5 is 'competence'
      if data.field3 isnt ''
        if not _.isEmpty(currentMat)
          # console.log '->', currentMat
          matieres.push(currentMat)
          currentMat = {}
          currentMat.competencesC = []
          currentMat.competencesM = []

        currentMat.nom = data.field3
        currentMat.ueCode = data.field1
        currentMat.ueName = data.field2


      if data.field7 is 'M'
        currentMat.competencesM.push(data.field6.replace(/'/g,''))
      else
        [, code, num, name] = /(\w\w) (\d) (.*)/.exec(data.field6)
        currentMat.competencesC.push("#{code.trim()}#{num.trim()} #{name.replace(/'/g,'')} (niveau #{data.field7})")
        # currentComp = data.field6.split(' ')[0]

  addCompetenceOrConnaissance = (data) ->
    if data.field5 is '' then return
    if data.field5 is 'capacité'
      if _.isEmpty(currentMat.capacites)
        currentMat.capacites = []
      currentMat.capacites.push("#{data.field6}")
      return
    if data.field5 is 'connaissance'
      if _.isEmpty(currentMat.connaissances)
        currentMat.connaissances = []
      currentMat.connaissances.push("#{data.field6}")
      return
    if data.field5 is 'competence'
      return
    console.error('ERREUR', data)

  readCsv = ->
    new Promise (resolve, reject) ->
      datas = []

      csv({flatKeys: true, delimiter: ";", noheader: true})
      .fromFile('./Compétences_GEn.csv')
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
