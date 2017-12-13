express = require('express')
app = express()
db = require '../db'
Promise = require 'bluebird'
_ = require 'lodash'
bodyParser = require 'body-parser'
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))

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

injectOption = (id, name, sel) ->
  "<option value='#{id}' #{if name is sel then 'selected'}>#{name}</option>\n"

injectCompetences = (aCompetence) ->
  competences.map (competence) ->
    injectOption(competence._id, competence.terme, aCompetence)

getTemplate = (rows, nom) ->
  injectSelects = (row) ->
    if row[0] is ''
      row[1] = """<select id='competence'>\n
                   #{injectCompetences(row[1])}
                  </select>\n
               """
    else
      row[0] = """<select id='coap'>\n
                   #{injectOption('Capacite','Capacite', row[0])}
                   #{injectOption('Connaissance', 'Connaissance', row[0])}
                  </select>\n
               """
      row[1] = "<textarea cols='115' rows='1'>#{row[1]}</textarea>"

    row[2] = if row[2] isnt ''
      "<textarea cols='2' rows='1'>#{row[2]}</textarea>"

    row

  trs = rows.map (row) ->
    "<tr><td>#{injectSelects(row).join('</td><td>')}</td></tr>"

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
      <form action='' method='post'>
        <table>\n
          <tr>
            <th colspan='3'>#{nom}</th>
          </tr>\n
          #{trs.join('\n')}\n
          <tr>
            <td colspan='3' style='text-align: center;'>
              <input type='submit' value='Valider'>
              <input type='submit' value='Annuler'>
            </td>
          </tr>
        </table>
      </form>
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
    .then (matrix) ->
      getTemplate(matrix, req.ec.nom)
    .then (html) ->
      res.send(html)

  app.post '/:ectsName', (req, res) ->
    console.log "->", req.body
    res.send("ok")

module.exports = app
