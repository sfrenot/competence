app = require('express')()
db = require '../db'

app.use '/ects', require('./ects')
app.use '/', require('./root')

db.connect()
.then () ->
  app.listen 3000, () ->
    console.log('Example app listening on port 3000!')
