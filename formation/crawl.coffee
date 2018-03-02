Promise = require 'bluebird'
cheerio = require 'cheerio'
request = require('request-promise').defaults
  url: 'https://www.insa-lyon.fr/fr/formation/diplomes/ING'

request()
.then (body) ->
  $ = cheerio.load(body)
  $('.diplome .contenu table tr td').each () ->
    url = $(@).children('a').attr('href')
    if url is '/fr/formation/parcours/729/4/2'
      request
        url:'https://www.insa-lyon.fr'+url
        method: 'GET'
      .then (body) ->
        $ = cheerio.load(body)
        $('.contenu-onglet .detail-parcours-table .even').each () ->
          url = $(@).children('td').children('a').attr('href')
          if url is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=34172&_lang=fr'
            request
              url: url
            .then (body) ->
              console.log body
