# Lancement du parser tika
# java -jar tika-app-1.17.jar --text -s -p 1234

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
  mainSections = ["PROGRAMME", "BIBLIOGRAPHIE", "PRÉ-REQUIS", "mailto"]
  for section in mainSections
    rech = buildCaptureMiddle("OBJECTIFS RECHERCHÉS PAR CET ENSEIGNEMENT\n", section).exec(pdf)
    if rech?
      return rech[1].trim().replace(/\n/g,' ')
  return null

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
    console.error(error)
    return matiere
    
  lcompetences = /[\s\S]*Compétences visées *:* *([\s\S]*)(Capacités visées|\* Être capable de : )/ig.exec(matiere.competencesBrutes)
  if lcompetences?
    try
      matiere.listeComp = lcompetences[1].match(/E\d : |SPI-\d : |GCU-[A-Z]\d : |SI\d - |R - |SHS-\d : /g).map (x) ->
        comp = refCompetences[x.substring(0, x.length-3)]
        unless comp?
          throw Error("#{x} est inconnue")
        comp
    catch error
      console.error(lcompetences)
      console.error(error)
      throw error

  matiere.capacite = []
  matiere.competenceToCapaciteEtConnaissance = {}
  lcapacites = (/(?:Capacités visées: |\* Être capable de : )([\s\S]*)(Connaissances visées:|\* Connaître *: )/ig.exec(matiere.competencesBrutes))
  if lcapacites?
    splitCapacites = lcapacites[1].split('; ');
    splitCapacites.map (capa) ->
      if capa isnt ''
        [,capaDescription,listComp] = capa.match(/([\s\S]*) *\((?!.*\()([\s\S]*)\)/)

        capaDescription = "Capacité : #{capaDescription.trim()}"
        matiere.capacite.push(capaDescription)
        lcomps = listComp.split(', ')
        lcomps.map (comp) ->
          unless matiere.competenceToCapaciteEtConnaissance[comp]? then matiere.competenceToCapaciteEtConnaissance[comp] = []
          matiere.competenceToCapaciteEtConnaissance[comp].push(capaDescription)

  matiere.connaissance = []
  lconnaissance = (/(?:\* Connaître *: )([\s\S]*)/ig.exec(matiere.competencesBrutes))
  if lconnaissance?
    splitConnaissance = lconnaissance[1].split(' ; ');
    splitConnaissance.map (capa) ->
      [,capaDescription,listComp] = capa.match(/(.*) \((.*)\)/)
      capaDescription = "Connaissance : #{capaDescription.trim()}"
      matiere.connaissance.push(capaDescription)
      lcomps = listComp.split(', ')
      lcomps.map (comp) ->
        if comp is 'GCU- P2'
          console.error("GCU -P2 a corriger")
          comp = 'GCU-P2'
        unless matiere.competenceToCapaciteEtConnaissance[comp]? then matiere.competenceToCapaciteEtConnaissance[comp] = []
        matiere.competenceToCapaciteEtConnaissance[comp].push(capaDescription)

  # console.warn "-->", matiere
  matiere

# tika=spawn('java', ['-jar', 'tika-app-1.17.jar', '--text', '-s', '-p', '1234'])

catalogue = []
request()
.then (body) ->
  $ = cheerio.load(body)
  $('.diplome').each () ->
    departement = $(@).attr('id')
    if departement is 'GCU'
      semestres = []
      $('.contenu table tr td a', @).each () ->
        #TC if $(@).attr('href') is '/fr/formation/parcours/729/4/1'
        # if $(@).attr('href') is '/fr/formation/parcours/719/3/1' #GCU
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
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36412&_lang=fr' or
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
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36418&_lang=fr'
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
