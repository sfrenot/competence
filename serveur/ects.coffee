express = require('express')
app = express()
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
        .populate "terme capacites connaissances"
        .lean()
        .exec()
        .then (comps) ->
          ec.comps = comps
          ec
    .then () ->
      sem

getMatrix = (req) ->
  # a = semestres.map (semestre) ->
  #   semestre.ues.map (ue) ->
  #     ue.ecs.map (ec) ->
  comps = req.competences.map (comp) -> [
    ['', '', comp.terme.terme, comp.niveau],
    comp.connaissances.map( (connaissance) ->
      ['', 'Connaissance', connaissance.terme, '']
    )...
    comp.capacites.map( (capacite) ->
      ['', 'Capacite', capacite.terme, '']
    )...
  ]
  # comps[0][0][0] = ec.nom
  console.log "->", comps
  comps
  # _.flattenDepth a, 4

getTemplate = (rows) ->
  trs = rows.map (row) ->
    if row[0]
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

app.param 'ectsName', (req, res, next, ectsName) ->
  db.EC.findOne
    nom: ectsName.toUpperCase()
  .exec()
  .then (res) ->
    req.ec = res
    db.NiveauCompetence.find
      _id: res._id
    .populate 'ec terme capacites connaissances'
    .then (comps) ->
      return Promise.reject(new Error('Mauvaise matiere'))
      req.competences = comps
  .then () -> next()
  .catch next

app.get '/:ectsName', (req, res) ->
  # getMatrix(req)

  console.log 'coucou2'
  res.send('ok')
  # getData()
  # .then getMatrix
  # .then getTemplate
  # .then (html) ->
  #   res.send(html)
module.exports = app
