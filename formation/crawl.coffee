Promise = require 'bluebird'
cheerio = require 'cheerio'
request = require('request-promise').defaults
  url: 'https://www.insa-lyon.fr/fr/formation/diplomes/ING'

{spawn}  = require 'child_process'

request()
.then (body) ->
  $ = cheerio.load(body)
  $('.diplome').each () ->
    console.log $(@).attr('id')
    $('.contenu table tr td a', @).each () ->
      url = $(@).attr('href')
      console.log "--> #{url}"
      if url is '/fr/formation/parcours/729/4/2'
        request
          url:'https://www.insa-lyon.fr'+url
          method: 'GET'
        .then (body) ->
          $ = cheerio.load(body)
          $('.contenu-onglet .detail-parcours-table .even').each () ->
            url = $(@).children('td').children('a').attr('href')
            if url is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=34172&_lang=fr'
              curl = spawn('curl', [url])
              tika = spawn('java', ['-jar', 'tika-app-1.17.jar', '--text'])
              curl.stdout.on 'data', (chunk) ->
                tika.stdin.write(chunk)
              curl.on 'close', (code) ->
                tika.stdin.end()
              tika.stdout.on 'data', (data) ->
                console.log '-->', data.toString()
