#!/bin/sh

git submodule init
git submodule update

cd depends/zoom
git submodule init
git submodule update

cd depends/CocoaGlk
git submodule init
git submodule update
