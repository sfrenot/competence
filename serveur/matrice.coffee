express = require('express')
app = express()
_ = require('lodash')

departements = [
  "TC"
  "GEN"
  "GE"
  "GM"
  "GI"
  "SGM"
  "BB"
  "BIM"
  "IF"
  "GCU"
]

refCompetences = require("../formation/refCompetences")

loadDepartement = (departement, res) ->
  data = require("../formation/catalogue-#{departement}.json")[0]

  comps = _.omitBy refCompetences, (value, key) ->
    not key.match(/^[AB]\d/) and not key.startsWith("#{departement}-")

  comps = _.mapKeys comps, (value) ->
    return value.code

  keys = _.keys(comps)

  keys.forEach (key, index) ->
    comps[key].index = index

  headComp = ->
    keys.map (key) ->
      # console.log "->", key
      "<th class='#{key[0]}'><span>#{key} : #{comps[key].val}</span></th>"
    .join('\n')

  ecComp = (ec) ->
    keys.map (key) ->
      competence = _.find(ec.detail.listeComp, {'code': key})
      if competence?
        if competence.niveau
          "<td class='#{key[0]}'>#{competence.niveau}</td>"
        else
          "<td class='#{key[0]}'>X</td>"
      else
        competence = _.find(ec.detail.listeCompMobilise, {'code': key})
        if competence?
          "<td class='#{key[0]}'>M</td>"
        else
          "<td class='#{key[0]}'></td>"

    .join("\n")

  semestreTr = (semestre, name) ->
    goodEcs = semestre.ecs.filter((ec) -> not _.isEmpty(ec.detail.listeComp))
    goodEcs.map (ec, index) ->
      if index is 0
        """
        <tr>
          <td rowspan="#{goodEcs.length}">#{name}</td>
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

  getMatrice = () ->

    data.semestres.map (semestre, idx) ->
      #console.log '->', semestre, idx
      semestreTr(semestre, "Semestre #{idx}")
    .join('')


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

        .tableheader th{
          border: 0;
        }

        table td {
          text-align: center;
        }

        a {
          text-decoration: none;
        }
      </style>
    </head>
    <body>
      <table class="tableheader">
       <thead>
         <tr>
           <th><a href="TC">TC</a></th>
           <th><a href="GEN">GEN</a></th>
           <th><a href="GE">GE</a></th>
           <th><a href="GM">GM</a></th>
           <th><a href="GI">GI</a></th>
           <th><a href="SGM">SGM</a></th>
           <th><a href="BB">BB</a></th>
           <th><a href="BIM">BIM</a></th>
           <th><a href="IF">IF</a></th>
           <th><a href="GCU">GCU</a></th>
         </tr>
       </thead>
      </table>
      </br>

      <table>
        <thead>
            <tr>
              <th>Semestre</th>
              <th>EC</th>
              #{headComp()}
            </tr>
        </thead>
        <tbody>
          #{getMatrice()}
        </tbody>
      </table>
    </body>
    </html>
    """

app.param 'departement', (req, res, next, departement) ->
  req.departement = departement
  next()

app.get '/:departement', (req, res) ->
  console.log('->', req.departement)
  if req.departement isnt 'undefined'
    loadDepartement(req.departement, res)
  else
    console.log('->')
    res.redirect('/matrice')

app.get "/", (req, res) ->
  res.send """
    <table class="tableheader">
     <thead>
       <tr>
         <th><a href="/matrice/TC">TC</a></th>
         <th><a href="/matrice/GEN">GEN</a></th>
         <th><a href="/matrice/GE">GE</a></th>
         <th><a href="/matrice/GM">GM</a></th>
         <th><a href="/matrice/GI">GI</a></th>
         <th><a href="/matrice/SGM">SGM</a></th>
         <th><a href="/matrice/BB">BB</a></th>
         <th><a href="/matrice/BIM">BIM</a></th>
         <th><a href="/matrice/IF">IF</a></th>
         <th><a href="/matrice/GCU">GCU</a></th>
       </tr>
     </thead>
    </table>
  """

module.exports = app
