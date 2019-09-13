express = require 'express'
mongoClient = require('mongodb').MongoClient
graphqlHTTP = require('express-graphql')
{ buildSchema } = require('graphql')

schema = buildSchema "
  type Etudiant {
    name: String
  }

  type Query {
    listeEtudiants: [Etudiant]
  }
"

queryMap =
  listeEtudiants: () -> [{name:'hello World'}]

mongoClient.connect 'mongodb://localhost:27017',
  useUnifiedTopology: true
  useNewUrlParser: true
.then (client) ->
  db = client.db('etudiants')

  app = express()
  app.use express.static '/opt/competence/formation'

  app.use '/graphql', graphqlHTTP(
    schema: schema
    rootValue: queryMap
    graphiql: true
  )

  app.listen(80)

  # etudiants = db.collection('etudiants')
  # etudiants.find({}).toArray()
  # .then (docs) ->
  #   console.log('->', docs)

.catch (err) ->
  console.error('SFR MONGO: ', err)
  process.exit(1)
