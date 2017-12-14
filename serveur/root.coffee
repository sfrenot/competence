app = require('express')()
db = require '../db'
Promise = require 'bluebird'
_ = require 'lodash'

getData = () ->
  db.Semestre
  .find()
  .sort "nom"
  .populate
    path: 'ues'
    populate:
      path: 'ecs'
      populate:
        path: 'responsable'
  .lean()
  .exec()
  .map (sem) ->
    Promise.map sem.ues, (ue) ->
      Promise.map ue.ecs, (ec) ->
        db.NiveauCompetence
        .find
          ec: ec
        .sort "niveau"
        .populate "terme details.terme capacites connaissances"
        .lean()
        .exec()
        .then (comps) ->
          ec.comps = comps
          ec
    .then () ->
      sem

getMatrix = (semestres) ->
  a = semestres.map (semestre) ->
    semestre.ues.map (ue) ->
      ue.ecs.map (ec) ->
        comps = ec.comps.map (comp) -> [
          ['', '', comp.terme.terme, comp.niveau],
          comp.details.map( (detail) ->
            ['', detail.classe, detail.terme.terme, '']
          )...
        ]
        comps[0][0][0] = ec.nom
        comps
  _.flattenDepth a, 4

getTemplate = (rows) ->
  trs = rows.map (row) ->
    if row[0]
      row[0] = "<a href='/ects/#{row[0]}'>#{row[0]}</a>"
      "<tr class='ec'><td>#{row.join('</td><td>')}</td></tr>"
    else
      "<tr><td>#{row.join('</td><td>')}</td></tr>"
  """
  <!DOCTYPE html>
  <html lang="fr">
    <head>
      <meta charset="utf-8">
      <title>Competence</title>
      <style>
        table {
          border-collapse: collapse;
          border-color: black;
          border-style: groove;
        }
        .ec td {
          border-top-color: black;
          border-top-style: groove;
        }
      </style>
    </head>
    <body>
      <table>\n#{trs.join('\n')}\n</table>
    </body>
  </html>
  """

app.get '/', (req, res) ->
  getData()
  .then getMatrix
  .then getTemplate
  .then (html) ->
    res.send(html)

app.get '/raw', (req, res) ->
  getData().then (semestres) ->
    res.send(semestres)

module.exports = app
