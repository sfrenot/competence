db = require './db'
csv = require 'csvtojson'
Promise = require 'bluebird'
_ = require 'lodash'

currentMatName = undefined
ec = undefined

mapVocabulaire = {}

addVoc = (voc) ->
  if mapVocabulaire[voc]
    mapVocabulaire[voc]
  else
    mapVocabulaire[voc] = db.Vocabulaire.create
      terme: voc

insertDetail = () ->
  setAndCheckMatiere = (data, matieres) ->
    if data.field1 is '' and data.field2 isnt '' then return Promise.resolve()
    if data.field1 isnt ''
      currentMatName = _.last(data.field1.split('-'))
    ec = _.find matieres,
      ec: {nom: currentMatName}
      terme: {terme: data.field3}
      niveau: data.field4

    unless ec
      return Promise.reject(
        "Erreur sur #{currentMatName}, #{data.field3}, #{data.field4}")

    return Promise.resolve()

  addCompetenceOrConnaissance = (data) ->

    if data.field2 is '' then return Promise.resolve()
    if data.field2 is 'Capacité'
      # console.log "-> Capa", ec.ec.nom, ec.terme.terme.substring(0,4), data.field3
      return addVoc(data.field3)
      .then (voc) ->
        ec.capacites.push(voc)

    if data.field2 is 'Connaissance'
      # console.log "-> Conn", ec.ec.nom, ec.terme.terme.substring(0,4), data.field3
      return addVoc(data.field3)
      .then (voc) ->
        ec.connaissances.push(voc)

    return Promise.reject("#{currentMatName} : #{ec.terme.term}: #{JSON.stringify data, null, 2}")

  readCsv = ->
    new Promise (resolve, reject) ->
      datas = []

      csv({flatKeys: true, delimiter: ";", noheader: true})
      .fromFile('./TC\ DetailCompetences\ 2017-12-04.csv')
      .on 'json', (data) ->
        datas.push data
      .on 'done', (error) ->
        if error
          return reject error
        resolve(datas)

  loadDataBase = ->
    db.NiveauCompetence
    .find()
    .populate 'terme'
    .populate 'ec'
    .exec()

  Promise.all [
    readCsv()
    loadDataBase()
  ]
  .then ([datas, matieres]) ->
    # console.log "matieres", matieres
    Promise.mapSeries datas, (data) ->
      setAndCheckMatiere(data, matieres)
      .then () -> addCompetenceOrConnaissance(data)
      .catch (err) -> console.log "ERREUR", err
    .then () ->
      Promise.map matieres, (matiere) ->
        matiere.save()

db.connect()
.then () ->
  return Promise.all [
    db.NiveauCompetence.update({}, {$set: {capacités: [], connaissances: []}}, multi: true).exec()
    db.Vocabulaire.remove({}).exec()
  ]
  .then insertDetail

.catch (err) ->
  console.log("erreur", err)
.finally () ->
  Promise.all [
    # currentSemestre.save()
    # currentUE.save()
  ]
  .then () ->
    db.disconnect()
