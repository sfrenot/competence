#!/bin/sh

echo "DPT BS-BB" >catalogues.err; coffee ./crawl.coffee BS BB > catalogue-BB.json 2>>catalogues.err
echo "DPT BS-BIM" >>catalogues.err; coffee ./crawl.coffee BS BIM > catalogue-BIM.json 2>>catalogues.err
echo "DPT GCU" >>catalogues.err; coffee ./crawl.coffee GCU > catalogue-GCU.json 2>>catalogues.err
echo "DPT GE" >>catalogues.err; coffee ./crawl.coffee GE > catalogue-GE.json 2>>catalogues.err
echo "DPT GEN" >>catalogues.err; coffee ./crawl.coffee GEN > catalogue-GEN.json 2>>catalogues.err
echo "DPT GI" >>catalogues.err; coffee ./crawl.coffee GI > catalogue-GI.json 2>>catalogues.err
echo "DPT GM" >>catalogues.err; coffee ./crawl.coffee GM > catalogue-GM.json 2>>catalogues.err
echo "DPT IF" >>catalogues.err; coffee ./crawl.coffee IF > catalogue-IF.json 2>>catalogues.err
echo "DPT SGM" >>catalogues.err; coffee ./crawl.coffee SGM > catalogue-SGM.json 2>>catalogues.err
echo "DPT TC" >>catalogues.err; coffee ./crawl.coffee TC > catalogue-TC.json 2>>catalogues.err
