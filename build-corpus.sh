
n=0;
size_so_far=0;

while read name
do
   if (("$size_so_far" > 1073741824)); then
     size_so_far=0;
     n=$(($n + 1));
   fi

   if [[ $name != *"/Wikipedia"* ]]; then
        # read in the content
     	plain_content=$(cat header $name footer);

	# remove template links
        plain_content=$(echo $plain_content | sed -r -e 's|<a [^>]*>Template:[^>]*</a>||g');

	# remove <ref> tags
	plain_content=$(echo $plain_content | sed -r -e 's|&lt;ref(.*)&lt;/ref&gt;||g');

	# get only the content of <p> tags
        plain_content=$(echo $plain_content | xmllint --xpath "//p[(count(a) > 0 and count(*) > count(a)) or (count(a) = 0) or (count(*) = 0)]//child::text()" --recover --nowarning - 2> /dev/null)

        plain_content=$(echo $plain_content | recode html..utf8)

	if [[ $plain_content != *"&"* ]]; then
		# convert html entities, if any
#               plain_content=$(echo $plain_content | perl -MHTML::Entities -pe 'decode_entities($_);' 2> /dev/null)
        	plain_content=$(echo $plain_content | php -r 'echo html_entity_decode(file_get_contents("php://stdin"), ENT_QUOTES|ENT_HTML401);' 2> /dev/null)
	fi

	# remove <ref /> tags
        plain_content=$(echo $plain_content | sed -r -e 's|<ref([^>]*)/>||g');

        # remove " ()" which is leftover from the removed template links above
	# and trim leading/trailing whitespace
        plain_content=$(echo $plain_content | sed -r -e 's|\s\(\)||g');

	# remove lines starting with |
	plain_content=$(echo $plain_content | sed '/^|/ d');

	### Trim leading whitespaces ###
	plain_content="${plain_content##*( )}"
 
	### trim trailing whitespaces  ##
	plain_content="${plain_content%%*( )}"

	# find out the final byte size of our content
        size_to_append=${#plain_content};
        size_to_append=$(echo -n $plain_content | wc -c);

        # size_to_append=$(du -sb $name | awk '{ print $1 }')
        size_so_far=$(($size_so_far + $size_to_append));

        # $name is the file that we'll be appending to the corpus file
	target_file=../corpus/out-$n.txt
        target_size=0;

        if [ -f $target_file ]; then
            target_size=$(du -sb $target_file | awk '{ print $1 }')
        fi

        if (("$size_so_far" > "$target_size")); then
            echo $plain_content >> $target_file;
        fi
   fi


# break;


done < en.xml.files





