
n=0;
size_so_far=0;
size_per_file=1073741824;
size_per_write=20000;
write_buffer="";
outdir=$(readlink -f $2)

total_lines=$(wc -l < "$1");
current_line=0;
current_percent_done=0;

$(mkdir $outdir 2> /dev/null);

while read name
do
	current_line=$(($current_line+1));
	updated_percent=$(echo "$current_line*100/$total_lines" | bc);
	
	if (($current_percent_done != "$updated_percent" )); then
		current_percent_done=$updated_percent;
		echo $outdir": "$current_percent_done"% current_line:$current_line total_lines:$total_lines";
	fi

   if (("$size_so_far" > "$size_per_file")); then
     size_so_far=0;
     n=$(($n + 1));
   fi

   if [[ $name != *"/Wikipedia"* && $name != *"Template%3A"* ]]; then

	plain_content="";
        plainfilename="${name%.*}"

	if [ -f $plainfilename ]; then
		plain_content=$(cat $plainfilename);
	else
		# read in the content
		plain_content=$(cat header $name footer);

		# remove template links
		plain_content=$(sed -r -e 's|<a [^>]*>Template:[^>]*</a>||g' <<< $plain_content);

		# remove <ref> tags
		plain_content=$(sed -r -e 's|&lt;ref[^&]*&gt;[^&]*&lt;/ref&gt;||g' <<< $plain_content);

		# get only the content of <p> tags
		plain_content=$(xmllint --xpath "//p//child::text()" --recover --nowarning - 2> /dev/null <<< $plain_content)


		plain_content=$(recode html..utf8 <<< $plain_content)

		if [[ $plain_content != *"&"* ]]; then
			# convert html entities, if any
	#               plain_content=$(echo $plain_content | perl -MHTML::Entities -pe 'decode_entities($_);' 2> /dev/null)
			plain_content=$(echo $plain_content | php -r 'echo html_entity_decode(file_get_contents("php://stdin"), ENT_QUOTES|ENT_HTML401);' 2> /dev/null)
		fi

		# remove <ref /> tags
		plain_content=$(sed -r -e 's|<ref([^>]*)/>||g' <<< $plain_content);
		plain_content=$(sed -r -e 's|<ref[^>]*>| |g' <<< $plain_content);
		plain_content=$(sed -r -e 's|</ref>| |g' <<< $plain_content);

		# remove " ()" which is leftover from the removed template links above
		# and trim leading/trailing whitespace
		plain_content=$(sed -r -e 's|\s\(\)||g' <<< $plain_content);

		# remove lines starting with |
		plain_content=$(sed '/^|/ d' <<< $plain_content);

		### Trim leading whitespaces ###
		plain_content="${plain_content##*( )}"
 
		### trim trailing whitespaces  ##
		plain_content="${plain_content%%*( )}"

        	echo $plain_content >> $plainfilename;
	fi

#	echo $plain_content;
#	echo "======================================="

        size_to_append=${#plain_content};
        size_to_append=$(echo -n $plain_content | wc -c);

	if (("$size_to_append" > 0 )); then
		write_buffer=$write_buffer$plain_content"\n"

		# find out the final byte size of our content
		size_to_append=${#write_buffer};
		size_to_append=$(echo -n $write_buffer | wc -c);

		if (("$size_to_append" > "$size_per_write")); then
			# size_to_append=$(du -sb $name | awk '{ print $1 }')
			size_so_far=$(($size_so_far + $size_to_append));

			# $name is the file that we'll be appending to the corpus file
			target_file=$outdir"/out-$n.txt"
			target_size=0;

			if [ -f $target_file ]; then
				target_size=$(du -sb $target_file | awk '{ print $1 }')
			fi

			if (("$size_so_far" > "$target_size")); then
				echo $write_buffer >> $target_file;
				size_to_append=0;
				write_buffer="";
			fi
		fi
	fi
   fi


# break;


done < $1





