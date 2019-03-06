_ = require 'lodash'
refCompetences = require './refCompetences'

buildCaptureMiddle = (from, to) ->
  regle = new RegExp("#{from}([\\s\\S]*)#{to}", 'g')
  return regle

getCompetenceSection = (matiere, start) ->
  compSections = [
    "Cet EC relève de l'unité d'enseignement\.\*et contribue aux compétences suivantes : "
    "De plus, elle nécessite de mobiliser les compétences suivantes : "
    "En permettant à \+l'étudiant de travailler et d'être évalué sur les connaissances suivantes : "
    "En permettant à \+l'étudiant de travailler et d'être évalué sur les capacités suivantes : "
    ""
  ]
  startfound = false
  for section in compSections
    unless startfound
      if section is start && matiere.competencesBrutes.match(section)
        startfound = true
    else
      rech = buildCaptureMiddle(start, section).exec(matiere.competencesBrutes)
      if rech?
        return rech
  unless /^HU-|^EPS-|^HUMA-/.test(matiere.code)
    console.error "#{matiere.code} section \"#{start}\" introuvable}."

module.exports = (matiere, DPTINSA) ->

  # Compétences
  lcompetences = getCompetenceSection(matiere, "Cet EC relève de l'unité d'enseignement\.\*et contribue aux compétences suivantes : ")
  # console.log "#{lcompetences[0]}"
  if lcompetences?
    try
      matiere.listeComp = lcompetences[1].trim().split(/ (?=[ABC]\d)/).map (x) ->
        # console.log "->#{x}"
        #TODO: GI avec un . http://planete.insa-lyon.fr/scolpeda/f/ects?id=35856&_lang=fr
        [, compet, niveau] = /([ABC]\d+)[ \.].*\(niveau (.*)\)/i.exec(x)
        if compet.startsWith('C')
          compet = "#{DPTINSA}-#{compet}"

        comp = _.clone(refCompetences[compet])
        unless comp?
          throw Error("*#{x}* est inconnue, recherche sur #{compet}")
        comp.niveau = niveau
        comp
    catch error
      # console.error(lcompetences)
      console.error(error.message)
      # throw error

  # Competences mobilisées
  lcompetences = getCompetenceSection(matiere, "De plus, elle nécessite de mobiliser les compétences suivantes : ")
  if lcompetences?
    try
      matiere.listeCompMobilise = lcompetences[1].trim().match(/[ABC]\d+ /g).map (x) ->
        if x.startsWith('C')
          x = "#{DPTINSA}-#{x}"
        comp = refCompetences[x.trim()]
        unless comp?
          throw Error("-#{x}- est inconnue")
        comp
    catch error
      console.error(lcompetences)
      console.error(error)
      throw error


  matiere.capacite = []
  matiere.connaissance = []
  matiere.competenceToCapaciteEtConnaissance = {}

  injectCapacitesConnaissances = (name, matiere, sectionStartName) ->
    lcapacites = getCompetenceSection(matiere, sectionStartName)
    if lcapacites?
      splitCapacites = lcapacites[1].trim().split(/ *- /)
      splitCapacites.map (capa) ->
        if capa isnt '' and capa.trim().length > 3 # Taille de la chaine à vérifier
          capaDescription = ''
          listComp = ''
          try
            [,capaDescription,listComp] = capa.match(/(.*) \((.*)\)/)
          catch error
            capaDescription = capa

          if name is 'Capacité'
            capaDescription = "Capacité : #{capaDescription.trim()}"
            matiere.capacite.push(capaDescription)
          else
            capaDescription = "Connaissance : #{capaDescription.trim()}"
            matiere.connaissance.push(capaDescription)

          lcomps = listComp.split(', ')
          lcomps.map (comp) ->
            if /[ABC]\d+/.test(comp)
              unless matiere.competenceToCapaciteEtConnaissance[comp]? then matiere.competenceToCapaciteEtConnaissance[comp] = []
              matiere.competenceToCapaciteEtConnaissance[comp].push(capaDescription)

  injectCapacitesConnaissances("Connaissance", matiere, "En permettant à \+l'étudiant de travailler et d'être évalué sur les connaissances suivantes : ")
  injectCapacitesConnaissances("Capacité", matiere, "En permettant à \+l'étudiant de travailler et d'être évalué sur les capacités suivantes : ")

  matiere
