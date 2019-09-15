express = require 'express'
mongoClient = require('mongodb').MongoClient
graphqlHTTP = require('express-graphql')
cors = require('cors')
_ = require('lodash')

{ buildSchema } = require('graphql')

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
  listeMatieres: () ->
    catalogue = require('../../formation/catalogue-TC')
    _.map(_.flatten(_.flatten(catalogue[0].semestres)[0].ecs), "detail")

mongoClient.connect 'mongodb://localhost:27017',
  useUnifiedTopology: true
  useNewUrlParser: true
.then (client) ->
  db = client.db('etudiants')

  app = express()
  app.use express.static '/opt/competence/formation'

  app.use '/graphql', cors(), graphqlHTTP(
    schema: schema
    rootValue: queryMap
    graphiql: true
  )

  app.listen(80)

.catch (err) ->
  console.error('SFR MONGO: ', err)
  process.exit(1)
