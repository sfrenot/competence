XLSX = require('xlsx')
fs = require('fs')

workbook = XLSX.readFile('ge.xlsx')

for sheetName in workbook.SheetNames
  fs.writeFileSync("#{sheetName}.csv", XLSX.utils.sheet_to_csv(workbook.Sheets[sheetName]))
