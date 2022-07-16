#!/usr/bin/env bash

case $1 in
	'-h'|'--help')
		printf 'Usage:       scripts/make-html.sh
Description: Makes the HTML header and footer stored in make/html awk variables
Variables:   NONE
Note:        Make sure to call this script from the repository root
'
		exit 1
		;;
esac

HTML_FILES=("make/html/header.txt" "make/html/footer.txt")

# Script message
echo '[ .. ] Making HTML header and footer'

# Info message
# echo "[ INFO ] "

# Script body
file=
for html_file in ${HTML_FILES[@]}
do
	var_name=${html_file##*/}
	var_name=${var_name%.*}
	var_name="HTML_${var_name^^}"
	file+="${var_name}=\"$(sed\
		-e 's/["#]/\\&/g'\
		-e 's/$/\\n\\/g'\
		-e 's/^\n\\/\\n/g' \
		$html_file)
\"
"
done

echo "$file" > make/Html.mk

echo '[ OK ] Done'
