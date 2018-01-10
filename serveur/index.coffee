app = require('express')()
session = require 'express-session'
CASAuthentication = require 'cas-authentication'

db = require '../db'

db.connect()
.then () ->
  app.listen 3000, () ->
    console.log('Example app listening on port 3000!')

app.use(session(
  secret: '12087371912'
  resave: false
  saveUninitialized : true
))

casStrategy = require('passport-cas').Strategy
cas = new CASAuthentication
  cas_url: 'https://login.insa-lyon.fr/cas'
  service_url: 'http://jumplyn.com:3000/'

app.use '/ects', cas.block, require('./ects')
app.use '/', cas.bounce, require('./root')
