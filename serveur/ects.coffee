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
  comps = req.competences.map (comp, comp_idx) -> [
    ['', comp.terme.terme, comp.niveau, comp.terme._id, comp_idx],
    comp.details.map( (detail, idx) ->
      [detail.classe, detail.terme.terme, '', detail._id, idx, comp.terme.terme.substring(0,4)]
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
      [ ''
      ,
        """<select name='competences'>\n
                   #{injectCompetences(row[1]).join('')}
                  </select>\n
        """
      ,
        "<select name='compLevel'>\n
        #{[1..3].map((elem) -> injectOption('C'+elem, 'C'+elem, row[2])).join(' ')}
        #{[1..3].map((elem) -> injectOption('M'+elem, 'M'+elem, row[2])).join(' ')}
        </select>"
      ,
        "<input type='submit' value='-' name='delete-comp-#{row[3]}-#{row[4]}'>"
      ]
    else
      [
        """<select name='coap-#{currentComp}'>\n
                   #{injectOption('Capacité','Capacité', row[0])}
                   #{injectOption('Connaissance', 'Connaissance', row[0])}
           </select>\n
        """
      ,
        "<input type='text' size='119' name='coapValue-#{currentComp}' value='#{row[1].replace('\'', '&rsquo;')}'"
      ,
        "<input type='submit' value='-' name='delete-coap-#{row[5]}-#{row[4]}-#{row[3]}'>"
      ,
        ''
      ]


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
            <th colspan='4'>#{nom}</th>
          </tr>\n
          #{trs.join('\n')}\n
          <tr>
            <td colspan='4' style='text-align: center;'>
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
    .populate 'ec terme details.terme'
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

      Promise.mapSeries coaps, (coap, idx) ->
        db.Vocabulaire.create
          terme: coap
        .then (terme) ->
          classe: if kinds[idx] is 'Connaissance' then 'Connaissance' else 'Capacité'
          terme: terme
    else
      Promise.resolve([])

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
          details: tableauCapaConn
          niveau: req.body.compLevel[idx]
  .then (res) ->
    req.competences = res
    req

removeCoap = (req) ->
  competenceId = (_.find (_.keys req.body), (elem) ->
    elem.startsWith('delete-'))?.substring("delete-".length)
  unless competenceId? then return Promise.resolve(req)
  [type, comp, idx, id] = competenceId.split('-')

  if type is 'coap'
    req.body["coap-#{comp}"].splice(idx, 1)
    req.body["coapValue-#{comp}"].splice(idx, 1)
  else
    console.log "->", req.body
    req.body["competences"].splice(idx, 1)
    req.body["compLevel"].splice(idx, 1)

  Promise.resolve(req)

db.Competence.find({}).then (lcomps) ->
  competences = lcomps

  app.get '/:ectsName', (req, res) ->
    render(req)
    .then (html) ->
      res.send(html)

  app.post '/:ectsName', (req, res) ->
    _.map req.body, (value, key) ->
      if _.isString(value)
        req.body[key] = [value]
      else
        req.body[key] = value

    removeCoap(req)
    .then saveChanges
    .then render
    .then (html) ->
      res.send(html)

module.exports = app
