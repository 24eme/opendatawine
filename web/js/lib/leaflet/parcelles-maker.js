var parcellesStr = window.parcelles;
var delimitationStr = window.delimitation;
var allIdu = window.all_idu;
var parcelleSelected = null;
var minZoom = 17;

function parseString(dlmString){
    var mydlm = [];
    dlmString.split("|").forEach(function(str){
        mydlm.push(JSON.parse(str));
    });
    return mydlm;
}

var map = L.map('map');
map.on('click', function(e) { if(e.target && e.target.feature) { return; } clearParcelleSelected() });

L.tileLayer('https://wxs.ign.fr/{ignApiKey}/geoportail/wmts?'+
        '&REQUEST=GetTile&SERVICE=WMTS&VERSION=1.0.0&TILEMATRIXSET=PM'+
        '&LAYER={ignLayer}&STYLE={style}&FORMAT={format}'+
        '&TILECOL={x}&TILEROW={y}&TILEMATRIX={z}',
        {
          ignApiKey: 'pratique',
          ignLayer: 'ORTHOIMAGERY.ORTHOPHOTOS',
          style: 'normal',
          format: 'image/jpeg',
          service: 'WMTS',
    maxZoom: 19,
    attribution: 'Map data &copy;' +
        '<a href="https://www.24eme.fr/">24eme Société coopérative</a>, ' +
        '<a href="https://cadastre.data.gouv.fr/">Cadastre</a>, ' +
        'Imagery © <a href="https://www.ign.fr/">IGN</a>',
    id: 'mapbox.light'
}).addTo(map);

/***** Location position ****/

$('#locate-position').on('click', function(){
    map.locate({setView: true});
});

var icon = L.divIcon({className: 'glyphicon glyphicon-record'});

function onLocationFound(e) {
    var radius = e.accuracy / 100;
    L.marker(e.latlng,{icon: icon}).addTo(map);
    L.circle(e.latlng, radius).addTo(map);
    map.setView(e.latlng, minZoom);
}
function onLocationError(e) {
    alert("Vous n'êtes actuellement pas localisable. Veuillez activer la localisation.");
}

map.on('locationfound', onLocationFound);

map.on('locationerror', onLocationError);

/****** End location position *****/

/**
* Css style for parcelles according product color ie "Côtes de Provence Rouge GRENACHE"
* Color will be Red
**/

function style(feature) {
    var color;
    color = getColor(feature.properties.parcellaires['0'].Produit);
    return {
        fillColor: '#fff',
        weight: 2,
        opacity: 1,
        color: 'red',
        fillOpacity: 0.3
    };
}

/**
* Css style default
**/
function styleDelimitation(color, opacity){
    return {
        fillColor: color,
        weight: 0,
        opacity: opacity,
        dashArray: '5',
        color: 'black',
        fillOpacity: 0.4
    }
}

function zoomOnMap(){
    map.fitBounds(layers[parcelles_name].getBounds());
    clearParcelleSelected()
}


zoomOnMap();


map.on('zoomend', function() {
    if (map.getZoom() > 15){
        $('.parcellelabel').show();
        $('.sectionlabel').hide();
    } else {
        $('.parcellelabel').hide();
        $('.sectionlabel').show();
    }
});
$('.parcellelabel').hide();
$('.sectionlabel').show();

function zoomToFeature(e) {
  zoomToParcelle(e.target);
  e.preventDefault();
}

function zoomToParcelle(layer) {
  clearParcelleSelected();
  map.fitBounds(layer.getBounds());
  parcelleSelected = layer;
  info.update(layer);
}

function clearParcelleSelected() {
  if(!parcelleSelected) {
    return;
  }
  parcelleSelected.setStyle(style(parcelleSelected.feature));
  parcelleSelected = null;
  info.update(null);
}

var info = L.control();

info.onAdd = function (map) {
    this._div = L.DomUtil.create('div', 'info'); // create a div with a class "info"
    this._div.style.display = 'none';
    this.update();
    return this._div;
};

/*
* filter tab after page load (when all ready)
* check parcelles which there aren't data geojson and put message not-found
*/
$(document).ready(function(){
})

