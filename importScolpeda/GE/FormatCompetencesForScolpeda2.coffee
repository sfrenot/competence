fs = require 'fs'
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

    if data.field3 is "Intitulé de l'EC"
      if not _.isEmpty(currentMat)
        # console.log '->', currentMat
        matieres.push(currentMat)
        currentMat = {}
      currentMat.nom = data.field5
      currentMat.ueCode = data.field2
      currentMat.ueName = ''

    if _.isEmpty(currentMat.competencesC)
      currentMat.competencesC = []
    if _.isEmpty(currentMat.competencesM)
      currentMat.competencesM = []

    if data.field1.trim().startsWith("Compétence")
      for i in [11..20]
        if data["field#{i}"]?.trim()?.match(/^[CM]$/)
          compName = data.field3.replace(/"/g,'').replace('oe', 'œ').replace(/  /g, ' ').trim()
          tmpComp = _.find(refCompetences, {'val': compName})
          unless tmpComp
            console.error("COMPETENCE ERREUR", JSON.stringify(currentMat,null, 2), JSON.stringify compName,null, 2)
            process.exit()
          else
            refComp = tmpComp.code

          if data["field#{i}"] is 'M'
            currentMat.competencesM.push("#{refComp} #{compName}")
          else
            currentMat.competencesC.push("#{refComp} #{compName} (niveau #{data["field#{i-1}"]})")
            currentComp = refComp
          break

  addCompetenceOrConnaissance = (data) ->
    if data.field2?.trim() is 'Sous compétence'
      currentComp = "#### #{data.field3.trim()}"
      currentMat.competencesC.push(currentComp)
      return
    if data.field2 is 'Capacité' and data.field3?.trim()
      if _.isEmpty(currentMat.capacites)
        currentMat.capacites = {}
      if _.isEmpty(currentMat.capacites[currentComp])
        currentMat.capacites[currentComp] = []
      currentMat.capacites[currentComp].push("Capacité : #{data.field3}")
      return
    if data.field2 is 'Connaissance' and data.field3?.trim()
      if _.isEmpty(currentMat.connaissances)
        currentMat.connaissances = {}
      if _.isEmpty(currentMat.connaissances[currentComp])
        currentMat.connaissances[currentComp] = []
      currentMat.connaissances[currentComp].push("Connaissance : #{data.field3}")
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
      # console.log '->', data
      setAndCheckMatiere(data)
      addCompetenceOrConnaissance(data)

    Promise.resolve()

insertDetail()
.then () ->
  matieres.push(currentMat)
  # console.log('->', JSON.stringify matieres, null, 2)
  # process.exit()
  matieres.forEach (matiere) ->
    console.log("#{matiere.nom} ****************************")
    console.log("Cet EC relève de l'unité d'enseignement #{matiere.ueName} (#{matiere.ueCode}) et
contribue aux compétences suivantes :            \n")
    matiere.competencesC.forEach (competence) ->

      ref = competence.split(' ')[0]
      if ref is "####"
        ref = competence
        console.log(" Sous compétence : #{competence.substring(5)}\n")
      else
        console.log("#{competence}\n")

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
