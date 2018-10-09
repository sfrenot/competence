fs = require 'fs'
csv = require 'csvtojson'
Promise = require 'bluebird'
_ = require 'lodash'
refCompetences = require './refCompetences'

currentMat = {}
ec = undefined

matieres = []
currentComp = ''
sectionCapacite = false

insertDetail = () ->
  setAndCheckMatiere = (data) ->
    if data.field7.trim() is 'Compétences école' or data.field2.trim() is 'GI-3-MOI-S1'

      sectionCapacite = false
      currentMat = {}


    if data.field1.startsWith('UE : ')
      sectionCapacite = false
      if not _.isEmpty(currentMat)
        # console.log '->', currentMat
        matieres.push(currentMat)
        currentMat = {}
      currentMat.ueName = data.field1.split(' : ')[1]
      currentMat.ueCode = ''

    if data.field1.startsWith('EC : ')
      sectionCapacite = false
      currentMat.nom = data.field1.split(' : ')[1]

    if _.isEmpty(currentMat.competencesC)
      currentMat.competencesC = []
    if _.isEmpty(currentMat.competencesM)
      currentMat.competencesM = []

    if data.field2.trim().startsWith("Compétence")
      if data.field8.trim() is 'M'
        currentMat.competencesM.push(data.field3.replace(/"/g,''))
      else
        compName = data.field3.replace(/"/g,'').replace('œ', 'oe').replace(/  /g, ' ').trim()
        refComp = refCompetences[compName]
        unless refComp
          console.error("ERREUR #{(JSON.stringify compName,null, 2)} : '#{data.field2.split(' ')[1]}'")
          refComp = '??'
        if data.field8.trim() is ''
          currentMat.competencesC.push("#{refComp} #{compName}")
        else
          currentMat.competencesC.push("#{refComp} #{compName}")
        currentComp = refComp

  addCompetenceOrConnaissance = (data) ->

    if data.field1 is 'CAPACITES' or data.field3 is 'CONNAISSANCE'
      sectionCapacite = true
      return

    if sectionCapacite
      if not _.isEmpty(data.field1)
        if _.isEmpty(currentMat.capacites)
          currentMat.capacites = []
        currentMat.capacites.push("#{data.field1.trim()}")

      if not _.isEmpty(data.field3)
        if _.isEmpty(currentMat.connaissances)
          currentMat.connaissances = []
        currentMat.connaissances.push("#{data.field3.trim()}")


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
