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
if ! test "$md5sum" = "$(md5sum e79a7c68-2fe4-4225-a802-8379a8d6426c.zip)" || ! test -d "features" ; then
    rm -rf features
    rm -f *delim* output.geojson
    unzip -q e79a7c68-2fe4-4225-a802-8379a8d6426c.zip || rm e79a7c68-2fe4-4225-a802-8379a8d6426c.zip
    ogr2ogr -f GeoJSON -t_srs crs:84 output.geojson *.shp
    rm *.shp *.cpg *.prj *.shx
    cat output.geojson | sed 's/{"type": "Feature"/\n{"type": "Feature"/g' | grep '"type": "Feature"' | sed 's/,$//' | split -l 1 --additional-suffix=".geojson" /dev/stdin "features/"
    rm output.geojson
fi
cd ..

sed -i 's/"insee": "ok"/"insee": "34162"/' geo/features/znuy.geojson

rgrep id_denom geo/features/ | sed 's/.*id_denom"://' | sed 's/,.*//' | sort -u | while read iddenom; do
    iddenum_print=$( printf '%05d' $iddenom )
    rgrep -l '"id_denom": *'$iddenom',' geo/features/ | while read json ; do
        insee=$(cat $json  | sed 's/.*"insee": *"//' | sed 's/".*//' )
        if test "$insee" = '{ '; then
            insee=$(cat $json  | sed 's/.*"insee2011": *"//' | sed 's/".*//' )
            sed -i 's/"insee": null/"insee": "'$insee'"/' $json
        fi
        dep=$(echo $insee | sed 's/...$//')
        mkdir -p "delimitation_aoc/"$dep"/"$insee
        file="delimitation_aoc/"$dep"/"$insee"/"$iddenum_print".geojson"
        echo '{"type": "FeatureCollection","name": "aoc_geojson","features": [' > $file
        cat $json | jq --compact-output . >> $file
        echo ']}' >> $file
        cat $file | tr -d '\n' > $file".tmp"
        mv -f $file".tmp" $file
        echo >> $file
    done
done

ls -d delimitation_aoc/*/*/ | while read villedir ; do
    commune=$(echo $villedir | awk -F '/' '{print $3}')
    departement=$(echo $villedir | awk -F '/' '{print $2}')
    cd $villedir;
    echo '{' > delimitations.json
    ls *geojson | while read geojson; do
        echo -n '"';
        sed 's/.*"denom":"//' $geojson | sed 's/".*//' | tr -d '\n';
        echo -n '":"';
        printf "%05d.geojson\"," $(sed 's/.*"id_denom"://' $geojson | sed 's/,.*//');
        echo
    done >> delimitations.json
    sed -i '$ s/,$//' delimitations.json
    echo '}' >> delimitations.json
    curl -s "https://cadastre.data.gouv.fr/data/etalab-cadastre/latest/geojson/communes/"$departement"/"$commune"/cadastre-"$commune"-parcelles.json.gz" | zcat > cadastre-parcelles.json
    cd - > /dev/null
done

echo "dt;type_prod;categorie;type_denom;type_ig;id_app;app;id_denom;denom;insee;nomcom;insee2011;nomcom2011;id_aire;crinao;grp_name1;grp_name2" > denominations.csv
cat $(find delimitation_aoc/ -name denominations.json) | grep '^"' | sort -u | sed 's/.geojson//' | awk -F '"' '{print $4";"$2}' | while read line; do
    denomid=$(echo $line| sed 's/;.*//')
    denomination=$(echo $line| sed 's/.*;//')
    find delimitation_aoc -name $denomid".geojson"  | while read file ; do
        jq -c .features[0].properties < $file | sed 's/\\"//g' | sed 's/,[^:,]*:/:/g' | sed 's/}/:/' | awk -F ':' '{print $2";"$3";"$4";"$5";"$6";"$7";"$8";"$9";"$10";"$11";"$12";"$13";"$14";"$15";"$16";"$17";"$18}' >> denominations.csv
    done
done
echo "<html><body><h1>Dénominations INAO</h1><ul>" > denominations.html
tail -n +2 denominations.csv | sed 's/"//g' | awk -F ';' '{print $8";"$9}' | sort -u | awk -F ';' '{printf("<li><a href=\"denominations/%05d.html\">%s</a></li>\n", $1, $2);}' >> denominations.html
echo "</ul></body></html>" >> denominations.html

tail -n +2 denominations.csv | awk -F ';' '{print $8";"$9}' | sort -u | awk -F ';' '{printf("%05d;%s\n", $1, $2);}' | sed 's/"//g' | while read line ; do
    denomid=$(echo $line | sed 's/;.*//')
    denomination=$(echo $line | sed 's/.*;//')
    echo "<html><body><h1>"$denomination"</h1><p>Liste des villes:</p><table>" > "denominations/"$denomid".html"
    echo -n "[" > "denominations/"$denomid".json"
    find . -name $denomid'.geojson' | while read geo ; do
        cat $geo | sed 's/.*"insee"://' | sed 's/insee2011".*//' | awk -F '"' '{dep=substr($2,0,2); print "<tr class=\"ville\"><td>"dep"</td><td><a href=\"../carte.html?insee="$2"&denomid='$denomid'\">"$6"</a></td></tr>"}'
        cat $geo | sed 's/.*"insee"://' | sed 's/insee2011".*//' | awk -F '"' '{print $2","}' | tr -d '\n' >> "denominations/"$denomid".json"
    done >> "denominations/"$denomid".html"
    sed -i 's/,$/]/' "denominations/"$denomid".json"
    echo "</table></body></html>" >> "denominations/"$denomid".html"
    echo "denominations/"$denomid".html"
done

echo "<html><body><h1>Communes ayant des dénominations INAO</h1><ul>" > communes.html
tail -n +2 denominations.csv | awk -F ';' '{print $10";"$11}' | sed 's/"//g' | sort -u | awk -F ';' '{ dep=substr($1,0, 2); print "<li><a href=\"carte.html?insee="$1"\">"$2" ("dep")</a></li>" }' >> communes.html
echo "</ul></body></html>" >> communes.html

