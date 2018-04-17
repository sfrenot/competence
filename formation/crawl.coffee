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

#####
# Skilvioo Routines
#####
headers = {
  'Accept': 'application/json'
  'Authorization':'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjFkMWEzMmJlLTM1ZDAtNGRmNy1iYzFhLTY0ZDNjYmU0Mjg5OSIsImZpcnN0bmFtZSI6IkJlbmphbWluIiwibGFzdG5hbWUiOiJSb3VsbGV0IiwiZW1haWwiOiJiZW5qYW1pbi5yb3VsbGV0QHNraWx2aW9vLm5ldCIsInBob25lIjoiMDY5NTU1MzcwMSIsInRvQmVDcmVhdGVkIjpudWxsLCJyb2xlIjpudWxsLCJyZWFsbSI6InNraWx2aW9vLWZvcm1hdGlvbi1mcm9udGVuZCIsImN1cnJlbnRPcmdhbmlzYXRpb24iOnsiYWRkcmVzcyI6IjIwIEF2ZW51ZSBBbGJlcnQgRWluc3RlaW4sIDY5MTAwIFZpbGxldXJiYW5uZSIsInRyYWluaW5nTnVtYmVyIjoiNSIsIm5hbWUiOiJJTlNBIEx5b24iLCJpZCI6Ijk4NmRjZjNiLTMyMWUtNDVmYi1hZjJlLTQxZWVlMDM5NWQxMyIsInR5cGUiOiJvcmdhbmlzYXRpb24udHlwZXMuZW5naW5lZXJpbmdfc2Nob29sIiwicm9sZSI6IkFETUlOX09SR0EifSwiaWF0IjoxNTIzNjAzNDIwfQ.ZBY1EJYIt50khcx3Tg5heCEIxmrZEGVTSKvbT6caMKo'
}

insertDepartement = (name) ->
  console.log 'ajout departement', name
  request
    url:'https://skilvioo-training.herokuapp.com/trainings'
    method: 'POST'
    headers: headers
    form:
      'idOrganisation':'986dcf3b-321e-45fb-af2e-41eee0395d13'
      'trainingName': "INSA Lyon #{name}"
      'trainingType': 'training.training_types.4'
      'userId': '1d1a32be-35d0-4df7-bc1a-64d3cbe42899'
      'isContinue': false
      'isInitial': true
      'trainingVae': true

UEs = {}
insertUE = (departement_id, UE_name) ->
  ue_id = UEs[UE_name]
  unless ue_id?
    console.log "Ajout UE #{UE_name}"
    request
      url: "https://skilvioo-training.herokuapp.com/trainings/#{departement_id}/blocks"
      method: 'POST'
      headers: headers
      form:
        "name": UE_name
        "color": '#FF0000'
    .then (res) ->
      ue_id = JSON.parse(res).id
      UEs[UE_name]=ue_id
      Promise.resolve(ue_id)
  else
    console.log "Insert dans #{UE_name}"
    Promise.resolve(ue_id)

insertEC = (UE_id, ec) ->
  request
    url: "https://skilvioo-training.herokuapp.com/blocks/#{UE_id}/blocks"
    method: 'POST'
    headers: headers
    form:
      "name": ec.detail.code
      "color": '#FFFF00'

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
              urls.push
                UE: currentUE
                url: $('a', @).attr('href')

        Promise.each urls, (url) ->
          console.log '-->', url.url # A laisser pour la progession du code
          new Promise (resolve) ->
            res=''
            curl = spawn('curl', [url.url])
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
              UE: url.UE
              url: url.url
              detail: extractPdfStructure(pdf)
.then () ->

  console.log "#{JSON.stringify catalogue, null, 2}"
  console.log "insertion"
  Promise.map catalogue, (departement) ->
    insertDepartement("INSA Lyon #{departement.departement}")
    .then (res) ->
      departement.id = JSON.parse(res).id
      Promise.map departement.semestres, (semestre) ->
        console.log "Ajout semestre", semestre.url
        Promise.map semestre.ecs, (ec) ->
          insertUE(departement.id, ec.UE)
          .then (UE) ->
            insertEC(UE, ec)

.then () ->
  # console.log "#{JSON.stringify catalogue, null, 2}"
  console.log "fin"
.catch (err) ->
  console.log 'ERR', err
