_ = require 'lodash'
unless process.argv[2]?
  console.log "Lancement : coffee ./invert.coffee <catalogue.json>"
  process.exit(0)

courses = require process.argv[2]
refs = require "../refCompetences.coffee"

domaines = ['Syscom', 'Réseaux', 'Info', 'Huma', 'Projet']
mapDomaines =
  'T': 'Syscom'
  'R': 'Réseaux'
  'I': 'Info'
  'H': 'Huma'
  'L': 'Huma'
  'PPH': 'Huma'
  'P': 'Projet'

matieres = []

extractMat = (ec) ->
  # console.log '->', JSON.stringify ec.code, null, 2
  domaine = ec.code.split(/[.*\d|HU|HUMA]-/)[1].substring(0,1)

  return
    'code': ec.code
    'nom': ec.nom
    'domaine': mapDomaines[domaine]

liste = []
courses.forEach (departement) ->
  departement.semestres.forEach (semestre) ->
    semestre.ecs.forEach (ec) ->
      matieres.push(extractMat(ec.detail))
      _.forEach ec.detail.competenceToCapaciteEtConnaissance, (list, competence) ->
        refComp = refs[competence]
        unless refComp
          console.error("Compétence introuvable #{competence}")
          process.exit(1)
        unless refComp.niveau?
          refComp.niveau = 0
        refComp.liste = []
        list.forEach (elem) ->
          if elem.startsWith('Capacité : ')
            liste.push
              'nom': elem.substring('Capacité : '.length)
              'matiere': ec.detail.code
              'type': 'Capacité'
          else if elem.startsWith('Connaissance : ')
            liste.push
              'nom': elem.substring('Connaissance : '.length)
              'matiere': ec.detail.code
              'type': 'Connaissance'
          else
            console.error("Connaissance ou capacité mal exprimée #{elem}")
            process.exit(1)

res =
  domaines: domaines
  matieres: matieres
  liste: liste

console.log JSON.stringify res, null, 2

# _.forEach refs, (value, key) ->
#   console.log("#{key} : #{value.val}\t #{value.niveau}\t")
#   value.capacites?.forEach (val) ->
#     console.log("Capacité\t#{val[0]}\t#{val[1]}")
#   value.connaissances?.forEach (val) ->
#     console.log("Connaissance\t#{val[0]}\t#{val[1]}")
