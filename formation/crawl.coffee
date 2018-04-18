Promise = require 'bluebird'
cheerio = require 'cheerio'
request = require('request-promise').defaults
  url: 'https://www.insa-lyon.fr/fr/formation/diplomes/ING'
_ = require 'lodash'
skilvioo = require './skilvioo'

{spawn}  = require 'child_process'

extractRe = (re, src) ->
  return re.exec(src)[0].split(' : ')[1]

extractPdfStructure = (pdf) ->
  matiere = {}
  # console.log "-->", pdf
  # console.log "Recherche mat"
  matiere.code = extractRe(/CODE : .*/, pdf)
  matiere.ects = extractRe(/ECTS : .*/, pdf)
  matiere.cours = extractRe(/Cours : .*/, pdf)
  matiere.td = extractRe(/TD : .*/, pdf)
  matiere.tp = extractRe(/TP : .*/, pdf)
  matiere.perso = extractRe(/Travail personnel : .*/, pdf)

  matiere.competences = /OBJECTIFS RECHERCHÉS PAR CET ENSEIGNEMENT\n([\s\S]*)PROGRAMME/g.exec(pdf)[1]

  # console.log "-->", matiere
  matiere



catalogue = []
request()
.then (body) ->
  $ = cheerio.load(body)
  $('.diplome').each () ->
    departement = $(@).attr('id')
    if departement is 'TC'
      semestres = []
      $('.contenu table tr td a', @).each () ->
        if $(@).attr('href') is '/fr/formation/parcours/729/4/1'
          semestres.push
            url: $(@).attr('href')
            ecs: []
      catalogue.push
        'departement': departement
        'semestres': semestres

  # console.log "#{JSON.stringify catalogue, null, 2}"
  Promise.map catalogue, (departement) ->
    Promise.map departement.semestres, (semestre) ->
      request
        url:'https://www.insa-lyon.fr'+semestre.url
        method: 'GET'
      .then (body) ->
        urls = []
        $ = cheerio.load(body)
        currentUE = null
        $('.contenu-onglet .detail-parcours-table tr').each () ->
          if $('.thlike', @).get().length is 1
            currentUE = /.*\((.*)\)/.exec($('.thlike', @).get(0).children[0].data)[1]
          else if $('a', @).get().length is 1
            if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36036&_lang=fr'
            # # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36040&_lang=fr' or
            # # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=34969&_lang=fr' or
            # # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36060&_lang=fr' or
            # # $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=34873&_lang=fr'
              urls.push
                UE: currentUE
                url: $('a', @).attr('href')

        Promise.each urls, (url) ->
          console.log '-->', url.url # A laisser pour la progession du code
          new Promise (resolve) ->
            res=''
            tika = spawn('java', ['-jar', 'tika-app-1.17.jar', '--text', url.url])
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
  # console.log "#{JSON.stringify catalogue, null, 2}"
  console.log "fin"
.catch (err) ->
  console.log 'ERR', err
