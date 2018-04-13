Promise = require 'bluebird'
cheerio = require 'cheerio'
request = require('request-promise').defaults
  url: 'https://www.insa-lyon.fr/fr/formation/diplomes/ING'
_ = require 'lodash'

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
        # semestre = $('.contenu-onglet h2').text()
        $('.contenu-onglet .detail-parcours-table .even td a').each () ->
          if $(@).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=36523&_lang=fr'
            urls.push($(@).attr('href'))
        Promise.each urls, (url) ->
          console.log '-->', url
          new Promise (resolve) ->
            res=''
            curl = spawn('curl', [url])
            tika = spawn('java', ['-jar', 'tika-app-1.17.jar', '--text'])
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
              url: url
              detail: extractPdfStructure(pdf)
.then () ->
  console.log "#{JSON.stringify catalogue, null, 2}"
