#!/bin/bash
clear


echo "--> Validating inx files with xmllint. Only errors are printed to console"
for folder in */ ; do 
	xmllint --noout --relaxng ./inkscape.extension.rng ${folder}*.inx > /dev/null 2>> 000_xmllint.out
done
grep -v "validates\|warning: failed to load external entity" 000_xmllint.out; rm 000_xmllint.out


#complete set of meta information
AGGLOMERATED_JSON=""
for folder in */ ; do 
	if [[ ! -f "${folder}meta.json" ]]; then
    	echo "meta.json missing for ${folder}"
	else
	    JSON_OKAY=$(jq -e . ${folder}meta.json)
	    if [ $? -eq 0 ]; then
    		echo ${AGGLOMERATED_JSON} > /tmp/prevJson
    		AGGLOMERATED_JSON=$(jq -s ".[0] + .[1]" /tmp/prevJson ${folder}meta.json)
        else
            echo Format error in ${folder}meta.json
        fi
		#DEBUG
		#cat ${folder}meta.json | jq
	fi
done
#print overall json
#echo $AGGLOMERATED_JSON | jq


echo "--> Show unique license kinds used:"
echo $AGGLOMERATED_JSON | jq -r '.[]|{license}|.[]' | sort | uniq -c


echo "--> show unique list of involved contributors (thanks/credits):"
#echo $AGGLOMERATED_JSON | jq -r '.[]|{main_authors}|.[]|.[]' | sort | uniq -c
echo $AGGLOMERATED_JSON | jq -r '.[]|{main_authors}|.[]|.[]' | sort | uniq


#show extensions which are in gallery
GALLERY_EXTENSIONS=$(echo $AGGLOMERATED_JSON | jq -r '.[]|{inkscape_gallery_url}|.[]' | sort | grep -v "null")
for GALLERY_EXTENSION in ${GALLERY_EXTENSIONS}; do
	EXTENSION=$(echo ${AGGLOMERATED_JSON} | jq -r '.[]|select(.inkscape_gallery_url=="'$GALLERY_EXTENSION'")|{name}|.[]')
done


echo "--> Count of inx files:"
INX=$(find ./ -type f -name "*.inx" | wc -l)
echo INX: $INX


echo "--> Count of extension folders:"
FOLDERS=$(ls -d */ | wc -l)
echo FOLDERS: $FOLDERS


README="../../README.md"
#replace values in README.md
sed -i 's/\*\*.* extension folders\*\*/\*\*'${FOLDERS}' extension folders\*\*/g' ${README}
sed -i 's/\*\* with .* \.inx files\*\*/\*\* with \*\*'${INX}' \.inx files\*\*/g' ${README}


echo "Removing unrequired pyc cache files"
find . -type d -name "__pycache__" -exec rm -rf {} \; > /dev/null


read -p "Build local gallery extension zip files?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Building extension zip files for zipmirror"
    TARGETDIR="../../../mightyscape-1.X-zipmirror"
    mkdir -p $TARGETDIR > /dev/null 2>&1
    
    for EXTENSION in */; do
        EXTENSION="${EXTENSION%/}" #strip trailing slash
        EXTRA=""
        if [[ $EXTENSION == "styles_to_layers" ]] || [[  $EXTENSION == "ungrouper_and_element_migrator_filter" ]] || [[  $EXTENSION == "epilog_dashboard_bbox_adjust" ]]; then
            EXTRA="${EXTRA} apply_transformations/"
                elif [[ $EXTENSION == "styles_to_layers" ]] || [[  $EXTENSION == "ungrouper_and_element_migrator_filter" ]]; then
                EXTRA="${EXTRA} remove_empty_groups/"
            fi
            ZIPFILE=$TARGETDIR/$EXTENSION.zip
        zip -ru $ZIPFILE $EXTENSION/ 000_about_fablabchemnitz.svg $EXTRA > /dev/null 2>&1
        echo "--> creating/updating $ZIPFILE"
    done
fi


read -p "Build local gallery extension zip files?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Building Inkscape gallery extension zip files"
    TARGETDIR="../000_Inkscape_Gallery"
    mkdir -p $TARGETDIR > /dev/null 2>&1
 
	#show extensions which are in gallery
	GALLERY_EXTENSIONS=$(echo $AGGLOMERATED_JSON | jq -r '.[]|{inkscape_gallery_url}|.[]' | sort | grep -v "null")
	for GALLERY_EXTENSION in ${GALLERY_EXTENSIONS}; do
		EXTENSION="$(echo ${AGGLOMERATED_JSON} | jq -r '.[]|select(.inkscape_gallery_url=="'$GALLERY_EXTENSION'")|{path}|.[]')"
    	EXTRA=""
    	if [[ $EXTENSION == "styles_to_layers" ]] || [[  $EXTENSION == "ungrouper_and_element_migrator_filter" ]] || [[  $EXTENSION == "epilog_dashboard_bbox_adjust" ]]; then
    		EXTRA="${EXTRA} apply_transformations/"
  		 	elif [[ $EXTENSION == "styles_to_layers" ]] || [[  $EXTENSION == "ungrouper_and_element_migrator_filter" ]]; then
  	  		EXTRA="${EXTRA} remove_empty_groups/"
  	  	fi
  	    ZIPFILE=$TARGETDIR/$EXTENSION.zip
    	rm $ZIPFILE > /dev/null 2>&1
		echo "--> creating $ZIPFILE"
    	zip -ru $ZIPFILE $EXTENSION/ 000_about_fablabchemnitz.svg $EXTRA
	done
fi
