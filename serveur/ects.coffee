express = require('express')
app = express()
db = require '../db'
Promise = require 'bluebird'
_ = require 'lodash'

getMatrix = (req) ->
  comps = req.competences.map (comp) -> [
    ['', comp.terme.terme, comp.niveau],
    comp.connaissances.map( (connaissance) ->
      ['Connaissance', connaissance.terme, '']
    )...
    comp.capacites.map( (capacite) ->
      ['Capacite', capacite.terme, '']
    )...
  ]
  Promise.resolve(_.flatten comps)

getTemplate = (rows) ->
  trs = rows.map (row) ->
    "<tr><td>#{row.join('</td><td>')}</td></tr>"

  """
  <!DOCTYPE html>
  <html lang="fr">
    <head>
      <meta charset="utf-8">
      <title>Matiere</title>
      <style>
        table {
          border-collapse: collapse;
          border-color: black;
          border-style: groove;
        }
      </style>
    </head>
    <body>
      <table>\n<tr><th colspan='3'>AGP</th></tr>\n#{trs.join('\n')}\n</table>
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
      ec: res
    .populate 'ec terme capacites connaissances'
    .then (comps) ->
      req.competences = comps
  .then () -> next()
  .catch next

app.get '/:ectsName', (req, res) ->
  getMatrix(req)
  .then getTemplate
  .then (html) ->
    res.send(html)

module.exports = app
