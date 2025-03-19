#!/bin/bash

cd $(dirname $0)/

bash get_delimination_aoc.sh
bash get_delimination_global_aoc-igp.sh
bash generate_delimitations_html.sh
