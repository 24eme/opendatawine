#!/bin/bash

cd $(dirname $0)/../

if ! which ogr2ogr > /dev/null; then
    echo "ogr2ogr missing (sudo apt install gdal-bin)"
    exit 3
fi

mkdir -p geo/features
cd geo
if ! test -f parcellaire-aoc-shp.zip ; then
    touch -d 1970-01-01 parcellaire-aoc-shp.zip
fi
sha1=$(sha1sum parcellaire-aoc-shp.zip | sed 's/ .*//')
#################################
# Données de https://www.data.gouv.fr/fr/datasets/delimitation-parcellaire-des-aoc-viticoles-de-linao/
#################################
DATAGOUV_DATASET="https://www.data.gouv.fr/datasets/delimitation-parcellaire-des-aoc-viticoles-de-linao"

curl -s "$DATAGOUV_DATASET" > /tmp/inao.html
grep script /tmp/inao.html | sed 's/.*<script type="application.json"[^>]*>//'  | sed 's|</script></body></html>||' | tail -n 1 > /tmp/inao.json
echo -n "[" > /tmp/inao_shape.json ; jq . < /tmp/inao.json | grep -B 1 -A 6 parcellaire-aoc-shp.zip >> /tmp/inao_shape.json ; echo '""]' >> /tmp/inao_shape.json
DATAGOUV_DATAURL=$(jq .[4] < /tmp/inao_shape.json | sed 's/"//g')
DATAGOUV_DATASHA=$(jq .[6] < /tmp/inao_shape.json | sed 's/"//g')
if ! test "$sha1" = "$DATAGOUV_DATASHA" ; then
curl -s -L $DATAGOUV_DATAURL -o parcellaire-aoc-shp.zip
fi
rm /tmp/inao.html /tmp/inao.json /tmp/inao_shape.json

actualsha1=$(sha1sum parcellaire-aoc-shp.zip | sed 's/ .*//')
#echo "SHA1 of downloaded file : "$actualsha1
if ! test "$sha1" = "$actualsha1" || ! test -d "features" ; then
    rm -rf features
    rm -f *delim* output.geojson
    unzip -q parcellaire-aoc-shp.zip || rm parcellaire-aoc-shp.zip
    ogr2ogr -f GeoJSON -t_srs crs:84 output.geojson *.shp
    rm *.shp *.cpg *.prj *.shx *.dbf
    mkdir features
    cat output.geojson | sed 's/{"type": "Feature"/\n{"type": "Feature"/g' | grep '"type": "Feature"' | sed 's/,$//' | split -l 1 --additional-suffix=".geojson" /dev/stdin "features/"
    rm output.geojson
fi
sed -i 's/insee": ["0-9A-]*/insee": "49345"/' $( grep -l 'insee": "49' $( rgrep -l "BELLEVIGNE-EN-LAYON" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "49060"/' $( grep -l 'insee": "49' $( rgrep -l "BELLEVIGNE-LES-CHATEAUX" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "49029"/' $( grep -l 'insee": "49' $( rgrep -l "BLAISON-SAINT-SULPICE" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "49050"/' $( grep -l 'insee": "49' $( rgrep -l "BRISSAC LOIRE AUBANCE" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "49092"/' $( grep -l 'insee": "49' $( rgrep -l "CHEMILLE-EN-ANJOU" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "49125"/' $( grep -l 'insee": "49' $( rgrep -l "DOUE-EN-ANJOU" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "49261"/' $( grep -l 'insee": "49' $( rgrep -l "GENNES-VAL-DE-LOIRE" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "41059"/' $( grep -l 'insee": "41' $( rgrep -l "Le Controis-en-Sologne" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "49373"/' $( grep -l 'insee": "49' $( rgrep -l "LYS-HAUT-LAYON" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "49244"/' $( grep -l 'insee": "49' $( rgrep -l "MAUGES-SUR-LOIRE" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "49194"/' $( grep -l 'insee": "49' $( rgrep -l "MAZE-MILON" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "26001"/' $( grep -l 'insee": "26' $( rgrep -l "SOLAURE EN DIOIS" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "49086"/' $( grep -l 'insee": "49' $( rgrep -l "TERRANJOU" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "79329"/' $( grep -l 'insee": "79' $( rgrep -l "THOUARS" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "49292"/' $( grep -l 'insee": "49' $( rgrep -l "VAL-DU-LAYON" features/ )  )
sed -i 's/insee": ["0-9A-]*/insee": "79063"/' $( grep -l 'insee": "79' $( rgrep -l "VAL EN VIGNES" features/ )  )
sed -i 's/"insee": "ok"/"insee": "34162"/' features/znuy.geojson

cd ..
rm -f iddenom_from_delim-communes.list
rgrep id_denom geo/features/ | sed 's/.*id_denom"://' | sed 's/,.*//' | sort -u | while read iddenom; do
    iddenum_print=$( printf '%05d' $iddenom )
    echo $iddenom >> iddenom_from_delim-communes.list
    find delimitation_aoc/ -name $iddenum_print".geojson" -delete
    rgrep -l '"id_denom": *'$iddenom',' geo/features/ | while read json ; do
        insee=$(cat $json  | sed 's/.*"insee": *"//' | sed 's/".*//' )
        if test "$insee" = '{ '; then
            insee=$(cat $json  | sed 's/.*"insee2011": *"//' | sed 's/".*//' )
            sed -i 's/"insee": null/"insee": "'$insee'"/' $json
        fi
        dep=$(echo $insee | sed 's/...$//')
        mkdir -p "delimitation_aoc/"$dep"/"$insee
        file="delimitation_aoc/"$dep"/"$insee"/"$iddenum_print".geojson"
        if ! test -f $file ; then
            echo '{"type": "FeatureCollection","name": "aoc_geojson","features": [' > $file
            cat $json | jq --compact-output . >> $file
            echo ']}' >> $file
            cat $file | tr -d '\n' > $file".tmp"
            mv -f $file".tmp" $file
        else
            echo '{"type": "FeatureCollection","name": "aoc_geojson","features": ' > $file."tmp"
            cat $file | jq --compact-output .features | sed 's/]$/,/' >> $file".tmp"
            cat $json | jq --compact-output . >> $file".tmp"
            echo ']}' >> $file".tmp"
            cat $file".tmp"  | tr -d '\n' > $file
            rm -f $file".tmp"
        fi
        echo >> $file
    done
done
sort -u iddenom_from_delim-communes.list > iddenom_from_delim-communes.list.tmp
mv iddenom_from_delim-communes.list.tmp iddenom_from_delim-communes.list

