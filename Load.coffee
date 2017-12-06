db = require './db'
csv = require 'csvtojson'
Promise = require 'bluebird'

db.connect()
.then () ->
  db.UE.remove({}).exec()
  db.EC.remove({}).exec()
  db.Enseignant.remove({}).exec()
  db.NiveauCompetence.remove({}).exec()
  db.Competence.remove({}).exec()
  db.Vocabulaire.remove({}).exec()

  a = require './Competences.json'
  Promise.map a, (elem) -> db.Competence.create
    terme: elem

  #
  # new Promise (resolve, reject) ->
  #   csv()
  #   .fromFile('./Competences.csv')
  #   .on 'json', (data) ->
  #     console.log "-->", data
  #     # db.Competence.push data
  #   .on 'done', (error) ->
  #     if error then return reject error
  #     resolve competences

.catch (err) ->
  console.log("erreur", err)
.finally () ->
  db.disconnect()
