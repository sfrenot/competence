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

    if /\d/.test(data.field3)
      currentMat.nom = data.field1
      currentMat.ueCode = data.field4
      currentMat.ueName = ''

      if _.isEmpty(currentMat.competencesC)
        currentMat.competencesC = []
      if _.isEmpty(currentMat.competencesM)
        currentMat.competencesM = []

      for i in [5..32]
        if data["field#{i}"]?.trim()?.match(/^[\d+M]/)
          tmpComp = _.find(refCompetences, {'bs': (i-4).toString()})
          if data["field#{i}"] is 'M'
            currentMat.competencesM.push("#{tmpComp.code} #{tmpComp.val}")
          else
            currentMat.competencesC.push("#{tmpComp.code} #{tmpComp.val} (niveau #{data["field#{i}"]})")

  addCompetenceOrConnaissance = (data) ->
    if /\d/.test(data.field3)
      capacites = data.field33.trim()
      if not _.isEmpty(capacites) and capacites isnt 'A compléter'
        if _.isEmpty(currentMat.capacites)
          currentMat.capacites = {}
        if /.*?\d+\)/.test(capacites)
          capacites.match(/.*?\d+\)/g).map (line) ->
            console.log "->#{line}"
            if /(.*?)\(([\d, \.]+)\)/.test(line)
              [, capacite, comp] = line.match(/(.*?)\(([\d, \.]+)\)/)
            else
              [, capacite, comp] = line.match(/(.*?)\(([C\d, \.]+)\)/)
              if comp is 'C1,1' then comp = 'C1.1'

            # console.log "Capacite : #{capacite} --> #{comp.split(/, /)}"
            capacite = capacite.trim().replace(/^[-;.,]/, '').replace(/^. +-/, '').replace(/^ +/,'').trim()

            comp.split(/,/).forEach (x) ->
              x = x.trim()
              if x is 'C1.1' then x='15'
              if x is 'C3.4' or x is 'C3.1' then x='9'
              if x is 'C2.2' then x='8'
              if x is 'C11' then x='15'
              if x is 'C13' then x='17'
              if x is 'C15' then x='16'

              if not _.isEmpty(x)
                tmpComp = _.find(refCompetences, {'bs': x.trim().toString()})
                unless tmpComp?
                  console.log "**#{x}**"
                  [, main, subcompetence] = x.trim().match(/(\d+)\.\d+/)
                  tmpComp = _.find(refCompetences, {'bs': main.toString()})

                # console.log "#{JSON.stringify currentMat, null, 2}"
                if tmpComp?
                  if _.isEmpty(currentMat.capacites[tmpComp.code])
                    currentMat.capacites[tmpComp.code] = []
                  currentMat.capacites[tmpComp.code].push("capacite : #{capacite}")
                  currentMat.capacites[tmpComp.code] = _.uniq(currentMat.capacites[tmpComp.code])
                else
                  console.error "Competence inconnue #{x}, #{JSON.stringify currentMat, null, 2}"
        else
          capacites.split(/\./).forEach (x) ->
            if _.isEmpty(currentMat.capacites['Inconnu'])
              currentMat.capacites['Inconnu'] = []
            currentMat.capacites['Inconnu'].push("capacite : #{x}")
            currentMat.capacites['Inconnu'] = _.uniq(currentMat.capacites['Inconnu'])

      # console.log JSON.stringify currentMat, null, 2
      # console.log '->', data.field33
      # process.exit()

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
      unless _.isEmpty(currentMat)
        matieres.push(currentMat)
        currentMat = {}

    Promise.resolve()

insertDetail()
.then () ->
  console.log('->', JSON.stringify matieres, null, 2)
#   # process.exit()
#   matieres.forEach (matiere) ->
#     console.log("#{matiere.nom} ****************************")
#     console.log("Cet EC relève de l'unité d'enseignement #{matiere.ueName} (#{matiere.ueCode}) et
# contribue aux compétences suivantes :            \n")
#     matiere.competencesC.forEach (competence) ->
#
#       ref = competence.split(' ')[0]
#       if ref is "####"
#         ref = competence
#         console.log(" Sous compétence : #{competence.substring(5)}\n")
#       else
#         console.log("#{competence}\n")
#
#       if matiere.capacites?[ref]?
#         matiere.capacites[ref].forEach (comp) ->
#           console.log("  #{comp}")
#         console.log()
#       if matiere.connaissances?[ref]?
#         matiere.connaissances[ref].forEach (comp) ->
#           console.log("  #{comp}")
#         console.log()
#
#     if not _.isEmpty(matiere.competencesM)
#       console.log("\nDe plus, elle nécessite de mobiliser les compétences suivantes :\n")
#       matiere.competencesM.forEach (competenceM) ->
#         console.log(competenceM)
#
.catch (err) ->
  console.log("erreur", err)
