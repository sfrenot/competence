unless process.argv[2]?
  console.log "Lancement : coffee ./extractVol <fichierVol.json>"
  process.exit(0)

courses = require process.argv[2]

split = (vol) ->
  return vol.split('.0 h')[0]

courses.forEach (departement) ->
  departement.semestres.forEach (semestre) ->
    semestre.ecs.forEach (ec) ->
      if not ec.detail.code.startsWith("HU")
        console.log "#{ec.detail.code}; #{ec.detail.nom}; #{ec.UE}"
      #console.log "#{ec.detail.code},#{split(ec.detail.cours)},\
        #{split(ec.detail.td)},#{split(ec.detail.tp)},\
        #{split(ec.detail.projet)}"
