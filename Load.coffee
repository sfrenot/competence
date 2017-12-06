db = require './db'
csv = require 'csvtojson'
Promise = require 'bluebird'

allEns = {}
currentSemestre = null
competences = {}
competencesIndices = []

currentUE = null
allUEs = {}

insertMatrice = () ->
  setSemestre = (sem) ->
    if sem is '' then return Promise.resolve()
    db.Semestre.create({nom: sem})
    .then (sem) ->
      currentSemestre = sem

  setUE = (uneUE) ->
    if uneUE is '' then return Promise.resolve()
    db.UE.create({nom: uneUE})
    .then (lue) ->
      currentUE = lue
      currentSemestre.ue.push lue
      currentSemestre.save()

  setEnseignant = (ens) ->
    if allEns[ens]? then return Promise.resolve(allEns[ens])
    db.Enseignant.create({nom: ens})
    .then (res) ->
      allEns[ens] = res
      Promise.resolve(res)

  setECandCompetences = (ens, data) ->
    # name : data.field4
    # C11-15, C21-C29, C31-C37 : data.field8 - data.field28
    # getComp = (field, idx, ec) ->
    #   ec: ec
    #   terme: competencesIndices[idx]
    #   niveau: field

    # console.log "ajout", data.field4,  ens

    db.EC.create({nom: data.field4, responsable: ens})
    .then (res) ->
      console.log "--> Ajouté", res
      Promise.resolve()
      # inserts = []
      #
      # if data.field8 isnt '' then inserts.push(getComp(data.field8, 0, ec))
      # if data.field9 isnt '' then inserts.push(getComp(data.field9, 1, ec))
      # if data.field10 isnt '' then inserts.push(getComp(data.field10, 2, ec))
      # if data.field11 isnt '' then inserts.push(getComp(data.field11, 3, ec))
      # if data.field12 isnt '' then inserts.push(getComp(data.field12, 4, ec))
      # if data.field13 isnt '' then inserts.push(getComp(data.field13, 5, ec))
      # if data.field14 isnt '' then inserts.push(getComp(data.field14, 6, ec))
      # if data.field15 isnt '' then inserts.push(getComp(data.field15, 7, ec))
      # if data.field16 isnt '' then inserts.push(getComp(data.field16, 8, ec))
      # if data.field17 isnt '' then inserts.push(getComp(data.field17, 9, ec))
      # if data.field18 isnt '' then inserts.push(getComp(data.field18, 10, ec))
      # if data.field19 isnt '' then inserts.push(getComp(data.field19, 11, ec))
      # if data.field20 isnt '' then inserts.push(getComp(data.field20, 12, ec))
      # if data.field21 isnt '' then inserts.push(getComp(data.field21, 13, ec))
      # if data.field22 isnt '' then inserts.push(getComp(data.field22, 14, ec))
      # if data.field23 isnt '' then inserts.push(getComp(data.field23, 15, ec))
      # if data.field24 isnt '' then inserts.push(getComp(data.field24, 16, ec))
      # if data.field25 isnt '' then inserts.push(getComp(data.field25, 17, ec))
      # if data.field26 isnt '' then inserts.push(getComp(data.field26, 18, ec))
      # if data.field27 isnt '' then inserts.push(getComp(data.field27, 19, ec))
      # if data.field28 isnt '' then inserts.push(getComp(data.field28, 20, ec))

      # Promise.all inserts, (insert) ->
      #   console.log 'insert', insert


  new Promise (resolve, reject) ->
    done = false

    csv({flatKeys: true, delimiter: ";", noheader: true})
    .fromFile('./TC\ MatriceCompetence\ 2017-11-29.csv')
    .on 'json', (data) ->
      if data.field4 isnt ''
        setSemestre(data.field1)
        .then () ->
          setUE(data.field2)
          .then () ->
            setEnseignant(data.field7)
            .then (ens) ->
              setECandCompetences(ens, data)
              .then () ->
                if done then resolve()

    .on 'done', (error) ->
      if error then return reject error
      done = true


db.connect()
.then () ->
  Promise.all [
    db.Competence.remove({}).exec()
    db.Semestre.remove({}).exec()
    db.UE.remove({}).exec()
    db.Enseignant.remove({}).exec()
    db.EC.remove({}).exec()
    db.NiveauCompetence.remove({}).exec()
    db.Vocabulaire.remove({}).exec()
  ]
  .then () ->
    a = require './Competences.json'
    Promise.map a, (elem) ->
      db.Competence.create({terme: elem})
      .then (a) ->
        competences[elem] = a
        competencesIndices.push a
        Promise.resolve()
    .then () ->
      insertMatrice()




    # new Promise (resolve, reject) ->
    #   csv({flatKeys: true, delimiter: ";", noheader: true})
    #   .fromFile('./TC DetailCompetences 2017-12-04.csv')
    #   .on 'json', (data) ->
    #     switch data.field1
    #       when ''
    #         console.log 'Non Matiere'
    #       else
    #         console.log "Matiere", data.field1
    #     # db.Competence.push data
    #   .on 'done', (error) ->
    #     if error then return reject error
    #     resolve competences

.catch (err) ->
  console.log("erreur", err)
# .finally () ->
#   db.disconnect()
