if [ -f "stop.command" ]; then
	echo "Please remove stop.command file"
        exit
fi



n=0;
size_so_far=0;
size_per_file=2073741824;
size_per_write=20000;
write_buffer="";
outdir=$(readlink -f $2)

total_lines=$(wc -l < "$1");
current_line=0;
current_percent_done=0;

log_file=$outdir"/progress.log"
last_line_file=$outdir"/stopped.line"
last_n_file=$outdir"/stopped.n"

skip_until=0

$(mkdir $outdir 2> /dev/null);

echo "started." >> $log_file;


if [ -f $last_line_file ]; then
	n=$(cat $last_n_file);
	skip_until=$(cat $last_line_file);
	target_file=$outdir"/out-$n.txt"
	size_so_far=$(wc -c $target_file | awk '{ print $1 }')
	echo "scanning to line $skip_until for file $n" >> $log_file
fi

while read name
do

	if [ -f "stop.command" ]; then
		echo $current_line > $last_line_file;
		echo $n > $last_n_file;
		echo "stopped at $current_line with size $size_so_far" >> $log_file;
		exit;
	fi

	current_line=$(($current_line+1));
	updated_percent=$(echo "$current_line*100/$total_lines" | bc);
	
	if (($current_percent_done != "$updated_percent" )); then
		current_percent_done=$updated_percent;
		echo $outdir": "$current_percent_done"% current_line:$current_line total_lines:$total_lines" >> $log_file;
	fi


        if (($current_line < $skip_until + 1)); then
                continue
        fi

        if (($current_line == $skip_until + 1)); then
                echo "restarting: "$current_percent_done"% current_line:$current_line total_lines:$total_lines with size: $size_so_far" >> $log_file;
        fi


   if (("$size_so_far" > "$size_per_file")); then
     size_so_far=0;
     n=$(($n + 1));
   fi

   if [[ $name != *"/Wikipedia"* && $name != *"Template%3A"* && $name != *"Module%3A"* && $name != *"jpg.xml" && $name != *"jpeg.xml" && $name != *"png.xml" ]]; then

	plain_content="";
        plainfilename="${name%.*}.plain.txt"

	if [ -f $plainfilename ]; then
		plain_content=$(cat $plainfilename);
	else
		# read in the content
		plain_content=$(cat header $name footer);


                # remove lines starting with |
               	plain_content=$(sed '/^|/d' <<< "$plain_content");
                plain_content=$(sed '/^!/d' <<< "$plain_content");
                plain_content=$(sed '/^{|/d' <<< "$plain_content");
                plain_content=$(sed '/^<p>|/d' <<< "$plain_content");

		#
		# After this, the entire content will be treated as a single line.
		# This happense because our input to sed is not quoted, which lets
		# us regex for multi-line patterns
		# Above, we used "$plain_content" to only filter out single lines
		# prefixed by |
		#

		# remove template links
		if [[ $plain_content == *">Template"* ]]; then
			plain_content=$(sed -r -e 's|<a [^>]*>Template:[^>]*</a>||ig' <<< "$plain_content");
		fi


		# remove <ref> tags
		if [[ $plain_content == *";ref"* ]]; then
                        plain_content=$(perl -0777 -p -e 's|&lt;ref&gt;([^&]\|&[^l]\|&l[^t]\|&lt[^;]\|&lt;[^/])*&lt;/ref&gt;||ig' <<< "$plain_content");
		fi

                # remove <math> tags
		if [[ $plain_content == *";math"* ]]; then
                        plain_content=$(perl -0777 -p -e 's|&lt;math&gt;([^&]\|&[^l]\|&l[^t]\|&lt[^;]\|&lt;[^/])*&lt;/math&gt;|MATHFORMULA|ig' <<< "$plain_content");
		fi

                # remove <syntaxhighlight></syntaxhighlight> tags
                if [[ $plain_content == *"&lt;syntaxhighlight"* ]]; then
                        plain_content=$(perl -0777 -p -e 's/&lt;syntaxhighlight((?!&gt;)(\S|\s))*&gt;((?!&lt;\/syntaxhighlight&gt;)(\S|\s))*&lt;\/syntaxhighlight&gt;/CODEBLOCK/ig' <<< "$plain_content");
                fi

                # remove <td></td> and <th></th> tags
                if [[ $plain_content == *"<td"* ]]; then
                        plain_content=$(perl -0777 -p -e 's/<td([^>]*)>((?!<\/td>)(\S|\s))*<\/td>//ig' <<< "$plain_content");
                        plain_content=$(perl -0777 -p -e 's/<th([^>]*)>((?!<\/th>)(\S|\s))*<\/th>//ig' <<< "$plain_content");
                fi


                plain_content=$(perl -0777 -p -e 's/<h1([^>]*)>((?!<\/h1>)(\S|\s))*<\/h1>//ig' <<< "$plain_content");
                plain_content=$(perl -0777 -p -e 's/<h2([^>]*)>((?!<\/h2>)(\S|\s))*<\/h2>//ig' <<< "$plain_content");
                plain_content=$(perl -0777 -p -e 's/<h3([^>]*)>((?!<\/h3>)(\S|\s))*<\/h3>//ig' <<< "$plain_content");
                plain_content=$(perl -0777 -p -e 's/<h4([^>]*)>((?!<\/h4>)(\S|\s))*<\/h4>//ig' <<< "$plain_content");
                plain_content=$(perl -0777 -p -e 's/<h5([^>]*)>((?!<\/h5>)(\S|\s))*<\/h5>//ig' <<< "$plain_content");


		# get only the content of <p> tags
		plain_content=$(xmllint --xpath "//p//child::text()" --recover --nowarning - 2> /dev/null <<< "$plain_content")
		plain_content=$(recode html..utf8 <<< "$plain_content")


		if [[ $plain_content = *"&"* ]]; then
			# convert html entities, if any
	#               plain_content=$(echo "$plain_content" | perl -MHTML::Entities -pe 'decode_entities($_);' 2> /dev/null)
			plain_content=$(echo "$plain_content" | php -r 'echo html_entity_decode(file_get_contents("php://stdin"), ENT_QUOTES|ENT_HTML401);' 2> /dev/null)
		fi


		# remove <syntaxhighlight></syntaxhighlight> tags
                if [[ $plain_content == *"<syntaxhighlight"* ]]; then
                        plain_content=$(perl -0777 -p -e 's/<syntaxhighlight([^>]*)>((?!<\/syntaxhighlight>)(\S|\s))*<\/syntaxhighlight>/CODEBLOCK/ig' <<< "$plain_content");
                fi

		# remove lines only of codeblocks
                plain_content=$(sed '/^CODEBLOCK$/d' <<< "$plain_content");


		# remove URLs
                plain_content=$(perl -0777 -p -e 's/([a-zA-Z]+:\/\/){0,1}[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/LINKURL/g' <<< "$plain_content");

                # remove <math></math> tags
		if [[ $plain_content == *"<math"* ]]; then
			plain_content=$(perl -0777 -p -e 's/<math([^>]*)>((?!<\/math>)(\S|\s))*<\/math>/MATHFORMULA/ig' <<< "$plain_content");
		fi

                # remove lines only of codeblocks
                plain_content=$(sed '/^MATHFORMULA$/d' <<< "$plain_content");


		# remove <ref /> tags
		if [[ $plain_content == *"<ref"* ]]; then
			plain_content=$(sed -r -e 's|<ref([^>]*)/>||g' <<< "$plain_content");
                        plain_content=$(perl -0777 -p -e 's/<ref([^>]*)>((?!<\/ref>)(\S|\s))*<\/ref>//ig' <<< "$plain_content");
		fi

                # remove <timeline> tags
		if [[ $plain_content == *"<timeline"* ]]; then
                	plain_content=$(perl -0777 -p -e 's/<timeline([^>]*)>((?!<\/timeline>)(\S|\s))*<\/timeline>//ig' <<< "$plain_content");
		fi

		# replace " (; " with " ( "
		# same with " (, "
		if [[ $plain_content == *"(;"* ]]; then
                	plain_content=$(sed -r -e 's| \(; | (|g' <<< "$plain_content");
		fi
		if [[ $plain_content == *"(,"* ]]; then
                        plain_content=$(sed -r -e 's| \(, | (|g' <<< "$plain_content");
		fi

		# remove " ()" which is leftover from the removed template links above
		# and trim leading/trailing whitespace
		if [[ $plain_content == *"()"* ]]; then
			plain_content=$(sed -r -e 's|\s\(\)||g' <<< "$plain_content");
		fi

                # remove lines starting with Source:
                if [[ $plain_content == *"Source:"* ]]; then
                        plain_content=$(sed '/^Source:/d' <<< "$plain_content");
                fi

		### Remove empty lines
                plain_content=$(sed '/^$/d' <<< "$plain_content");

                plain_content=$(sed -r -e 's/\[edit\]//g' <<< "$plain_content");

		### Trim leading whitespaces ###
		plain_content="${plain_content##*( )}"
 
		### trim trailing whitespaces  ##
		plain_content="${plain_content%%*( )}"


        	echo $plain_content > $plainfilename;
	fi

        size_to_append=${#plain_content};
        size_to_append=$(echo -n $plain_content | wc -c);

	if (("$size_to_append" > 0 )); then
		NEWLINE=$'\n'
		write_buffer=$write_buffer$NEWLINE$plain_content

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
				# echo "writing to corpus"
				# echo $write_buffer
				echo "$write_buffer" >> $target_file;
				size_so_far=$(($target_size + $size_to_append))
			fi

                        size_to_append=0;
                        write_buffer="";
		fi
	fi
   fi


# break;

done < $1

# finish writing anything in the buffer
if (("$size_to_append" > 0)); then
#        echo "writing remaining of buffer";
#        echo $write_buffer;
        target_file=$outdir"/out-$n.txt"
        echo "$write_buffer" >> $target_file;
fi


echo "done." >> $log_file

$(rm -f $last_line_file 2> /dev/null);
$(rm -f $last_n_file 2> /dev/null);


