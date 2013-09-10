#!/bin/sh

if [[ -z "$1" ]] 
then
	curl http://doi:42026/metadata.html
else
	curl -o $1 http://doi:42026/metadata.html
fi

