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
  lcompetences = getCompetenceSection(matiere, "Cet EC relève de l'unité d'enseignement\.\*et contribue aux compétences suivantes : ")
  # console.log(lcompetences[1])
  if lcompetences?
    try
      matiere.listeComp = lcompetences[1].trim().split(/ (?=[ABC]\d)/).map (x) ->
        capaciteIdx = x.indexOf('Capacité : ')
        connaissanceIdx = x.indexOf('Connaissance : ')

        if capaciteIdx > 0 and connaissanceIdx > 0
          compName = x.substring(0, capaciteIdx).trim()
          capaName = x.substring(capaciteIdx, connaissanceIdx).trim()
          connName = x.substring(connaissanceIdx).trim()
        else
          if capaciteIdx > 0
            compName = x.substring(0, capaciteIdx).trim()
            capaName = x.substring(capaciteIdx).trim()
          else if connaissanceIdx > 0
            compName = x.substring(0, connaissanceIdx).trim()
            connName = x.substring(connaissanceIdx).trim()
          else
            compName = x.trim()

        # On place la compétence
        [, compet, niveau] = /([ABC]\d) .*\(niveau (.*)\)/i.exec(compName)
        if compet.startsWith('C')
          compet = "#{DPTINSA}-#{compet}"
        comp = _.clone(refCompetences[compet])
        unless comp?
          throw Error("*#{x}* est inconnue, #{compet}")
        comp.niveau = niveau

        addCapaOrConn = (compet, listName, field, motif) ->
          if listName
            unless matiere.competenceToCapaciteEtConnaissance[compet]? then matiere.competenceToCapaciteEtConnaissance[compet] = []
            capaArray = listName.split(new RegExp(" (?=#{motif} : )"))
            matiere[field].push(capaArray...)
            matiere.competenceToCapaciteEtConnaissance[compet].push(capaArray...)

        addCapaOrConn(compet, capaName, "capacite", "Capacité")
        addCapaOrConn(compet, connName, "connaissance", "Connaissance")

        comp

    catch error
      console.error(lcompetences)
      console.error(error)
      throw error
  # Competences mobilisées
  lcompetences = getCompetenceSection(matiere, "De plus, elle nécessite de mobiliser les compétences suivantes : ")
  if lcompetences?
    try
      matiere.listeCompMobilise = lcompetences[1].trim().match(/[ABC]\d /g).map (x) ->
        if x.startsWith('C')
          x = "#{DPTINSA}-#{x}"
        comp = refCompetences[x.trim()]
        unless comp?
          throw Error("#{x} est inconnue")
        comp
    catch error
      console.error(lcompetences)
      console.error(error)
      throw error

  matiere
