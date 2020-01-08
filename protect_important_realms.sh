#!/bin/bash

if [[ ("$realm" == "prod" || "$realm" == "ops") && -z "$force" ]]; then
    echo "Important realm protection activated."
    read -p "Are you sure you want to do this to the realm '$realm'? " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
