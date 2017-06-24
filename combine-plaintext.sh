while read p; do
if [[ $p != *"/Wikipedia"* ]]; then
  cat header $p footer | xmllint --xpath "//p[(count(a) > 0 and count(*) > count(a)) or (count(a) = 0) or (count(*) = 0)]//child::text()" --recover --nowarning - 2> /dev/null | php -r 'while(($line=fgets(STDIN)) !== FALSE) echo html_entity_decode($line, ENT_QUOTES|ENT_HTML401);' 2> /dev/null
fi
done < en.xml.files
