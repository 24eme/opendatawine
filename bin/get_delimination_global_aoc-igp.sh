#!/bin/bash

cd $(dirname $0)/../

if ! which ogr2ogr > /dev/null; then
    echo "ogr2ogr missing (sudo apt install gdal-bin)"
    exit 3
fi

mkdir -p geo-aire-geographique/features
cd geo-aire-geographique
if ! test -f parcellaire-delim-aire-geographique-shp.zip ; then
    touch -d 1970-01-01 parcellaire-aoc-shp.zip
fi
sha1=$(sha1sum parcellaire-delim-aire-geographique-shp.zip)
#################################
# Données de https://www.data.gouv.fr/fr/datasets/delimitation-des-aires-geographiques-des-siqo/
#################################
if ! test "$sha1" = "$( curl -s https://www.data.gouv.fr/fr/datasets/delimitation-des-aires-geographiques-des-siqo/ | grep -A 30 delim-aire-geographique-shp.zip | grep -A 6 sha1 | head -n 7 | tail -n 1 | awk '{print $1"  parcellaire-aoc-shp.zip"}' )" ; then
	curl -s -L $( curl -s https://www.data.gouv.fr/fr/datasets/delimitation-des-aires-geographiques-des-siqo/ | grep -A 30 delim-aire-geographique-shp.zip | grep -B 5 Télécharger | grep href | awk -F '"' '{print $2}' ) -o parcellaire-delim-aire-geographique-shp.zip -z parcellaire-delim-aire-geographique-shp.zip
fi

actualsha1=$(sha1sum parcellaire-delim-aire-geographique-shp.zip)
echo "SHA1 of downloaded file : "$actualsha1
if ! test "$sha1" = "$actualsha1" || ! test -d "features" ; then
    rm -rf features
    rm -f output.geojson 20*delim*
    unzip -q parcellaire-delim-aire-geographique-shp.zip || rm parcellaire-delim-aire-geographique-shp.zip
    ogr2ogr -f GeoJSON -t_srs crs:84 output.geojson *.shp
    rm *.shp *.cpg *.prj *.shx *.dbf
    mkdir features
    cat output.geojson | sed 's/{"type": "Feature"/\n{"type": "Feature"/g' | grep '"type": "Feature"' | sed 's/,$//' | split -l 1 --additional-suffix=".geojson" /dev/stdin "features/"
    rm output.geojson
fi

if ! test -s comagri-communes-aires-ao.csv ; then
        curl -s -L $( curl -s https://www.data.gouv.fr/fr/datasets/aires-geographiques-des-aoc-aop/ | grep -A 30 comagri-communes-aires-ao.csv | grep -B 5 Télécharger | grep href | awk -F '"' '{print $2}' ) -o comagri-communes-aires-ao.csv
fi

cd ..

rgrep -H id_denom geo-aire-geographique/features/ | sed 's/:.*id_denom"://' | sed 's/,.*//' | while read json iddenom; do
        if ! grep '^'$iddenom'$' iddenom_from_delim-communes.list > /dev/null && jq .properties.categorie $json | grep Vin > /dev/null ; then
		grep -a "$( jq .properties.denom $json | sed 's/"//g' )" geo-aire-geographique/comagri-communes-aires-ao.csv  | awk -F ';' '{print $1}' | while read insee ; do
			dep=$(echo $insee | sed 's/...$//')
			iddenum_print=$(printf '%05d' $iddenom)
			mkdir -p delimitation_aoc/$dep/$insee
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
	fi
done
