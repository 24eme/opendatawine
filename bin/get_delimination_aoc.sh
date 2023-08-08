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
sha1=$(sha1sum parcellaire-aoc-shp.zip)
#################################
# Données de https://www.data.gouv.fr/fr/datasets/delimitation-parcellaire-des-aoc-viticoles-de-linao/
#################################
if ! test $sha1 = $( curl -s https://www.data.gouv.fr/fr/datasets/delimitation-parcellaire-des-aoc-viticoles-de-linao/ | grep -A 30 parcellaire-aoc-shp.zip | grep -A 6 sha1 | tail -n 1 | awk '{print $1"  parcellaire-aoc-shp.zip"}' ) ; then
curl -s -L $( curl -s https://www.data.gouv.fr/fr/datasets/delimitation-parcellaire-des-aoc-viticoles-de-linao/ | grep -A 30 parcellaire-aoc-shp.zip  | grep -B 1 Télécharger | grep href | awk -F '"' '{print $2}' ) -o parcellaire-aoc-shp.zip -z parcellaire-aoc-shp.zip
fi
actualsha1=$(sha1sum parcellaire-aoc-shp.zip)
echo "SHA1 of downloaded file : "$actualsha1
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

rgrep id_denom geo/features/ | sed 's/.*id_denom"://' | sed 's/,.*//' | sort -u | while read iddenom; do
    iddenum_print=$( printf '%05d' $iddenom )
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
cat $(find delimitation_aoc/ -name delimitations.json) | grep '^"' | sort -u | sed 's/.geojson//' | awk -F '"' '{print $4";"$2}' | while read line; do
    denomid=$(echo $line| sed 's/;.*//')
    denomination=$(echo $line| sed 's/.*;//')
    find delimitation_aoc -name $denomid".geojson"  | while read file ; do
    cat $file | jq -c .features[0].properties | sed 's/\\"//g' | sed 's/;/ /g' | jq  -c '[.dt,.type_prod,.categorie,.type_denom,.type_ig,.id_app,.app,.id_denom,.denom,.insee,.nomcom,.insee2011,.nomcom2011,.id_aire,.crinao,.grp_name1,.grp_name2]' | sed 's/]$//' | awk -F '"' 'BEGIN{OFS = "\"" ;} { gsub(",", " -@- ", $4); gsub(",", " -@- ", $6); gsub(",", " -@- ", $8); gsub(",", " -@- ", $10); gsub(",", " -@- ", $22); gsub(",", " -@- ", $24); gsub(",", " -@- ", $26); gsub(",", "|", $14); gsub(",", "|", $16); gsub(",", "|", $18); gsub(",", "|", $20); print $0}' | sed 's/,null/,/g' | sed 's/^\[//' | sed 's/"*$//' | sed 's/,/;/g' | sed 's/ -@- /,/g' >> denominations.csv
    done
done

echo "<html><head><script type='text/javascript' src='web/js/bootstrap.bundle.5.3.0-alpha3.min.js'></script><link rel='stylesheet' type='text/css' media='screen' href='web/css/bootstrap.5.3.0-alpha3.min.css'/><title>Les délimitations INAO</title></head><body><div class='container'><h1>Dénominations INAO</h1><ul>" > denominations.html
tail -n +2 denominations.csv | sed 's/"//g' | awk -F ';' '{print $8";"$9}' | sort -u | awk -F ';' '{printf("<li><a href=\"denominations/%05d.html\">%s</a></li>\n", $1, $2);}' >> denominations.html
echo "</ul></div></body></html>" >> denominations.html

tail -n +2 denominations.csv | awk -F ';' '{print $8";"$9}' | sed 's/"//g' | sort -u | awk -F ';' '{printf("%05d;%s\n", $1, $2);}' | sed 's/"//g' | while read line ; do
    denomid=$(echo $line | sed 's/;.*//')
    denomination=$(echo $line | sed 's/.*;//')
    denomorig=$(echo $denomid | sed 's/^0*//')

    echo "<html><head><script type='text/javascript' src='../web/js/bootstrap.bundle.5.3.0-alpha3.min.js'></script><link rel='stylesheet' type='text/css' media='screen' href='../web/css/bootstrap.5.3.0-alpha3.min.css'/><title>Les communes de la dénomination "$denomination"</title></head><body><div class='container'><h1>"$denomination"</h1><p>Liste des villes:</p><table>" > "denominations/"$denomid".html"
    grep '";'$denomorig';"' denominations.csv | awk -F ';' '{if ($8 = '$denomorig') print $10";"$11;}' | sed 's/"//g' | awk -F ';' '{dep=substr($1,0,2); print "<tr class=\"ville\"><td>"dep"</td><td><a href=\"../carte.html?insee="$1"&denomid='$denomid'\">"$2"</a></td></tr>"}' >> "denominations/"$denomid".html"
    echo "</table></div></body></html>" >> "denominations/"$denomid".html"
    echo "denominations/"$denomid".html"

    echo -n "[" > "denominations/"$denomid".json"
    grep '";'$denomorig';"' denominations.csv | awk -F ';' '{if ($8 = '$denomorig') print $10",";}' | sed 's/"//g' | tr -d '\n' >> "denominations/"$denomid".json"
    sed -i 's/,$/]/' "denominations/"$denomid".json"
done

echo "<html><head><script type='text/javascript' src='web/js/bootstrap.bundle.5.3.0-alpha3.min.js'></script><link rel='stylesheet' type='text/css' media='screen' href='web/css/bootstrap.5.3.0-alpha3.min.css'/><title>Les communes viticoles</title></head><body><h1>Communes ayant des dénominations INAO</h1><ul>" > communes.html
tail -n +2 denominations.csv | awk -F ';' '{print $10";"$11}' | sed 's/"//g' | sort -u | awk -F ';' '{ dep=substr($1,0, 2); print "<li><a href=\"carte.html?insee="$1"\">"$2" ("dep")</a></li>" }' >> communes.html
echo "</ul></div></body></html>" >> communes.html

