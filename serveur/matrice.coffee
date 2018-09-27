express = require('express')
app = express()
_ = require('lodash')

data = require('../formation/catalogue-TC.json')[0]

calculComps = ->
  data.semestres.reduce (comps, semestre) ->
    semestre.ecs.reduce (comps, ec) ->
      unless ec.detail then return comps
      if ec.detail.listeComp
        ec.detail.listeComp.reduce (comps, comp) ->
          comps[comp.code] =
            code: comp.code
            val: comp.val
          comps
        , comps
      else
        comps
    , comps
  , {}

comps = calculComps()
keys = _.sortBy(_.keys(comps))
keys.forEach (key, index) ->
  comps[key].index = index

console.log "keys", keys

headComp = ->
  keys.map (key) ->
    "<th class='#{key[0]}'><span>#{key} : #{comps[key].val}</span></th>"
  .join('\n')

ecComp = (ec) ->
  keys.map (key) ->
    if ec.detail.competenceToCapaciteEtConnaissance?[key]
      "<td class='#{key[0]}'>x</td>"
    else
      "<td class='#{key[0]}'></td>"
  .join("\n")

semestreTr = (semestre, name) ->
  semestre.ecs.filter((ec) -> ec.detail.listeComp?).map (ec, index) ->
    if index is 0
      """
      <tr>
        <td rowspan="#{semestre.ecs.length}">#{name}</td>
        <td>#{ec.detail.code}</td>
        #{ecComp(ec)}
      </tr>
      """
    else
      """
      <tr>
        <td>#{ec.detail.code}</td>
        #{ecComp(ec)}
      </tr>
      """
  .join('\n')

app.get '/GCU', (req, res) ->
  res.send """
  <!doctype html>
  <html lang="fr">
  <head>
    <meta charset="utf-8">
    <title>#{data.departement}</title>
    <style>
      .A {
        background-color: #f3e3e3;
      }
      .B {
        background-color: #ecfdd8;
      }
      .C {
        background-color: #d8defd;
      }
      table td {
        white-space: nowrap;
      }

      thead tr th span {
        writing-mode: vertical-rl;
        text-orientation: mixed;
        height: 300px;
        width: 30px;
        overflow: hidden;
        text-overflow: ellipsis;
        font-size: x-small;
      }

      table {
        border-collapse: collapse;
      }

      table th, table td {
        border: solid 3px;
        border-collapse: collapse;
        max-height: 200px;
        overflow: hidden;
      }

      table td {
        text-align: center;
      }
    </style>
  </head>
  <body>
    <table>
      <thead>
          <tr>
            <th>Semestre</th>
            <th>EC</th>
            #{headComp()}
          </tr>
      </thead>
      <tbody>
        #{semestreTr(data.semestres[0], "Semestre 5")}
      </tbody>
    </table>
  </body>
  </html>
  """

module.exports = app
