#!/bin/bash

cd $(dirname $0)/..

bash bin/get_delimination_aoc.sh
bash bin/get_delimination_global_aoc-igp.sh
bash bin/generate_delimitations_html.sh
