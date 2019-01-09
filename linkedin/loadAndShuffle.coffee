students = require('./students.json')
full = false
randomIdx = -1

getNextCandidate = () ->
  # Find random first candidate without position
  randomIdx = Math.floor(Math.random() * Math.floor(students.length))

  while true
    if (students[randomIdx].id and not students[randomIdx].positions) or (students[randomIdx].id and students[randomIdx].positions[0].linkedinid and not students[randomIdx].positions[0].description)
      break
    randomIdx++
    if randomIdx is students.length
      if full
        console.log("-> FICHIER TERMINE, tout est fini")
        process.exit()
      else
        full = true
        randomIdx = 0

  unless students[randomIdx].id
    console.log("Id de #{JSON.stringify students[randomIdx], null, 2}")
    process.exit()

  students[randomIdx]

storeCandidate = (candidateWithPosition) ->
  students[randomIdx] = candidateWithPosition

print = () ->
  console.log(JSON.stringify students, null, 2)

module.exports =
  getNextCandidate: getNextCandidate
  storeCandidate: storeCandidate
  print: print

unless module.parent
  console.log(getNextCandidate())
