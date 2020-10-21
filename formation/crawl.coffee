# Lancement du parser tika
# java -jar tika-app-1.17.jar --text -s -p 1234
# TODO : garer le format sans écraser les retours à la ligne.
# Extraire la section parmis cette liste

Promise = require 'bluebird'
cheerio = require 'cheerio'
request = require('request-promise').defaults
  url: 'https://www.insa-lyon.fr/fr/formation/diplomes/ING'
{spawn}  = require 'child_process'
_ = require 'lodash'

if process.argv.length < 3
  console.info("Usage : coffee ./crawl.coffee <DPT> [<SPECIALITE>]")
  process.exit()

DPTINSA = process.argv[2]

SPECIALITE = process.argv[3] ||  ""
analyseurDpt = require "./extract-#{DPTINSA}-#{SPECIALITE}"
unless _.isEmpty(SPECIALITE) then SPECIALITE = " #{SPECIALITE}"

extractRe = (re, src) ->
  return re.exec(src)[0].split(' : ')[1]

buildCaptureMiddle = (from, to) ->
  regle = new RegExp("#{from}([\\s\\S]*)#{to}", 'g')
  return regle

getCompetenceBruteSection = (pdf) ->
  mainSections = ["OBJECTIFS", "PROGRAMME", "BIBLIOGRAPHIE", "PRÉ-REQUIS", "\n\n[http//if.insa-lyon.fr|mailto]"]
  for section in mainSections
    rech = buildCaptureMiddle("OBJECTIFS RECHERCHÉS PAR CET ENSEIGNEMENT\n", section).exec(pdf)
    if rech?
      solution = rech[1].trim()
      solution = solution.replace(/mailto:[^\n]*\n/g, '')
      solution = solution.replace(/http:\/\/www\.insa-lyon\.fr[\s\S]*?Dernière modification le : [^\n]*\n/g, '')
      tmp = solution.replace(/\n/g,' ').replace(/l¿/g, 'l\'') # PB DE GI
      return tmp
  return null

analyseur = (pdf) ->

  matiere = {}
  # console.warn "-->", pdf
  # console.warn "Recherche mat"
  matiere.code = extractRe(/CODE : .*ECTS/s, pdf).replace(/\n/g, '')
  matiere.code = matiere.code.substring(0, matiere.code.length-('ECTS'.length))
  # //
  # Bug fix for coffeescript linter

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
    return matiere

  matiere.capacite = []
  matiere.connaissance = []
  matiere.competenceToCapaciteEtConnaissance = {}

  matiere = analyseurDpt(matiere, DPTINSA)

  matiere

catalogue = []
request()
.then (body) ->
  $ = cheerio.load(body)
  $('.diplome').each () ->
    departement = $(@).attr('id')
    if departement is DPTINSA
      semestres = []
      $('.contenu table tr td a', @).each () ->
        # if $(@).attr('href') is '/fr/formation/parcours/1371/3/2' # BIM
        # if $(@).attr('href') is '/fr/formation/parcours/721/3/1' # GEN
        # if $(@).attr('href') is '/fr/formation/parcours/722/3/1' # GI
        # if $(@).attr('href') is '/fr/formation/parcours/726/4/1' # IF
        # if $(@).attr('href') is '/fr/formation/parcours/719/4/2' #GCU
        # if $(@).attr('href') is '/fr/formation/parcours/1334/5/2' #GM
          if $(@).text().trim() is "Parcours Standard#{SPECIALITE}" or
             $(@).text().trim().startsWith("Parcours 5IF") or
             departement is 'GM'
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
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=37974&_lang=fr' #BIM
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=38623&_lang=fr' #GEN
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=38494&_lang=fr' #GI
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=38444&_lang=fr' # GCU
            # if $('a', @).attr('href') is 'http://planete.insa-lyon.fr/scolpeda/f/ects?id=41824&_lang=fr' # GM
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
            if _.isEmpty(pdf)
              console.error ("Warning : url inconnue #{url.url}")
            semestre.ecs.push
              UE: url.UE
              url: url.url
              detail: unless _.isEmpty(pdf) then analyseur(pdf, DPTINSA) else {}

.then () ->
  console.log "#{JSON.stringify catalogue, null, 2}"

.then () ->
  # console.warn "#{JSON.stringify catalogue, null, 2}"
  console.warn "fin"
.catch (err) ->
  console.warn 'ERR', err
.finally () ->
  # spawn("sh", ["-c", "killall java"])
  console.warn "Fin"
