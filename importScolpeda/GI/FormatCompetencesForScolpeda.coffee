fs = require 'fs'
csv = require 'csvtojson'
Promise = require 'bluebird'
_ = require 'lodash'
refCompetences = require '../../formation/refCompetences'

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
      currentMat.ueName = ''
      currentMat.ueCode = data.field1.split(' : ')[1]

    if data.field1.startsWith('EC : ')
      sectionCapacite = false
      currentMat.nom = data.field1.split(' : ')[1]

    if _.isEmpty(currentMat.competencesC)
      currentMat.competencesC = []
    if _.isEmpty(currentMat.competencesM)
      currentMat.competencesM = []

    if data.field2.trim().startsWith("Compétence")
      if data.field8.trim() is 'M'
        compName = data.field3.replace(/"/g,'').replace('œ', 'oe')
        tmpComp = _.find(refCompetences, {'val': compName})
        unless tmpComp
            console.error("COMPETENCE ERREUR", currentMat.ueCode, JSON.stringify compName,null, 2)
            process.exit()
          else
            refComp = tmpComp.code

        currentMat.competencesM.push("#{refComp} #{compName}")
      else
        compName = data.field3.replace(/"/g,'').replace('œ', 'oe').replace(/  /g, ' ').trim()
        tmpComp = _.find(refCompetences, {'val': compName})
        unless tmpComp
            console.error("COMPETENCE ERREUR", currentMat.ueCode, JSON.stringify compName,null, 2)
            process.exit()
          else
            refComp = tmpComp.code

        if data.field8.trim() is ''
          currentMat.competencesC.push("#{refComp} #{compName}")
        else
          if data.field8.trim() is 'C'
            currentMat.competencesC.push("#{refComp} #{compName} (niveau 3)")
          else
            currentMat.competencesC.push("#{refComp} #{compName} (niveau #{data.field8})")

        currentComp = refComp

  addCompetenceOrConnaissance = (data) ->
    addOtherCompetences = (elem, matiere) ->
      #console.error '->', elem
      complist = /.* \((.*)\).*/.exec(elem)
      if complist?[1] # (1, 2 , 4)
        res = complist[1].split(',')
        # console.error '->', res.map (elem) -> elem
        res.forEach (val) ->
          valAsNum = new Number(val)
          if not isNaN(valAsNum) and (valAsNum < 6 or valAsNum > 26)
            if valAsNum < 6
              comp = refCompetences["A#{valAsNum}"]
              matiere.competencesM.push("#{comp.code} #{comp.val}")
            else
              comp = refCompetences["B#{valAsNum - 26}"]
              matiere.competencesM.push("#{comp.code} #{comp.val}")

    if data.field1 is 'CAPACITES' or data.field3 is 'CONNAISSANCE'
      sectionCapacite = true
      return

    if sectionCapacite
      if not _.isEmpty(data.field1)
        if _.isEmpty(currentMat.capacites)
          currentMat.capacites = []
        currentMat.capacites.push("#{data.field1.trim()}")
        addOtherCompetences(data.field1.trim(), currentMat)

      if not _.isEmpty(data.field3)
        if _.isEmpty(currentMat.connaissances)
          currentMat.connaissances = []
        currentMat.connaissances.push("#{data.field3.trim()}")
        addOtherCompetences(data.field3.trim(), currentMat)

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
      currentMat.competencesM = _.uniq(currentMat.competencesM)
      currentMat.competencesC = _.uniq(currentMat.competencesC)


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
