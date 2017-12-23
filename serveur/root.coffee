app = require('express')()
db = require '../db'
Promise = require 'bluebird'
_ = require 'lodash'
json2xls = require 'json2xls'

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
          ['', '', '', '', comp.terme.terme, comp.niveau],
          comp.details.map( (detail) ->
            ['', '', '', detail.classe, detail.terme.terme, '']
          )...
        ]
        if comps[0]?
          comps[0][0][0] = semestre.nom
          comps[0][0][1] = ue.nom
          comps[0][0][2] = ec.nom
        else # Si la matière est vide
          comps = [[[ec.nom,'', '', '']]]
        comps
  _.flattenDepth a, 4

getTemplate = (rows) ->
  trs = rows.map (row) ->
    if row[2]
      row[2] = "<a href='/ects/#{row[2]}'>#{row[2]}</a>"
      "<tr class='ec'><td>#{row.join('</td><td>')}</td></tr>"
    else if row[5]
      "<tr class='comp'><td>#{row.join('</td><td>')}</td></tr>"
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
          font-style: italic;
          font-weight: bold;
          vertical-align: top;
        }
        .comp td {
          font-style: italic;
          font-weight: bold;
        }
      </style>
    </head>
    <body>
      <table>\n#{trs.join('\n')}\n</table>
      <form id='rootform' action='' method='post'>
        <input type='submit' value='Générer excel'>
      </form>
    </body>
  </html>
  """

app.use(json2xls.middleware)

app.post '/', (req, res) ->
  getData()
  .then getMatrix
  .then (mat) ->
    curSem = ''
    curUE = ''
    a = _.map mat, (m) ->
      'Semestre': if m[0] isnt '' and curSem isnt m[0]
        curSem = m[0]
      else
        ''
      'UE': if m[1] isnt '' and curUE isnt m[1]
        curUE = m[1]
      else
        ''
      'EC': m[2]
      'Type': m[3]
      'Compétence': m[4]
      'Niveau': m[5]

    res.xls('competences.xlsx', a, {style: 'serveur/styles.xml'})

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
