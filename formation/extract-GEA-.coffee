_ = require 'lodash'
refCompetences = require './refCompetences'

buildCaptureMiddle = (from, to) ->
  regle = new RegExp("#{from}([\\s\\S]*)#{to}", 'g')
  return regle

getCompetenceSection = (matiere, start) ->
  compSections = [
    "Cet EC relève de l'unité d'enseignement\.\*et contribue aux compétences suivantes : "
    "De plus, elle nécessite de mobiliser les compétences suivantes : "
    "En permettant à l'étudiant de travailler et d'être évalué sur les connaissances suivantes : "
    "En permettant à l'étudiant de travailler et d'être évalué sur les capacités suivantes : "
    "http://"
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
  lcompetences = getCompetenceSection(matiere, "Cet EC relève de l'unité d'enseignement\.\*et contribue aux compétences suivantes : ")

  if lcompetences?
    try
      matiere.listeComp = lcompetences[1].trim().split(/ - /).map (x) ->

        if x.startsWith('- ') then x = x.substring('- '.length)
        end = x.indexOf('--- ')
        compName = x.substring(0, end)
        val = x.substring(end+'--- '.length)
        val = val.replace(/-- Sous compétence.*? ---/g, '---')

        try
          [, compet, niveau] = /(.*)\(niveau (.*)\)/.exec(compName)
        catch
          console.error "Pas de niveau pour #{matiere.code}"
          [, compet] = /(.*)/.exec(compName)
          niveau = 1

        # TODO : GE ¿ -->
        corres = _.find refCompetences, {"val": compet.replace(/¿/g,'\'').replace(/^-+/g, '').trim()}
        unless corres?
          # console.error  "Inconnue --'#{compet.replace('¿','\'').trim()}', pour #{matiere.code}--"
          throw Error()
          # process.exit()
        comp = _.clone(corres)
        comp.niveau = niveau

        if comp.code.startsWith('C')
          compet = "#{DPTINSA}-#{comp.code}"
        else
          compet = comp.code

        addCapaOrConn = (compet, listName, field, motif) ->
          if listName
            unless matiere.competenceToCapaciteEtConnaissance[compet]? then matiere.competenceToCapaciteEtConnaissance[compet] = []
            capaArray = listName.split(new RegExp("#{motif}"))
            capaArray.forEach (elem) ->
              elem = elem.replace(/¿/g,'\'').trim()
              if elem.startsWith('Capacité : ')
                matiere['capacite'].push(elem)
              else if elem.startsWith('Connaissance : ')
                matiere['connaissance'].push(elem)
              else
                console.error "Ce n'est pas une capacité ou connaissance #{elem}"
              matiere.competenceToCapaciteEtConnaissance[compet].push(elem)

        addCapaOrConn(compet, val, null, " --- ")

        comp

    catch error
      # console.error(lcompetences)
      # console.error(error)
      # throw error

  # Competences mobilisées
  lcompetences = getCompetenceSection(matiere, "De plus, elle nécessite de mobiliser les compétences suivantes : ")
  if lcompetences?
    # console.error("->", lcompetences[1])
    matiere.listeCompMobilise = []
    try
      lcompetences[1].trim().split(/ -- | - /).forEach (x) ->
        compet = x.replace(/^-+/, '').replace(/\./g, '').trim()
        # console.log '->', compet
        # process.exit()
        unless _.isEmpty(compet)
          corres = _.find refCompetences, {"val": compet.replace('¿','\'').trim()}
          unless corres?
            console.error("Section : Compétence Mobilisées : #{matiere.code} Erreur : compétence *#{x}* est inconnue.")
          else
            matiere.listeCompMobilise.push(compet)
    catch error
      console.error(lcompetences)
      console.error(error)
      throw error

    matiere.listeCompMobilise = matiere.listeCompMobilise.filter((x) -> x)

  matiere
