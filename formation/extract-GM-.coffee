_ = require 'lodash'
refCompetences = require './refCompetences'

buildCaptureMiddle = (from, to) ->
  regle = new RegExp("#{from}([\\s\\S]*)#{to}", 'g')
  return regle

getCompetenceSection = (matiere, start) ->
  compSections = [
    "Compétences écoles en sciences pour l'ingénieur : "
    "Compétences écoles en humanité, documentation et éducation physique et sportive : "
    "Compétences écoles spécifiques à la spécialité : "
    "En mobilisant les compétences suivantes : "
    "En permettant à l'étudiant de travailler et d'être évalué sur les connaissances suivantes *: "
    "En permettant à l'étudiant de travailler et d'être évalué sur les capacités suivantes *: "
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

  insertCompetence = (typeCompetence) ->
    # Compétences
    lcompetences = getCompetenceSection(matiere, typeCompetence)
    # console.log(lcompetences[1])
    # process.exit()
    if lcompetences?
      try
        matiere.listeComp.push lcompetences[1].trim().split(/ (?=[ABC]\d+-)/).map (x) ->
          # console.log "**#{x}**"
          #TODO: GM niveau null pour http://planete.insa-lyon.fr/scolpeda/f/ects?id=36372&_lang=fr
          [, compet, niveau] = /([ABC]\d+)- .*\(niveau (\d?)\)/i.exec(x)
          if compet.startsWith('C')
            compet = "#{DPTINSA}-#{compet}"

          comp = _.clone(refCompetences[compet])
          unless comp?
            throw Error(" *#{x}* EST INCONNUE SUR #{compet}")
          # console.error "* #{niveau} *"
          comp.niveau = niveau
          comp
      catch error
        console.error(lcompetences)
        console.error(error)
        throw error

  matiere.listeComp = []
  insertCompetence("Compétences écoles en sciences pour l'ingénieur : ")
  insertCompetence("Compétences écoles en humanité, documentation et éducation physique et sportive : ")
  insertCompetence("Compétences écoles spécifiques à la spécialité : ")
  matiere.listeComp = _.flatten matiere.listeComp

  # Competences mobilisées
  lcompetences = getCompetenceSection(matiere, "En mobilisant les compétences suivantes : ")
  if lcompetences?
    try
      matiere.listeCompMobilise = lcompetences[1].trim().match(/[ABC]\d+/g).map (x) ->
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
      splitCapacites = lcapacites[1].trim().split(/ - /)
      splitCapacites.map (capa) ->
        if capa isnt '' and capa.trim().length > 3 # Taille de la chaine à vérifier
          capaDescription = ''
          listComp = ''
          # GM N'utilise pas de niveau
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

  injectCapacitesConnaissances("Connaissance", matiere, "En permettant à l'étudiant de travailler et d'être évalué sur les connaissances suivantes *: ")
  injectCapacitesConnaissances("Capacité", matiere, "En permettant à l'étudiant de travailler et d'être évalué sur les capacités suivantes *: ")

  # console.warn "-->", matiere
  matiere
