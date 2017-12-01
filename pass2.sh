



target_file=$( sed -r -e "s/.txt/.pass2.txt/" <<< "$1")


echo "start $1"


sed -r -e "s/<ref>/ /g" $1 > $target_file

sed -itmp -r -e "s/^[0-9]*://g" "$target_file"


sed -itmp -r -e "s/\{\{cite [a-zA-Z0-9]*(\|[a-zA-Z0-9]*=[^|=.?!]*)*/ /g" "$target_file"
sed -itmp -r -e "s/<ref[^>]*>/ /g" "$target_file"
sed -itmp -r -e "s/<\/ref/ /g" "$target_file"
sed -itmp -r -e "s/\(Dead link\)/ /g" "$target_file"
sed -itmp -r -e "s/\/ref/ /g" "$target_file"
sed -itmp -r -e "s/\[\[[0-9]*\]\]/ /g" "$target_file"
sed -itmp -r -e "s/\[[0-9]*\]/ /g" "$target_file"
sed -itmp -r -e "s/LINKURL[ ]*>/ /g" "$target_file"
sed -itmp -r -e "s/\[\[\[:([^]]*)\]\]//g" "$target_file"
sed -itmp -r -e "s/\[\[:([^]]*)\]\]\]//g" "$target_file"
sed -itmp '/^{{/d' "$target_file"
sed -itmp '/^|/d' "$target_file"
sed -itmp '/^!/d' "$target_file"
sed -itmp -r -e "s/<div[^>]*>/ /g" "$target_file"
sed -itmp -r -e "s/LINKURL:\/\/[a-zA-Z0-9.]*LINKURL[ ]?/ /g" "$target_file"
sed -itmp -r -e "s/ref>LINKURL/ /g" "$target_file"
sed -itmp -r -e "s/LINKURL<.ref>/ /g" "$target_file"
sed -itmp -r -e "s/ref>/ /g" "$target_file"
sed -itmp -r -e "s/<ref[^\/>]*\// /g" "$target_file"
sed -itmp -r -e "s/\[\[[a-zA-Z]*([^]]*)\]\]/ /g" "$target_file"
sed -itmp -r -e "s/\[ \|([^}]*)\}\}/ /g" "$target_file"
sed -itmp -r -e "s/\|([^]]*)\]\]/\]\]/g" "$target_file"
sed -itmp -r -e "s/\[\[([^]]*)\]//g" "$target_file"
sed -itmp -r -e "s/div(\S|\s)*\/div//ig" "$target_file"
sed -itmp -r -e "s/<r[e]?[f]?$//g" "$target_file"
sed -itmp -r -e "s/File:([^]]*)\]\]//g" "$target_file"
sed -itmp '/^\[[ ]*$/d' "$target_file"
sed -itmp '/^\][ ]*$/d' "$target_file"
sed -itmp '/<td[ ]/d' "$target_file"
sed -itmp '/<td>/d' "$target_file"



sed -itmp -r -e "s/\[\[//g" "$target_file"
sed -itmp -r -e "s/\]\]//g" "$target_file"

sed -itmp '/^[a-zA-Z0-9]*:/d' "$target_file"
sed -itmp '/^===/d' "$target_file"
sed -itmp '/^\[/d' "$target_file"
sed -itmp '/^{/d' "$target_file"
sed -itmp -r -e "s/\{\{.*\}\}//g" "$target_file"
sed -itmp -r -e "s/\{\{.*$//g" "$target_file"
sed -itmp '/{|/d' "$target_file"
sed -itmp '/\\begin/d' "$target_file"
sed -itmp '/\\frac/d' "$target_file"


suffix="tmp"

rm -f "$target_file$suffix"

echo "end $target_file"




