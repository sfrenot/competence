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
  matiere.code = extractRe(/CODE : .*/, pdf)
  matiere.ects = extractRe(/ECTS : .*/, pdf)
  matiere.cours = extractRe(/Cours : .*/, pdf)
  matiere.td = extractRe(/TD : .*/, pdf)
  matiere.tp = extractRe(/TP : .*/, pdf)
  matiere.perso = extractRe(/Travail personnel : .*/, pdf)

  matiere.competences = /COMPETENCES \/ CONNAISSANCES\n([\s\S]*)PROGRAMME/g.exec(pdf)[1]

  console.log "-->", matiere
  matiere

catalogue = {}
request()
.then (body) ->
  semesters = []
  $ = cheerio.load(body)
  $('.diplome').each () ->
    departement = $(@).attr('id')
    if departement is 'TC'
      unless catalogue[departement]? then catalogue[departement]={}
      $('.contenu table tr td a', @).each () ->
        if $(@).attr('href') is '/fr/formation/parcours/729/4/1'
          semesters.push($(@).attr('href'))
      Promise.map semesters, (url) ->
        request
          url:'https://www.insa-lyon.fr'+url
          method: 'GET'
      .then (bodies) ->
        Promise.map bodies, (body) ->
          urls = []
          $ = cheerio.load(body)
          semestre = $('.contenu-onglet h2').text()
          unless catalogue[departement][semestre]?
            catalogue[departement][semestre] = []
          $('.contenu-onglet .detail-parcours-table .even td a').each () ->
            if $(@).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=32965&_lang=fr'
              urls.push($(@).attr('href'))
          Promise.map urls, (url) ->
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
              catalogue[departement][semestre].push(extractPdfStructure(pdf))
    # else
    #   false
# .then () ->
#   console.log "#{JSON.stringify catalogue, null, 2}"
