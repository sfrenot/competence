_ = require 'lodash'
unless process.argv[2]?
  console.log "Lancement : coffee ./invert.coffee <catalogue.json>"
  process.exit(0)

courses = require process.argv[2]
refs = require "../refCompetences.coffee"

courses.forEach (departement) ->
  departement.semestres.forEach (semestre) ->
    semestre.ecs.forEach (ec) ->
      _.forEach ec.detail.competenceToCapaciteEtConnaissance, (list, competence) ->
        refComp = refs[competence]
        unless refComp
          console.error("Compétence introuvable #{competence}")
          process.exit(1)
        unless refComp.niveau?
          refComp.niveau = 0
        unless refComp.capacites?
          refComp.capacites = []
        unless refComp.connaissances?
          refComp.connaissances = []
        list.forEach (elem) ->
          if elem.startsWith('Capacité : ')
            refComp.capacites.push(["#{elem.substring('Capacité : '.length)}", "#{ec.detail.code}"])
          else if elem.startsWith('Connaissance : ')
            refComp.connaissances.push(["#{elem.substring('Connaissance : '.length)}", "#{ec.detail.code}"])
          else
            console.error("Connaissance ou capacité mal exprimée #{elem}")
            process.exit(1)
        #Ajout niveaux
        refComp.niveau += Number((_.find ec.detail.listeComp, {"code": refComp.code}).niveau)


_.forEach refs, (value, key) ->
  delete value.valAnglais
  delete value.bs
  delete value.code
  if _.isEmpty(value.connaissances)
    delete value.connaissances
  if _.isEmpty(value.capacites)
    delete value.capacites

  if value.connaissances?
    value.connaissances = _.uniq(value.connaissances)
  else if value.capacites?
    value.capacites = _.uniq(value.capacites)
  else
    delete refs[key]

# console.log JSON.stringify refs
_.forEach refs, (value, key) ->
  console.log("#{key} : #{value.val}\t #{value.niveau}\t")
  value.capacites?.forEach (val) ->
    console.log("Capacité\t#{val[0]}\t#{val[1]}")
  value.connaissances?.forEach (val) ->
    console.log("Connaissance\t#{val[0]}\t#{val[1]}")
