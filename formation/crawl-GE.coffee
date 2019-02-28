# Lancement du parser tika
# java -jar tika-app-1.17.jar --text -s -p 1234
# TODO : fonction de liste de section
# Extraire la section parmis cette liste
DPTINSA = 'GE'

Promise = require 'bluebird'
cheerio = require 'cheerio'
request = require('request-promise').defaults
  url: 'https://www.insa-lyon.fr/fr/formation/diplomes/ING'
_ = require 'lodash'
skilvioo = require './skilvioo/skilvioo'
refCompetences = require './refCompetences'
{spawn}  = require 'child_process'

extractRe = (re, src) ->
  return re.exec(src)[0].split(' : ')[1]

buildCaptureMiddle = (from, to) ->
  regle = new RegExp("#{from}([\\s\\S]*)#{to}", 'g')
  return regle

getCompetenceBruteSection = (pdf) ->
  mainSections = ["PROGRAMME", "BIBLIOGRAPHIE", "PRÉ-REQUIS", "\n\nmailto"]
  for section in mainSections
    rech = buildCaptureMiddle("OBJECTIFS RECHERCHÉS PAR CET ENSEIGNEMENT\n", section).exec(pdf)
    if rech?
      solution = rech[1].trim()
      solution = solution.replace(/mailto:[^\n]*\n/g, '')
      solution = solution.replace(/http:\/\/www\.insa-lyon\.fr[\s\S]*?Dernière modification le : [^\n]*\n/g, '')
      return solution.replace(/\n/g,' ')
  return null

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
  console.error "#{matiere.code} section \"#{start}\" introuvable}."

extractPdfStructure = (pdf) ->

  matiere = {}
  # console.warn "-->", pdf
  # console.warn "Recherche mat"
  matiere.code = extractRe(/CODE : .*/, pdf)
  matiere.ects = extractRe(/ECTS : .*/, pdf)
  matiere.cours = extractRe(/Cours : .*/, pdf)
  matiere.td = extractRe(/TD : .*/, pdf)
  matiere.tp = extractRe(/TP : .*/, pdf)
  matiere.projet = extractRe(/Projet : .*/, pdf)
  matiere.perso = extractRe(/Travail personnel : .*/, pdf)
  try
    [..., avant, dernier, blanc, blanc] = buildCaptureMiddle("CONTACT\n","OBJECTIFS RECHERCHÉS PAR CET ENSEIGNEMENT").exec(pdf)[1].split('\n')
    matiere.nom = "#{avant} : #{dernier}"
    matiere.competencesBrutes = getCompetenceBruteSection(pdf)
  catch error
    console.error("Warning matiere mal saisie #{matiere.code}")
    # console.error(error)
    return matiere

  unless matiere.competencesBrutes
    console.error("Erreur d'analyse #{matiere.code}")
    # console.error(error)
    return matiere

  matiere.capacite = []
  matiere.connaissance = []
  matiere.competenceToCapaciteEtConnaissance = {}
  # Compétences
  lcompetences = getCompetenceSection(matiere, "Cet EC relève de l'unité d'enseignement\.\*et contribue aux compétences suivantes : ")

  if lcompetences?
    try
      matiere.listeComp = lcompetences[1].trim().split(/ - /).map (x) ->

        if x.startsWith('- ') then x = x.substring('- '.length)
        end = x.indexOf('--- ')
        compName = x.substring(0, end)
        val = x.substring(end+'--- '.length)

        try
          [, compet, niveau] = /(.*)\(niveau (.*)\)/.exec(compName)
        catch
          console.error "Pas de niveau pour #{matiere.code}"
          [, compet] = /(.*)/.exec(compName)
          niveau = 1

        # TODO : GE ¿ -->
        corres = _.find refCompetences, {"val": compet.replace(/¿/g,'\'').trim()}
        unless corres?
          console.error  "Inconnue --'#{compet.replace('¿','\'').trim()}', pour #{matiere.code}--"
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
              if elem.startsWith('Capacité : ')
                matiere['capacite'].push(elem.replace(/¿/g,'\''))
              else if elem.startsWith('Connaissance : ')
                matiere['connaissance'].push(elem.replace(/¿/g,'\''))
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
    try
      matiere.listeCompMobilise = lcompetences[1].trim().match(/-- (.*?)\./g).map (x) ->
        [, , compet, ] = /(--)(.*)(\.)/.exec(x)
        # console.log '=>', compet
        corres = _.find refCompetences, {"val": compet.replace('¿','\'').trim()}
        unless corres?
          throw Error("*#{x}* est inconnue, #{compet}")
        corres

    catch error
      console.error(lcompetences)
      console.error(error)
      throw error

  matiere

# tika=spawn('java', ['-jar', 'tika-app-1.17.jar', '--text', '-s', '-p', '1234'])

catalogue = []
request()
.then (body) ->
  $ = cheerio.load(body)
  $('.diplome').each () ->
    departement = $(@).attr('id')
    if departement is DPTINSA
      semestres = []
      $('.contenu table tr td a', @).each () ->
        # if $(@).attr('href') is '/fr/formation/parcours/720/5/1'
          if $(@).text().trim() is 'Parcours Standard'
            semestres.push
              url: $(@).attr('href')
              ecs: []
      catalogue.push
        'departement': departement
        'semestres': semestres

  # console.warn "#{JSON.stringify catalogue, null, 2}"
  Promise.each catalogue, (departement) ->
    Promise.each departement.semestres, (semestre) ->
      request
        url:'https://www.insa-lyon.fr'+semestre.url
        method: 'GET'
      .then (body) ->
        urls = []
        $ = cheerio.load(body)
        currentUE = null
        $('.contenu-onglet .detail-parcours-table tr').each () ->
          if $('.thlike', @).get().length is 1
            currentUE = /Unité d'enseignement : (.*)/.exec($('.thlike', @).get(0).children[0].data)[1]
          else if $('a', @).get().length is 1
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=34615&_lang=fr'
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=35329&_lang=fr'
              urls.push
                UE: currentUE
                url: $('a', @).attr('href')

        Promise.each urls, (url) ->
          console.warn '-->', url.url # A laisser pour la progession du code
          new Promise (resolve) ->
            res=''
            curl = spawn('curl', [url.url])
            tika = spawn('nc', ['localhost', 1234])
            curl.stdout.on 'data', (chunk) ->
              tika.stdin.write(chunk)
            curl.on 'close', (code) ->
              tika.stdin.end()
            tika.stdout.on 'data', (data) ->
              res += data
            tika.on 'close', (code) ->
              resolve(res)
          .then (pdf) ->
            semestre.ecs.push
              UE: url.UE
              url: url.url
              detail: extractPdfStructure(pdf)
.then () ->
  console.log "#{JSON.stringify catalogue, null, 2}"
  # skilvioo.insert(catalogue)

.then () ->
  # console.warn "#{JSON.stringify catalogue, null, 2}"
  console.warn "fin"
.catch (err) ->
  console.warn 'ERR', err
.finally () ->
  # spawn("sh", ["-c", "killall java"])
  console.warn "Fin"
