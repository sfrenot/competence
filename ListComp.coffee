db = require './db'
mongoose = require 'mongoose'
Promise = require 'bluebird'
_ = require 'lodash'

db.connect()
.then () ->
  db.Semestre
  .find()
  .sort "nom"
  .populate
    path: 'ues'
    populate:
      path: 'ecs'
      populate:
        path: 'responsable'
  .exec()
  .then (semestres) ->
    Promise.map semestres, (sem) ->
      Promise.map sem.ues, (ue) ->
        Promise.map ue.ecs, (ec) ->
          db.NiveauCompetence
          .find
            ec: mongoose.Types.ObjectId ec._id
          .populate "terme capacites connaissances"
          .exec()
          .then (comps) ->
            res = "-> #{sem.nom}, #{ue.nom}, #{ec.nom}, #{ec.responsable.nom}\n"
            _.sortBy(comps, ["terme.terme"]).forEach (comp) ->
              res+="#{comp.terme.terme.substring(0, 4)}:#{comp.niveau}\n"
              comp.capacites.forEach (capa) ->
                res+= " Capacite : #{capa.terme}\n"
              comp.connaissances.forEach (conn) ->
                res+= " Connaissance : #{conn.terme}\n"
            res
  .then _.flattenDeep
  .map (res) -> console.log res
.finally () ->
  db.disconnect()
