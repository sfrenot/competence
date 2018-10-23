# Lancement du parser tika
# java -jar tika-app-1.17.jar --text -s -p 1234
# TODO : fonction de liste de section
# Extraire la section parmis cette liste

Promise = require 'bluebird'
cheerio = require 'cheerio'
request = require('request-promise').defaults
  url: 'https://www.insa-lyon.fr/fr/formation/diplomes/ING'
_ = require 'lodash'
skilvioo = require './skilvioo/skilvioo'
refCompetences = require './refCompetences'
{spawn}  = require 'child_process'

DPTINSA = 'GEN'

extractRe = (re, src) ->
  return re.exec(src)[0].split(' : ')[1]

buildCaptureMiddle = (from, to) ->
  regle = new RegExp("#{from}([\\s\\S]*)#{to}", 'g')
  return regle

getCompetenceBruteSection = (pdf) ->
  mainSections = ["OBJECTIFS", "PROGRAMME", "BIBLIOGRAPHIE", "PRÉ-REQUIS", "\n\nmailto"]
  for section in mainSections
    rech = buildCaptureMiddle("OBJECTIFS RECHERCHÉS PAR CET ENSEIGNEMENT\n", section).exec(pdf)
    if rech?
      return rech[1].trim().replace(/\n/g,' ')
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

  # Compétences
  lcompetences = getCompetenceSection(matiere, "Cet EC relève de l'unité d'enseignement\.\*et contribue aux compétences suivantes : ")
  # console.log(lcompetences[1])
  if lcompetences?
    try
      matiere.listeComp = lcompetences[1].trim().split(/ (?=[ABC]\d)/).map (x) ->
        [, compet, niveau] = /([ABC]\d) .*\(niveau (.*)\)/i.exec(x)
        if compet.startsWith('C')
          compet = "#{DPTINSA}-#{compet}"

        comp = _.clone(refCompetences[compet])
        unless comp?
          throw Error("*#{x}* est inconnue, recherche sur #{compet}")
        comp.niveau = niveau
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
            if _.isNumber(comp)
              unless matiere.competenceToCapaciteEtConnaissance[comp]? then matiere.competenceToCapaciteEtConnaissance[comp] = []
              matiere.competenceToCapaciteEtConnaissance[comp].push(capaDescription)

  injectCapacitesConnaissances("Connaissance", matiere, "En permettant à l'étudiant de travailler et d'être évalué sur les connaissances suivantes : ")
  injectCapacitesConnaissances("Capacité", matiere, "En permettant à l'étudiant de travailler et d'être évalué sur les capacités suivantes : ")

  # console.warn "-->", matiere
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
        # if $(@).attr('href') is '/fr/formation/parcours/729/4/2'
        # if $(@).attr('href') is '/fr/formation/parcours/719/3/1' #GCU
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
            # GCU
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36069&_lang=fr'
            # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36410&_lang=fr' or
            # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36410&_lang=fr' or
            # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36407&_lang=fr' or
            # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36411&_lang=fr'

            #  if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36412&_lang=fr' or
            #  $('a', @).attr('href') is "http://planete.insa-lyon.fr/scolpeda/f/ects?id=36417&_lang=fr" or
            #  $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36424&_lang=fr' or
            #  $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36424&_lang=fr' or
            #  $('a', @).attr('href') is "http://planete.insa-lyon.fr/scolpeda/f/ects?id=36418&_lang=fr" or
            #  $('a', @).attr('href') is "http://planete.insa-lyon.fr/scolpeda/f/ects?id=36419&_lang=fr" or
            #  $('a', @).attr('href') is "http://planete.insa-lyon.fr/scolpeda/f/ects?id=35883&_lang=fr"
            # # TC
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=35786&_lang=fr'
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36424&_lang=fr'
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36408&_lang=fr'
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36036&_lang=fr'
            # # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36040&_lang=fr' or
            # # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=34969&_lang=fr' or
            # # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36060&_lang=fr' or
            # # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=34873&_lang=fr'
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
