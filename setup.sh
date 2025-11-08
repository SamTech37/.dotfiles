#!/bin/bash


# get your favorite tools
apt install -y chewing-editor

# read dconf settings
dconf load /org/gnome/shell/ < dconf-settings.ini

