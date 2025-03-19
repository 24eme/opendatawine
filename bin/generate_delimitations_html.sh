#!/bin/bash

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
    grep '";'$denomorig';"' denominations.csv | awk -F ';' '{if ($8 == '$denomorig') print $10";"$11;}' | sed 's/"//g' | awk -F ';' '{dep=substr($1,0,2); print "<tr class=\"ville\"><td>"dep"</td><td><a href=\"../carte.html?insee="$1"&denomid='$denomid'\">"$2"</a></td></tr>"}' >> "denominations/"$denomid".html"
    echo "</table></div></body></html>" >> "denominations/"$denomid".html"
    echo "denominations/"$denomid".html"

    echo -n "{" > "denominations/"$denomid".json"
    grep '";'$denomorig';"' denominations.csv | awk -F ';' '{if ($8 == '$denomorig') print "\""$10"\":\""$11"\",";}' | sed 's/""/"/g' | tr -d '\n' >> "denominations/"$denomid".json"
    sed -i 's/,$/}/' "denominations/"$denomid".json"
done

echo "<html><head><script type='text/javascript' src='web/js/bootstrap.bundle.5.3.0-alpha3.min.js'></script><link rel='stylesheet' type='text/css' media='screen' href='web/css/bootstrap.5.3.0-alpha3.min.css'/><title>Les communes viticoles</title></head><body><h1>Communes ayant des dénominations INAO</h1><ul>" > communes.html
tail -n +2 denominations.csv | awk -F ';' '{print $10";"$11}' | sed 's/"//g' | sort -u | awk -F ';' '{ dep=substr($1,0, 2); print "<li><a href=\"carte.html?insee="$1"\">"$2" ("dep")</a></li>" }' >> communes.html
echo "</ul></div></body></html>" >> communes.html

