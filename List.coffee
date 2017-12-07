db = require './db'
mongoose = require 'mongoose'


db.connect()
.then () ->
  db.Semestre
  .find()
  .sort({nom:1})
  .populate
    path: 'ues'
    populate:
      path: 'ecs'
      populate:
        path: 'responsable'
  .exec()
  .then (semestres) ->
    semestres.forEach (sem) ->
      sem.ues.forEach (ue) ->
        ue.ecs.forEach (ec) ->
          db.NiveauCompetence
          .find
            ec: mongoose.Types.ObjectId("5a290e970907939265931dd8")
          .exec()
          .then (comps) ->
            console.log "-> #{sem.nom}, #{ue.nom}, #{ec.nom}, #{ec.responsable.nom}"
.finally () ->
  db.disconnect()
