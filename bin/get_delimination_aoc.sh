#!/bin/bash 

cd $(dirname $0)/../

if ! which ogr2ogr > /dev/null; then
    echo "ogr2ogr missing (sudo apt install gdal-bin)"
    exit 3
fi

mkdir -p geo/features
cd geo
if ! test -f e79a7c68-2fe4-4225-a802-8379a8d6426c.zip ; then
    touch -d 1970-01-01 e79a7c68-2fe4-4225-a802-8379a8d6426c.zip
fi
md5sum=$(md5sum e79a7c68-2fe4-4225-a802-8379a8d6426c.zip)
curl -s -L https://www.data.gouv.fr/fr/datasets/r/e79a7c68-2fe4-4225-a802-8379a8d6426c -o e79a7c68-2fe4-4225-a802-8379a8d6426c.zip -z e79a7c68-2fe4-4225-a802-8379a8d6426c.zip
if ! test "$md5sum" = "$(md5sum e79a7c68-2fe4-4225-a802-8379a8d6426c.zip)" || ! test -d "geo/features" ; then
    rm -rf geo/features
    rm -f *delim_parcellaire_aoc_shp.shp
    unzip -q e79a7c68-2fe4-4225-a802-8379a8d6426c.zip || rm e79a7c68-2fe4-4225-a802-8379a8d6426c.zip
    ogr2ogr -f GeoJSON -t_srs crs:84 output.geojson *delim_parcellaire_aoc_shp.shp
    rm *delim_parcellaire_aoc_shp.shp
    cat output.geojson | jq --compact-output ".features[]" | split -l 1 --additional-suffix=".geojson" /dev/stdin "features/"$i
    rm output.geojson
fi
cd ..

ls geo/features/* | while read feature ; do
    sed 's/.*id_denom"://' $feature  | sed 's/,.*//'
done  | sed 's/,.*//' | sort -u | while read iddenom; do
    iddenum_print=$( printf '%05d' $iddenom )
    rgrep -l '"id_denom":'$iddenom',' geo/features/ | while read json ; do
        insee=$(cat $json  | sed 's/.*"insee":"//' | sed 's/".*//' )
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