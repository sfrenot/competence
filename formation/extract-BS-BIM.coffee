_ = require 'lodash'
refCompetences = require './refCompetences'

buildCaptureMiddle = (from, to) ->
  regle = new RegExp("#{from}([\\s\\S]*)#{to}", 'g')
  return regle

getCompetenceSection = (matiere, start) ->
  compSections = [
    "Cet EC contribue aux compétences ci-dessous \\(niveau\\) avec les capacités associées : "
    "Les connaissances associées à \.\* :"
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
  lcompetences = getCompetenceSection(matiere, "Cet EC contribue aux compétences ci-dessous \\(niveau\\) avec les capacités associées : ")

  if lcompetences?
    try
      matiere.listeComp = lcompetences[1].trim().split(/ (?=[ABC]\d+)/).map (x) ->
        # console.log '--> *', x
        description = x.split(/ - ?/)
        if (description[0] is 'A6') ## TODO BIM : A6 - est compliqué
          description.shift()
          description[0] = "A6. #{description[0]}"
        #
        # console.log '-->', description
        # On place la compétence
        try
          tmp = description.shift()
          [, compet, niveau] = /([ABC]\d+).*\((.*)\)/.exec(tmp)
          if compet.startsWith('C')
            compet = "#{DPTINSA}-#{compet}"
          comp = _.clone(refCompetences[compet])

          unless comp?
            throw Error("* Competence INCONNUE #{x}*, #{compet}")
          if niveau.startsWith('niveau')
            comp.niveau = niveau.replace(/niveau/,'').trim()
          else
            comp.niveau = 'M'
        catch error
          console.error "Erreur sur la matière #{matiere.code}, #{error}, #{tmp}"

        addCapaOrConn = (compet, listName, field, motif) ->
          if listName
            unless matiere.competenceToCapaciteEtConnaissance[compet]? then matiere.competenceToCapaciteEtConnaissance[compet] = []
            capaArray = listName.split(new RegExp(" (?=#{motif} : )"))
            matiere[field].push(capaArray...)
            matiere.competenceToCapaciteEtConnaissance[compet].push(capaArray...)

        description.forEach (desc) ->
          addCapaOrConn(compet, desc, "capacite", "Capacité")

        comp

    catch error
      console.error(lcompetences)
      console.error(error)
      throw error

  if matiere.listeComp
    # console.log "->", matiere.listeComp
    matiere.listeCompMobilise = matiere.listeComp.filter((x) -> x?.niveau is 'mobilise')
    matiere.listeComp = matiere.listeComp.filter((x) -> x?.niveau isnt 'mobilise')
    # console.log "-->", matiere.listeCompMobilise

  if _.isEmpty(matiere.listeCompMobilise)
    delete matiere.listeCompMobilise

  # BIM TODO Compétences mobilisé --> Connaissance
  try
    matiere.connaissances = getCompetenceSection(matiere, "Les connaissances associées à \.\* :")[1].trim()
  catch
    # try
    #   getCompetenceSection(matiere, "Les connaissances associées à ce cours sont :")[1]
    # catch
    # unless /^HU-|^EPS-/.test(matiere.code)
    #   console.error "Erreur sur la connaissance #{matiere.code}"

  matiere
