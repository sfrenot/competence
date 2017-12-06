Promise = require 'bluebird'
mongoose = require 'mongoose'
mongoose.Promise = Promise
Schema = mongoose.Schema

module.exports =
  UE: mongoose.model 'UE', new mongoose.Schema
    nom: String
    ec:
      type: [
        _id:
          type: Schema.Types.ObjectId
          ref: 'EC'
      ]

  EC: mongoose.model 'EC', new mongoose.Schema
    nom: String
    responsable:
      type: Schema.Types.ObjectId
      ref: 'Enseignant'
    niveauCompetence :
      type: [
        _id:
          type: Schema.Types.ObjectId
          ref: 'NiveauCompetence'
      ]

  Enseignant: mongoose.model 'Enseignant', new mongoose.Schema
    nom: String

  NiveauCompetence: mongoose.model 'NiveauCompetence', new mongoose.Schema
    nom:
      type: Schema.Types.ObjectId
      ref: 'Competence'
    type: String   # Ciblé / Mobilisé
    niveau: Number # 1, 2, 3
    capacité:
      type: [
        _id:
          type: Schema.Types.ObjectId
          ref: 'Vocabulaire'
      ]
    connaissance:
      type: Schema.Types.ObjectId
      ref: 'Vocabulaire'

  Competence: mongoose.model 'Competence', new mongoose.Schema
    terme: String

  Vocabulaire: mongoose.model 'Vocabulaire', new mongoose.Schema
    terme: String

  connect: () ->
    new Promise (resolve, reject) ->
      mongoose.connect 'mongodb://localhost/competences', useMongoClient: true
      mongoose.connection.on 'connected', (err) ->
        if (err) then return reject err
        resolve()

  disconnect: () ->
    new Promise (resolve, reject) ->
      mongoose.connection.close (err) ->
        if (err) then return reject err
        resolve()
