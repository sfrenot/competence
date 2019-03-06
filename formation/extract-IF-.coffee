_ = require 'lodash'
refCompetences = require './refCompetences'

buildCaptureMiddle = (from, to) ->
  regle = new RegExp("#{from}([\\s\\S]*)#{to}", 'g')
  return regle

getCompetenceSection = (matiere, start) ->
  compSections = [
    "Cet EC contribue aux : "
    "En mobilisant les compétences suivantes"
    "http://if.insa-lyon.fr"
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
  lcompetences = getCompetenceSection(matiere, "Cet EC contribue aux : ")

  if lcompetences?
    try
      matiere.listeComp = lcompetences[1].trim().split(/ == (?=[ABC]\d+ )/).map (x) ->
        # console.log '->', x
        if /[ABC]\d+/.test(x)
          # console.log "**#{x}**"
          capaciteIdx = x.indexOf('* Capacités : ')
          connaissanceIdx = x.indexOf('* Connaissances : ')

          # console.log "CapaciteIdx #{capaciteIdx}, ConnaissanceIdx #{connaissanceIdx}"

          if capaciteIdx > 0 and connaissanceIdx > 0
            compName = x.substring(0, capaciteIdx).trim()
            capaName = x.substring(capaciteIdx + '* Capacités : - '.length, connaissanceIdx).trim()
            connName = x.substring(connaissanceIdx + '* Connaissances : - '.length).trim()
          else
            if capaciteIdx > 0 # Il n'y a que des capacites
              compName = x.substring(0, capaciteIdx).trim()
              capaName = x.substring(capaciteIdx + '* Capacités : - '.length).trim()
            else if connaissanceIdx > 0 # Il n'y a que des competences
              compName = x.substring(0, connaissanceIdx).trim()
              connName = x.substring(connaissanceIdx + '* Connaissances : - '.length).trim()
            else
              compName = x.trim()

          try
            [, compet, niveau] = /([ABC]\d+) .*\(niveau (.*)\) ==/i.exec(compName)
            if compet.startsWith('C')
              compet = "#{DPTINSA}-#{compet}"
            comp = _.clone(refCompetences[compet])
            unless comp?
              throw Error("*#{compName}* est inconnue, #{compet}")
            comp.niveau = niveau

            addCapaOrConn = (compet, listName, field) ->
              if listName
                unless matiere.competenceToCapaciteEtConnaissance[compet]? then matiere.competenceToCapaciteEtConnaissance[compet] = []
                capaArray = listName.split(/ - /)
                capaArray = capaArray.map ((x) -> "#{field} : #{x}" )
                matiere[field].push(capaArray...)
                matiere.competenceToCapaciteEtConnaissance[compet].push(capaArray...)

            addCapaOrConn(comp.code, capaName, "capacite")
            addCapaOrConn(comp.code, connName, "connaissance")

          catch error
            console.error("#{matiere.code}, *#{compName}*, #{error}")
            process.exit()
        comp

    catch error
      console.error(lcompetences)
      console.error(error)
      throw error
  if matiere.listeComp
    matiere.listeComp = matiere.listeComp.filter((x) -> x)

  # Competences mobilisées
  lcompetences = getCompetenceSection(matiere, "En mobilisant les compétences suivantes")

  if lcompetences?
    try
      matiere.listeCompMobilise = lcompetences[1].trim().match(/ [ABC]\d+/g).map (x) ->
        # console.log "**#{x}**"
        x = x.trim()
        if x.startsWith('C')
          x = "#{DPTINSA}-#{x}"
        comp = refCompetences[x]
        unless comp?
          throw Error("#{x} est inconnue")
        comp
    catch error
      console.error(lcompetences)
      console.error(error)
      throw error

  matiere
