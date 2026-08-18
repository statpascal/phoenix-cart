#!/bin/bash
mogrify -format pbm -background "#ffffff" -alpha remove *.png
