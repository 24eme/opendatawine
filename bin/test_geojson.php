<?php
include("/home/actualys/odgloire_preprod/project/plugins/acVinParcellairePlugin/lib/vendor/geoPHP/geoPHP.inc");
$geo = file_get_contents($argv[1]);
if (!geoPHP::geosInstalled()) {
	throw new sfException("php-geos needed");
}

$g = geoPHP::load($geo);
$g->area();
$g->intersection($g)->area();

