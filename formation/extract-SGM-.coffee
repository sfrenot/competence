_ = require 'lodash'
refCompetences = require './refCompetences'

buildCaptureMiddle = (from, to) ->
  regle = new RegExp("#{from}([\\s\\S]*)#{to}", 'g')
  return regle

getCompetenceSection = (matiere, start) ->
  compSections = [
    "Cet \.\*\? relève de \.\*\? et contribue aux : "
    "\[E\|3\]n \{0,2\}mobilisant les compétences\? suivantes\? :\{0,1\}"
    "\[E\|e\]n permettant à l'étudiant de travailler et d\['\|¿\]être évalué sur les connaissances \.\*\? :"
    "\[E\|e\]n permettant à l'étudiant de travailler et d'être évalué sur les capacités\{0,1\} suivantes :"
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
    console.error "#{matiere.code} section \"#{start}\" introuvable."

module.exports = (matiere, DPTINSA) ->

  # Compétences
  lcompetences = getCompetenceSection(matiere, "Cet \.\*\? relève de \.\*\? et contribue aux : ")
  # console.log(lcompetences[1])
  # process.exit()
  if lcompetences?
    try
      matiere.listeComp = lcompetences[1].trim().split(/ (?=[ABC]\d+ )/).map (x) ->
        if /[ABC]\d+ /.test(x)
          # console.log "**#{x}**"
          try
            [, compet, tmp, niveau] = /([ABC]\d)( -? .*)\(Niveau ?(.*)\)/i.exec(x)
            # if niveau.endsWith(')') then niveau = niveau.substring(0, niveau.length()-1 )
            if compet.startsWith('C')
              compet = "#{DPTINSA}-#{compet}"

            comp = _.clone(refCompetences[compet])
            unless comp?
              throw Error("*#{x}* est inconnue, recherche sur #{compet}")
            comp.niveau = niveau
            comp
          catch error
            console.error("ERREUR : Impossible d'extraire Compétence ou niveau pour ----> #{x}")
            console.error("#{JSON.stringify matiere, null, 2}")
    catch error
      console.error(lcompetences)
      console.error(error)
      throw error
  if matiere.listeComp
    matiere.listeComp = matiere.listeComp.filter((x) -> x)

  # Competences mobilisées
  lcompetences = getCompetenceSection(matiere, "[E\|3\]n \{0,2\}mobilisant les compétences\? suivantes\? :\{0,1\}")
  if lcompetences?
    try
      matiere.listeCompMobilise = lcompetences[1].trim().match(/[ABC]\d+/g).map (x) ->
        # console.log "-#{x}-"
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
  if matiere.listeCompMobilise
    matiere.listeCompMobilise = matiere.listeCompMobilise.filter((x) -> x)


  matiere.capacite = []
  matiere.connaissance = []
  matiere.competenceToCapaciteEtConnaissance = {}

  injectCapacitesConnaissances = (name, matiere, sectionStartName) ->
    lcapacites = getCompetenceSection(matiere, sectionStartName)

    if lcapacites?
      splitCapacites = lcapacites[1].trim().split(/ *- /)
      splitCapacites.map (capa) ->
        if capa isnt '' and capa.trim().length > 3 # Taille de la chaine à vérifier
          # capaDescription = ''
          # listComp = ''
          # try
          #   # [,capaDescription,listComp] = capa.match(/(.*) \((.*)\)/)
          # catch error
          #   capaDescription = capa

          capaDescription = capa # Hach for SGM
          if name is 'Capacité'
            capaDescription = "Capacité : #{capaDescription.trim()}"
            matiere.capacite.push(capaDescription)
          else
            capaDescription = "Connaissance : #{capaDescription.trim()}"
            matiere.connaissance.push(capaDescription)

          # lcomps = listComp.split(', ')
          # lcomps.map (comp) ->
          #   if _.isNumber(comp)
          #     unless matiere.competenceToCapaciteEtConnaissance[comp]? then matiere.competenceToCapaciteEtConnaissance[comp] = []
          #     matiere.competenceToCapaciteEtConnaissance[comp].push(capaDescription)

  injectCapacitesConnaissances("Connaissance", matiere, "\[E\|e\]n permettant à l'étudiant de travailler et d\['\|¿\]être évalué sur les connaissances \.\*\? :")
  injectCapacitesConnaissances("Capacité", matiere, "\[E\|e\]n permettant à l'étudiant de travailler et d'être évalué sur les capacités\{0,1\} suivantes :")

  # console.warn "-->", matiere
  matiere
