#!/bin/bash 

cd $(dirname $0)/../

if ! which ogr2ogr > /dev/null; then
    echo "ogr2ogr missing (sudo apt install gdal-bin)"
    exit 3
fi

rm -rf geo/*
mkdir -p geo/features
cd geo
curl -s -L https://www.data.gouv.fr/fr/datasets/r/e79a7c68-2fe4-4225-a802-8379a8d6426c > e79a7c68-2fe4-4225-a802-8379a8d6426c.zip
unzip -q e79a7c68-2fe4-4225-a802-8379a8d6426c.zip 
ogr2ogr -f GeoJSON -t_srs crs:84 output.geojson *delim_parcellaire_aoc_shp.shp
rm *delim_parcellaire_aoc_shp.shp
cat output.geojson | jq --compact-output ".features[]" | split -l 1 --additional-suffix=".geojson" /dev/stdin "features/"$i
rm output.geojson
cd ..

ls geo/features/* | while read feature ; do
    sed 's/.*id_denom"://' $feature  | sed 's/,.*//'
done  | sed 's/,.*//' | sort -u | while read iddenom; do
    iddenum_print=$( printf '%05d' $iddenom )
    rgrep -l '"id_denom":'$iddenom',' geo/features/ | while read json ; do
        insee=$(jq .properties.insee $json | sed 's/"//g')
        dep=$(echo $insee | sed 's/...$//')
        mkdir -p "delimitation_aoc/"$dep"/"$insee
        file="delimitation_aoc/"$dep"/"$insee"/"$iddenum_print".geojson"
        echo '{"type": "FeatureCollection","name": "aoc_geojson","features": [' > $file
        cat $json >> $file
        echo ']}' >> $file
        cat $file | tr -d '\n' > $file".tmp"
        mv $file".tmp" $file
        echo >> $file
    done
done