express = require 'express'
mongoClient = require('mongodb').MongoClient
graphqlHTTP = require('express-graphql')
cors = require('cors')
_ = require('lodash')
session = require('express-session')
CASAuthentication = require 'cas-authentication'

{ buildSchema } = require('graphql')

corsOptions =
  origin: 'http://localhost:4200'
  credentials: true


schema = buildSchema "
  type Etudiant {
    name: String
  }

  type Matiere {
    code: String
  }

  type Query {
    listeEtudiants: [Etudiant],
    listeMatieres: [Matiere]
  }

"

db = ''

queryMap =
  listeEtudiants: () ->
    etudiants = db.collection('etudiants')
    etudiants.find({}).toArray()
  listeMatieres: (express, req) ->
    console.log '->', req.session

    catalogue = require('../../formation/catalogue-TC')
    _.map(_.flatten(_.map(_.flatten(catalogue[0].semestres), "ecs")), "detail")

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
    service_url: 'http://tc405-r004.insa-lyon.fr'


  # app.use cas.block, express.static '/opt/competence/formation'

  app.use '/graphql', cors(corsOptions), cas.block, graphqlHTTP(
    schema: schema
    rootValue: queryMap
    graphiql: true
  )

  app.use '/', cas.bounce, (req, res) -> res.redirect('http://localhost:4200')


  app.listen(80)

.catch (err) ->
  console.error('SFR MONGO: ', err)
  process.exit(1)
