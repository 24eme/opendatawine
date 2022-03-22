#!/bin/bash 

cd $(dirname $0)/../

PRODOUANE_NO_WWWDATA=true

if ! which ogr2ogr > /dev/null; then
    echo "ogr2ogr missing (sudo apt install gdal-bin)"
    exit 3
fi

. bin/common.inc

rm -rf geo/*
mkdir -p geo/features
cd geo
curl -s -L https://www.data.gouv.fr/fr/datasets/r/e79a7c68-2fe4-4225-a802-8379a8d6426c > e79a7c68-2fe4-4225-a802-8379a8d6426c.zip
unzip -q e79a7c68-2fe4-4225-a802-8379a8d6426c.zip 
ogr2ogr -f GeoJSON -t_srs crs:84 output.geojson *delim_parcellaire_aoc_shp.shp
cat output.geojson | jq --compact-output ".features[]" | split -l 1 --additional-suffix=".geojson" /dev/stdin "features/"$i
cd ..
rm -rf communes
mkdir -p communes
rgrep -l '"id_denom":'$INAO_ID_DENOM',' geo/features/ | while read json ; do
    insee=$(jq .properties.insee $json | sed 's/"//g')
    echo '{"type": "FeatureCollection","name": "aoc_geojson","crs": {"type": "name","properties": {"name": "urn:ogc:def:crs:EPSG::2154"}},"features": [' > "communes/delimitation-"$insee".json"
    cat $json >> "communes/delimitation-"$insee".json"
    echo ']}' >> "communes/delimitation-"$insee".json"
done
ls communes | grep json > communes/communes.list
