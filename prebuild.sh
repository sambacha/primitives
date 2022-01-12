#!/bin/bash

bundle update

rm -rf _sass/lib && mkdir -p _sass/lib

mkdir -p _sass/lib/@primer/css
mkdir -p _sass/lib/font-awesome
mkdir -p _sass/lib/rouge
mkdir -p _sass/lib/material-design-lite

# @primer/css
cp -r node_modules/@primer/css/support    _sass/lib/@primer/css
cp -r node_modules/@primer/css/base       _sass/lib/@primer/css
cp -r node_modules/@primer/css/breadcrumb _sass/lib/@primer/css
cp -r node_modules/@primer/css/buttons    _sass/lib/@primer/css
cp -r node_modules/@primer/css/forms      _sass/lib/@primer/css
cp -r node_modules/@primer/css/loaders    _sass/lib/@primer/css
cp -r node_modules/@primer/css/markdown   _sass/lib/@primer/css
cp -r node_modules/@primer/css/utilities  _sass/lib/@primer/css
