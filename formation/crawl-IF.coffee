# Lancement du parser tika
# java -jar tika-app-1.17.jar --text -s -p 1234
# TODO : fonction de liste de section
# Extraire la section parmis cette liste
DPTINSA = 'IF'

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
      return rech[1].trim().replace(/\n/g,' ')
  return null

getCompetenceSection = (matiere, start) ->
  compSections = [
    "Cet EC relève de l'unité d'enseignement\.\*et contribue aux : "
    "En mobilisant les compétences suivantes"
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
  # console.log '->', pdf
  # Suppression de l'addresse et du numéro de page sous toutes les pages
  pdf = pdf.replace(/mailto:[\s\S]*Dernière modification le : [^\n]+/g,'')
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

  matiere.capacite = []
  matiere.connaissance = []
  matiere.competenceToCapaciteEtConnaissance = {}
  # Compétences
  lcompetences = getCompetenceSection(matiere, "Cet EC relève de l'unité d'enseignement\.\*et contribue aux : ")
  # console.log(lcompetences[1])
  if lcompetences?
    try
      matiere.listeComp = lcompetences[1].trim().split(/ (?=[ABC]\d+- )/).map (x) ->

        if /[ABC]\d+-/.test(x)
          # console.log "**#{x}**"
          capaciteIdx = x.indexOf(' Capacités : ')
          connaissanceIdx = x.indexOf(' Connaissances : ')

          # console.log "CapaciteIdx #{capaciteIdx}, ConnaissanceIdx #{connaissanceIdx}"

          if capaciteIdx > 0 and connaissanceIdx > 0
            compName = x.substring(0, capaciteIdx).trim()
            capaName = x.substring(capaciteIdx + ' Capacités : - '.length, connaissanceIdx).trim()
            connName = x.substring(connaissanceIdx + ' Connaissances : - '.length).trim()
          else
            if capaciteIdx > 0 # Il n'y a que des capacites
              compName = x.substring(0, capaciteIdx).trim()
              capaName = x.substring(capaciteIdx + ' Capacités : - '.length).trim()
            else if connaissanceIdx > 0 # Il n'y a que des competences
              compName = x.substring(0, connaissanceIdx).trim()
              connName = x.substring(connaissanceIdx + ' Connaissances : - '.length).trim()
            else
              compName = x.trim()

          # console.log "Capacite #{capaName}"
          # console.log "Connaissances #{connName}"
          # On place la compétence
          # TODO: IF n'a pas de niveaux pour l'instant
          # [, compet, niveau] = /([ABC]\d+)- .*\(niveau (.*)\)/i.exec(compName)
          [, compet] = /([ABC]\d+)- .*/i.exec(compName)
          if compet.startsWith('C')
            compet = "#{DPTINSA}-#{compet}"
          comp = _.clone(refCompetences[compet])
          unless comp?
            throw Error("*#{x}* est inconnue, #{compet}")
          # Le niveau est en dur
          comp.niveau = 3

          addCapaOrConn = (compet, listName, field) ->
            if listName
              unless matiere.competenceToCapaciteEtConnaissance[compet]? then matiere.competenceToCapaciteEtConnaissance[compet] = []
              capaArray = listName.split(/ - /)
              capaArray = capaArray.map ((x) -> "#{field} : #{x}" )
              matiere[field].push(capaArray...)
              matiere.competenceToCapaciteEtConnaissance[compet].push(capaArray...)

          addCapaOrConn(comp.code, capaName, "capacite")
          addCapaOrConn(comp.code, connName, "connaissance")

        comp

    catch error
      console.error(lcompetences)
      console.error(error)
      throw error
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
        if $(@).attr('href') is '/fr/formation/parcours/726/4/2'
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
            if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=35056&_lang=fr'
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