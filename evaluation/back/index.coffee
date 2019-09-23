express = require 'express'
mongoClient = require('mongodb').MongoClient
graphqlHTTP = require('express-graphql')
cors = require('cors')
_ = require('lodash')
session = require('express-session')
CASAuthentication = require 'cas-authentication'

{ buildSchema } = require('graphql')

SERVER_URL = require('./config.json').SERVER_URL

corsOptions =
  origin: "http://#{SERVER_URL}:4200"
  credentials: true


schema = buildSchema "
  type Eval {
    nom: String,
    eval: Int
  }

  type DescriptionCompetence {
    code: String,
    val: String,
    niveau: Int,
    connaissances: [Eval],
    capacites: [Eval]
  }

  type MatiereEvaluee {
    code: String,
    listeComp: [DescriptionCompetence]
  }

  type EvalEnseignant {
    login: String,
    matieres: [MatiereEvaluee]
  }

  type Query {
    evalsMatieres: EvalEnseignant
  }

"

db = ''

getMatieres = (login) ->
  catalogue = require('../../formation/catalogue-TC')
  dpt = catalogue[0].departement

  matieres = _.map(_.map(_.flatten(_.map(_.flatten(catalogue[0].semestres), "ecs")), "detail"), (matiere) ->
    matiere.listeComp = _.map matiere.listeComp, (comp) ->
      comp.connaissances = []
      comp.capacites = []
      code = if comp.code.startsWith('C') then "#{dpt}-#{comp.code}" else comp.code
      matiere.competenceToCapaciteEtConnaissance[code]?.forEach (elem) ->
        if elem.startsWith('Connaissance : ')
          comp.connaissances.push
            nom: elem.substring('Connaissance : '.length)
        if elem.startsWith('Capacité : ')
          comp.capacites.push
            nom: elem.substring('Capacité : '.length)
      if comp.connaissances.length is 0 then delete comp.connaissances
      if not comp.capacites then delete comp.capacites
      comp
    delete matiere.competencesBrutes
    delete matiere.capacite
    delete matiere.connaissance
    delete matiere.competenceToCapaciteEtConnaissance
    delete matiere.listeCompMobilise
    matiere
  )

  matieres = _.filter matieres, (mat) -> mat.listeComp.length > 0

  return
    login: login
    matieres: matieres

queryMap =
  evalsMatieres: (express, req) ->
    console.log '-> TEST', req.session  # When CAS is available
    login = 'sfrenot'
    evaluations = db.collection('evaluations')
    evaluations.findOne({"login": login})
    .then (res) ->
      if res is null # Nouvel utilisateur
        evaluations.insertOne(getMatieres(login))
        .then (res) ->
          evaluations.findOne({_id: res.insertedId})
      else
        res

mongoClient.connect 'mongodb://localhost:27017',
  useUnifiedTopology: true
  useNewUrlParser: true
.then (client) ->
  db = client.db('etudiants')

  app = express()
  app.use(session(
    secret: '120873qsdsqdsq71912'
    resave: false
    saveUninitialized : true
  ))

  cas = new CASAuthentication
    cas_url: 'https://login.insa-lyon.fr/cas'
    service_url: "http://#{SERVER_URL}:8080"

  app.use '/graphql', cors(corsOptions), cas.block, graphqlHTTP(
  # app.use '/graphql', cors(corsOptions), graphqlHTTP( # TESTING
    schema: schema
    rootValue: queryMap
    graphiql: true
  )

  app.use '/', cas.bounce, (req, res) -> res.redirect("http://#{SERVER_URL}:4200")

  app.listen(8080)

.catch (err) ->
  console.error('SFR MONGO: ', err)
  process.exit(1)
