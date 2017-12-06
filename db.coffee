Promise = require 'bluebird'
mongoose = require 'mongoose'
mongoose.Promise = Promise
Schema = mongoose.Schema

module.exports =

  Semestre: mongoose.model 'Semestre', new mongoose.Schema
    nom: String
    ue:
      type: [
        _id:
          type: Schema.Types.ObjectId
          ref: 'UE'
      ]

  UE: mongoose.model 'UE', new mongoose.Schema
    nom: String
    ec:
      type: [
        _id:
          type: Schema.Types.ObjectId
          ref: 'EC'
      ]

  Enseignant: mongoose.model 'Enseignant', new mongoose.Schema
    nom: String

  EC: mongoose.model 'EC', new mongoose.Schema
    nom: String
    responsable:
      type:
        _id:
          type: Schema.Types.ObjectId
          ref: 'Enseignant'

  NiveauCompetence: mongoose.model 'NiveauCompetence', new mongoose.Schema
    terme:
      type: Schema.Types.ObjectId
      ref: 'Competence'
    ec:
      type: Schema.Types.ObjectId
      ref: 'EC'
    # type:
    #   type: String
    #   enum: ["C", "M"]
    # niveau:
    #   type: Number
    #   enum: [1, 2, 3]
    niveau: String
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
