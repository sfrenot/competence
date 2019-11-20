csv = require 'csvtojson'
Promise = require 'bluebird'
_ = require 'lodash'
refCompetences = require '../../formation/refCompetences'

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

    competence = data.field6.replace(/"/g,'').replace(/’/g, '\'').replace('oe', 'œ').trim()

    # console.log '->', competence, data

    [,ref,detail] = /(\w\d) (.*)/.exec(competence)
    if ref > 'B99'
      ref = "TC-#{ref}"
    if not refCompetences[ref] or refCompetences[ref].val isnt detail
      console.error("COMPETENCE ERREUR", currentMat, ref, JSON.stringify competence,null, 2)
      console.error(ref)
      console.error(detail)
      console.error(refCompetences[ref])
      console.error(refCompetences[ref].val)


      process.exit()
    else
      if data.field7 is 'M'
        currentMat.competencesM.push(competence)
      else
        currentMat.competencesC.push("#{competence} (niveau #{data.field7})")
        currentComp = data.field6.split(' ')[0]

  addCompetenceOrConnaissance = (data) ->
    if data.field5 is 'Capacité' and data.field6?
      if _.isEmpty(currentMat.capacites)
        currentMat.capacites = {}
      if _.isEmpty(currentMat.capacites[currentComp])
        currentMat.capacites[currentComp] = []
      currentMat.capacites[currentComp].push("Capacité : #{data.field6.replace('oe', 'œ')
}")
      return
    if data.field5 is 'Connaissance' and data.field6
      if _.isEmpty(currentMat.connaissances)
        currentMat.connaissances = {}
      if _.isEmpty(currentMat.connaissances[currentComp])
        currentMat.connaissances[currentComp] = []
      currentMat.connaissances[currentComp].push("Connaissance : #{data.field6.replace('oe', 'œ')
}")
      return

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
  matieres.push(currentMat)
  matieres.forEach (matiere) ->
    console.log("#{matiere.nom} ****************************")
    console.log("Cet EC relève de l'unité d'enseignement #{matiere.ueName} (#{matiere.ueCode}) et
contribue aux compétences suivantes :            \n")
    matiere.competencesC.forEach (competence) ->
      console.log("#{competence}\n")

      ref = competence.split(' ')[0]
      if matiere.capacites?[ref]?
        matiere.capacites[ref].forEach (comp) ->
          console.log("  #{comp}")
        console.log()
      if matiere.connaissances?[ref]?
        matiere.connaissances[ref].forEach (comp) ->
          console.log("  #{comp}")
        console.log()

    if not _.isEmpty(matiere.competencesM)
      console.log("\nDe plus, elle nécessite de mobiliser les compétences suivantes :\n")
      matiere.competencesM.forEach (competenceM) ->
        console.log(competenceM)

.catch (err) ->
  console.log("erreur", err)
