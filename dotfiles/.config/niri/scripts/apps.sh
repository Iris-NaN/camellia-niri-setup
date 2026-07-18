#!/bin/bash

# open site
open_site() {
    local site_name=$1
    url="https://${site_name}.com"


    xdg-open "$url"
}

open_site $1
