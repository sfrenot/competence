express = require('express')
app = express()
db = require '../db'
Promise = require 'bluebird'
_ = require 'lodash'

competences = []

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

injectCompetence = (aCompetence) ->
  competences.map (competence) ->
    """
      <option value='#{competence._id}'
      #{if competence.terme is aCompetence then 'selected'}>
      #{competence.terme}</option>\n"""

injectCoap = (type, ori) ->
  "<option value='#{type}' #{if ori is type then 'selected'}>#{type}</option>\n"

getTemplate = (rows) ->
  injectCompetences = (row) ->
    if row[0] is ''
      row[1] = """<select id='competence'>\n
                   #{injectCompetence(row[1])}
                  </select>\n
               """
    else
      row[0] = """<select id='coap'>\n
                   #{injectCoap('Capacite', row[0])}
                   #{injectCoap('Connaissance', row[0])}
                  </select>\n
               """
      row[1] = "<textarea cols='115'>#{row[1]}</textarea>"

    row[2] = if row[2] isnt '' then "<textarea cols='2'>#{row[2]}</textarea>"

    row

  trs = rows.map (row) ->
    "<tr><td>#{injectCompetences(row).join('</td><td>')}</td></tr>"

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

db.Competence.find({}).then (comps) ->
  competences = comps

  app.get '/:ectsName', (req, res) ->
    getMatrix(req)
    .then getTemplate
    .then (html) ->
      res.send(html)

module.exports = app
