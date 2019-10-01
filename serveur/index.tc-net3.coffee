app = require('express')()
session = require 'express-session'
CASAuthentication = require 'cas-authentication'

#db = require '../db'

#db.connect()
#.then () ->
#  app.listen 80, () ->
#    console.log('Example app listening on port 80!')

app.listen 80

app.use(session(
  secret: '12087371912'
  resave: false
  saveUninitialized : true
))

cas = new CASAuthentication
  cas_url: 'https://login.insa-lyon.fr/cas'
  service_url: 'http://tc-net3.insa-lyon.fr'
  #is_dev_mode: true
  returnTo: '/matrice'

# app.use '/ects', cas.block, require('./ects')
app.use '/matrice', cas.bounce, require('./matrice')
app.use '/', cas.bounce, (req, res) -> res.redirect('/matrice')
