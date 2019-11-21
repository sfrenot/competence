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
        unless refComp.capacites?
          refComp.capacites = []
        unless refComp.connaissances?
          refComp.connaissances = []
        list.forEach (elem) ->
          if elem.startsWith('Capacité : ')
            refComp.capacites.push("#{elem.substring('Capacité : '.length)} (#{ec.detail.code})")
          else if elem.startsWith('Connaissance : ')
            refComp.connaissances.push("#{elem.substring('Connaissance : '.length)} (#{ec.detail.code})")
          else
            console.error("Connaissance ou capacité mal exprimée #{elem}")
            process.exit(1)

_.forEach refs, (value, key) ->
  delete refs.valAnglais
  delete refs.bs
  if value.connaissances? or value.capacites?
    value.connaissances = _.uniq(value.connaissances)
    value.capacites = _.uniq(value.capacites)
  else
    delete refs[key]

console.log JSON.stringify refs
