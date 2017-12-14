express = require('express')
app = express()
mongoose = require 'mongoose'
db = require '../db'
Promise = require 'bluebird'
_ = require 'lodash'
bodyParser = require 'body-parser'
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))

competences = []
currentComp = ''

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
  "<option value='#{id}' #{if name is sel then 'selected' else ''}>#{name}</option>\n"

injectCompetences = (aCompetence) ->
  competences.map (competence) ->
    injectOption(competence._id, competence.terme, aCompetence)

getTemplate = (rows, nom) ->
  injectSelects = (row) ->
    if row[0] is ''
      currentComp = row[1].substring(0, 4)
      row[1] = """<select name='competences'>\n
                   #{injectCompetences(row[1]).join('')}
                  </select>\n
               """
    else
      row[0] = """<select name='coap-#{currentComp}'>\n
                   #{injectOption('Capacite','Capacite', row[0])}
                   #{injectOption('Connaissance', 'Connaissance', row[0])}
                  </select>\n
               """
      row[1] = "<input type='text' size='119' name='coapValue-#{currentComp}' value='#{row[1]}'"

    row[2] = if row[2] isnt ''
      "<select name='compLevel'>\n
      #{[1..3].map((elem) -> injectOption('C'+elem, 'C'+elem, row[2])).join(' ')}
      #{[1..3].map((elem) -> injectOption('M'+elem, 'M'+elem, row[2])).join(' ')}
      </select>"
    else
      delete(row[3])
      "<input type='submit' value='-' name=''>"

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
      <form id='formulaire' action='' method='post'>
        <table>\n
          <tr>
            <th colspan='3'>#{nom}</th>
          </tr>\n
          #{trs.join('\n')}\n
          <tr>
            <td colspan='3' style='text-align: center;'>
              <input type='submit' value='Valider' id='bouttonValider'>
              <input type='reset' value='Annuler'>
            </td>
          </tr>
        </table>
      </form>
      <script>
        const form = document.getElementById('formulaire');
        const validerButton = document.getElementById('bouttonValider');
        form.addEventListener('input', function () {
          validerButton.style.backgroundColor = 'green';
        });
        form.addEventListener('reset', function () {
          validerButton.style.backgroundColor = 'white';
        });
      </script>
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

render = (req) ->
  getMatrix(req)
  .then (matrix) ->
    getTemplate(matrix, req.ec.nom)

saveChanges = (req) ->

  saveVocabulaire = (idComp) ->
    coaps = req.body["coapValue-#{idComp}"]
    if coaps?
      kinds = req.body["coap-#{idComp}"]
      allConn = _.filter coaps, (coap, idx) ->
        kinds[idx] is 'Connaissance'
      allCapa = _.filter coaps, (coap, idx) ->
        kinds[idx] is 'Capacite'

      Promise.all [
        Promise.map allCapa, (desc) ->
          db.Vocabulaire.create
            terme: desc
        Promise.map allConn, (desc) ->
          db.Vocabulaire.create
            terme: desc
      ]
    else
      Promise.resolve([undefined, undefined])

  db.NiveauCompetence.remove
    ec:req.ec
  .exec()
  .then () ->
    Promise.mapSeries req.body.competences, (comp, idx) ->
      terme = _.find competences, (compe) -> compe._id.toString() is comp
      saveVocabulaire(terme.terme.substring(0,4))
      .then (tableauCapaConn) ->
        db.NiveauCompetence.create
          ec: req.ec
          terme: terme
          niveau: req.body.compLevel[idx]
          capacites: tableauCapaConn[0]
          connaissances: tableauCapaConn[1]
  .then (res) ->
    req.competences = res
    req

db.Competence.find({}).then (comps) ->
  competences = comps

  app.get '/:ectsName', (req, res) ->
    render(req)
    .then (html) ->
      res.send(html)

  app.post '/:ectsName', (req, res) ->
    saveChanges(req)
    .then render
    .then (html) ->
      res.send(html)

module.exports = app
