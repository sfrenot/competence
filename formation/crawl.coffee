Promise = require 'bluebird'
cheerio = require 'cheerio'
request = require('request-promise').defaults
  url: 'https://www.insa-lyon.fr/fr/formation/diplomes/ING'
_ = require 'lodash'

{spawn}  = require 'child_process'

request()
.then (body) ->
  $ = cheerio.load(body)
  $('.diplome').each () ->
    departement = $(@).attr('id')
    $('.contenu table tr td a', @).each () ->
      url = $(@).attr('href')
      if url is '/fr/formation/parcours/729/4/2'
        request
          url:'https://www.insa-lyon.fr'+url
          method: 'GET'
        .then (body) ->
          $ = cheerio.load(body)
          $('.contenu-onglet .detail-parcours-table .even td a').each () ->
            url = $(@).attr('href')
            if url is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=34172&_lang=fr'
              curl = spawn('curl', [url])
              tika = spawn('java', ['-jar', 'tika-app-1.17.jar', '--text'])
              curl.stdout.on 'data', (chunk) ->
                tika.stdin.write(chunk)
              curl.on 'close', (code) ->
                tika.stdin.end()
              tika.stdout.on 'data', (data) ->
                code = /\n/
                lignes = _.split data, code
                lignes.forEach (ligne) ->
                  if ligne?
                    if /^CODE/.test(ligne)
                      console.log "code : #{ligne.split(/^CODE/)[1]}"
                    # code = _.split ligne, /^CODE/
                    # console.log "split : #{code}"

                # console.log "split : #{lignes}"
                # console.log "-->#{departement} ", data.toString()
