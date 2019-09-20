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

  type CompetenceEvaluee {
    code: String,
    connaissances: [ Eval ],
    capacites: [ Eval ]
  }

  type DescriptionCompetence {
    code: String,
    val: String,
    niveau: Int
  }

  type MatiereEvaluee {
    code: String,
    competenceToCapaciteEtConnaissance: [CompetenceEvaluee]
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

  return
    login: login
    matieres: _.filter(_.map(_.map(_.flatten(_.map(_.flatten(catalogue[0].semestres), "ecs")), "detail"), (matiere) ->
        matiere.competenceToCapaciteEtConnaissance = _.map(matiere.competenceToCapaciteEtConnaissance, (value, key) ->
          rep = {}
          rep.code = key
          rep.connaissances = _.map(_.filter(value, (elem) -> elem.startsWith('Connaissance : ')), (el) ->
            "nom": el.substring('Connaissance : '.length)
          )
          rep.capacites = _.map(_.filter(value, (elem) -> elem.startsWith('Capacité : ')), (el) ->
            "nom": el.substring('Capacité : '.length)
          )
          rep
        )
        matiere
      )
      , (mat) -> mat.competenceToCapaciteEtConnaissance.length > 0
    )

getMatieresTest = (login) -> #TODO: A supprimer un jour
  login: login
  matieres: [
    code: "TSA"
    competenceToCapaciteEtConnaissance: [
      {
        code: 'TC-C1'
        connaissances: [
          nom : "tcp"
        ]
        capacites: [
          nom: "etre"
        ]
      },
      {
        code: 'TC-C6'
        connaissances: [
          nom : "udp"
        ]
      }
    ]
    listeComp: [
      {
       code: "C2",
       val: "Spécifier, concevoir et modéliser des réseaux de communication et des protocoles",
       niveau: 3
      },
      {
        code: "C6",
        val: "Mettre en œuvre, réaliser, développer, déployer des réseaux et des protocoles",
        niveau: 2
      }
    ]
  ]

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
  #app.use '/graphql', graphqlHTTP( # TESTING
    schema: schema
    rootValue: queryMap
    graphiql: true
  )

  app.use '/', cas.bounce, (req, res) -> res.redirect("http://#{SERVER_URL}:4200")


  app.listen(8080)

.catch (err) ->
  console.error('SFR MONGO: ', err)
  process.exit(1)
