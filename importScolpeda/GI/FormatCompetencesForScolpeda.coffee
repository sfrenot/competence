fs = require 'fs'
csv = require 'csvtojson'
Promise = require 'bluebird'
_ = require 'lodash'
refCompetences = require '../../formation/refCompetences'

currentMat = {}
ec = undefined

matieres = []
sectionCapacite = false

ues =
  "GI-3-AUTOM-S1": "Automatique"
  "GI-3-MOI-S1": "Méthodes et outils d'ingénierie industrielle"
  "GI-3-INFO-S1": "Informatique"
  "GI-3-MECA-S1": "Mécanique"
  "GI-3-HU EPS-S1": "Humanités et Education sportive"
  "GI-3-AUTOM-S2": "Automatique"
  "GI-3-INFO-S2": "Informatique et optimisation"
  "GI-3-MECA-S2": "Mécanique"
  "GI-3-HU EPS -S2": "Humanités et Education sportive"
  "GI-4-AUT1-S1": "Automatique"
  "GI-4-GP SIM-S1": "Gestion de production et des flux"
  "GI-4-HU EPS-S1": "Humanités et Education sportive"
  "GI-4-INFO-S1": "Informatique"
  "GI-4-PCO-S1": "Projets Collectifs"
  "GI-4-GOP-S2": "Gestion et Optimisation de la Production"
  "GI-4-PEP-S2": "Pilotage et performance"
  "GI-4 HU EPS-S2": "Humanités et Education sportive"
  "GI-4-PCO-S2": "Projets collectifs"
  "GI-4-STI-S2": "Stage industriel"
  "GI-5-ENTR-S1": "Management de l'entreprise"
  "GI-5-TAI 1A-S1": "Techniques Avancées de l'Ingénieur 1A"
  "GI-5-PRI 1A-S1": "Projets Industriels 1A"
  "GI-5-EPS-S1": "Humanités et Education sportive"
  "GI-5-PFE-S2": "Projet de Fin d'Etudes"
  "GI-5-R&D1-s1": "Optimisation de la chaîne logistique dans l'industrie 4.0 "
  "GI-5-TAI 2A-S1": "Techniques Avancées de l'Ingénieur 2A"
  "GI-5-PRI 2A-S1": "Projets Industriels 2A"

insertDetail = () ->
  setAndCheckMatiere = (data) ->
    # if not data.field7 then return
    # console.log '->', data.field1

    if data.field3 is undefined
      return

    if data.field7.trim() is 'Compétences école'

      sectionCapacite = false
      currentMat = {}


    if data.field1.startsWith('UE : ')
      sectionCapacite = false
      if not _.isEmpty(currentMat)
        # console.log '->', currentMat
        matieres.push(currentMat)
        currentMat = {}
      unless ues[data.field1.split(' : ')[1]]
        console.log "ue inconnue : #{data.field1.split(' : ')[1]}"
        process.exit()
      currentMat.ueName = ues[data.field1.split(' : ')[1]]
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
        compName = data.field3.replace(/"/g,'')
        tmpComp = _.find(refCompetences, {'val': compName})
        unless tmpComp
            console.error("COMPETENCE ERREUR", currentMat.nom, JSON.stringify compName,null, 2)
            process.exit()
          else
            refComp = tmpComp.code

        currentMat.competencesM.push("#{refComp} #{compName}")
      else
        compName = data.field3.replace(/"/g,'').replace(/  /g, ' ').trim()
        tmpComp = _.find(refCompetences, {'val': compName})
        unless tmpComp
            console.error("COMPETENCE ERREUR", currentMat.nom, JSON.stringify compName,null, 2)
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

  addCompetenceOrConnaissance = (data) ->
    addOtherCompetences = (elem, matiere) ->
      testComp = (comp) ->
        findComp = (col, comp) ->
          _.find col, (o) ->
            o.startsWith(comp)

        if not findComp(matiere.competencesC, "#{comp.code} #{comp.val}") and not findComp(matiere.competencesM, "#{comp.code} #{comp.val}")
          # console.error "->", matiere.competencesC
          # console.error "->", matiere.competencesM
          #
          # console.error "->#{comp.code} #{comp.val}"
          console.error 'Competence non indiquée', comp.code, ' pour ', matiere.nom

      #console.error '->', elem
      complist = /(.*) \((.*)\).*/.exec(elem)
      if complist?[2] # (1, 2 , 4)
        res = complist[2].split(',')
        # console.error '->', res.map (elem) -> elem
        rep = res.map (val) ->
          valAsNum = new Number(val)
          if isNaN(valAsNum)
            return val
          if valAsNum < 7
            comp = refCompetences["A#{valAsNum}"]
            testComp(comp)
            return comp.code
          if valAsNum > 26
            comp = refCompetences["B#{valAsNum - 26}"]
            testComp(comp)
            return comp.code
          else
            # console.log "->", valAsNum
            comp = refCompetences["GI-C#{valAsNum}"]
            testComp(comp)
            return comp.code

      if rep?
        "#{complist[1].trim()} (#{rep.join(', ')})"
      else
        "#{elem}"

    if data.field1 is 'CAPACITES' or data.field3 is 'CONNAISSANCE'
      sectionCapacite = true
      return

    if sectionCapacite
      if not _.isEmpty(data.field1)
        if _.isEmpty(currentMat.capacites)
          currentMat.capacites = []
        currentMat.capacites.push(addOtherCompetences(data.field1.trim(), currentMat))

      if not _.isEmpty(data.field3)
        if _.isEmpty(currentMat.connaissances)
          currentMat.connaissances = []
        currentMat.connaissances.push(addOtherCompetences(data.field3.trim(), currentMat))

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
      currentMat.competencesM = _.sortBy(
        _.uniq(currentMat.competencesM), (elem) ->
          tmp = elem.split(' ')[0]
          "#{tmp.substring(0,1)}#{_.padStart(tmp.substring(1), 2)}"
      )

      currentMat.competencesC = _.sortBy(
        _.uniq(currentMat.competencesC), (elem) ->
          tmp = elem.split(' ')[0]
          "#{tmp.substring(0,1)}#{_.padStart(tmp.substring(1), 2)}"
      )


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
