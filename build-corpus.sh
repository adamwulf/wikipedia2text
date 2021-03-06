if [ -f "stop.command" ]; then
	echo "Please remove stop.command file"
        exit
fi



n=0;
size_so_far=0;
size_per_file=2073741824;
size_per_write=50000;
write_buffer="";
outdir=$(readlink -f $2)

total_lines=$(wc -l < "$1");
current_line=0;
current_percent_done=0;

log_file=$outdir"/progress.log"
last_line_file=$outdir"/stopped.line"
last_n_file=$outdir"/stopped.n"
skipped_files=$outdir"/files.skipped.txt"
appended_files=$outdir"/files.appended.txt"



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


   if [[ $name != *"/Wikipedia"* && $name != *"%3A"* && name != *":"* && $name != *"jpg.xml" && $name != *"jpeg.xml" && $name != *"png.xml" ]]; then

	plain_content="";
        plainfilename="${name%.*}.plain.txt"

        echo "$name" >> $appended_files;

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
                plain_content=$(sed '/^.*\\[a-zA-Z]*/d' <<< "$plain_content");


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
                        plain_content=$(perl -0777 -p -e 's|&lt;references((?!&lt;/references&gt;)(\S\|\s))*&lt;/references&gt;||ig' <<< "$plain_content");
                        plain_content=$(perl -0777 -p -e 's|&lt;ref((?!&gt;)(\S\|\s))*/&gt;||ig' <<< "$plain_content");
                        plain_content=$(perl -0777 -p -e 's|&lt;ref([^&]\|&[^l]\|&l[^t]\|&lt[^;]\|&lt;[^/])*&lt;/ref&gt;||ig' <<< "$plain_content");
		fi


                # remove <math> tags
		if [[ $plain_content == *";math"* ]]; then
                        plain_content=$(perl -0777 -p -e 's|&lt;math&gt;([^&]\|&[^l]\|&l[^t]\|&lt[^;]\|&lt;[^/])*&lt;/math&gt;|MATHFORMULA|ig' <<< "$plain_content");
		fi

                # remove <graph> tags
                if [[ $plain_content == *";graph"* ]]; then
                        plain_content=$(perl -0777 -p -e 's|&lt;graph&gt;([^&]\|&[^l]\|&l[^t]\|&lt[^;]\|&lt;[^/])*&lt;/graph&gt;|\n|ig' <<< "$plain_content");
                fi

                # remove <timeline> tags
                if [[ $plain_content == *";timeline"* ]]; then
                        plain_content=$(perl -0777 -p -e 's|&lt;timeline&gt;([^&]\|&[^l]\|&l[^t]\|&lt[^;]\|&lt;[^/])*&lt;/timeline&gt;|\n|ig' <<< "$plain_content");
                fi

                # remove <syntaxhighlight></syntaxhighlight> tags
                if [[ $plain_content == *"&lt;syntaxhighlight"* ]]; then
                        plain_content=$(perl -0777 -p -e 's/&lt;syntaxhighlight((?!&gt;)(\S|\s))*&gt;((?!&lt;\/syntaxhighlight&gt;)(\S|\s))*&lt;\/syntaxhighlight&gt;//ig' <<< "$plain_content");
                fi

                # remove <td></td> and <th></th> tags
                if [[ $plain_content == *"<td"* ]]; then
                        plain_content=$(perl -0777 -p -e 's/<td([^>]*)>((?!<\/td>)(\S|\s))*<\/td>/\n/ig' <<< "$plain_content");
                        plain_content=$(perl -0777 -p -e 's/<th([^>]*)>((?!<\/th>)(\S|\s))*<\/th>/\n/ig' <<< "$plain_content");
                fi

                if [[ $plain_content == *"<h"* ]]; then
                        plain_content=$(perl -0777 -p -e 's/<h([\d])([^>]*)>((?!<\/h\1>)(\S|\s))*<\/h\1>//ig' <<< "$plain_content");
		fi

		
		# remove newlines and replace all </p> with </p>\n.
		# this ensures that all paragraphs are on a single line
		# in the next step
                plain_content=$(perl -0777 -p -e 's|<br[^>]*>|====nl====|ig' <<< "$plain_content");
                plain_content=$(perl -0777 -p -e 's|\n||ig' <<< "$plain_content");
                plain_content=$(perl -0777 -p -e 's|</p>|\n</p>|ig' <<< "$plain_content");
                plain_content=$(perl -0777 -p -e 's|====nl====|\n|ig' <<< "$plain_content");

                # remove <math> tags
                if [[ $plain_content == *";poem"* ]]; then
                        plain_content=$(perl -0777 -p -e 's|&lt;poem&gt;(\s\|\S)*?&lt;/poem&gt;|\n|ig' <<< "$plain_content");
                fi

		# replace ndash with a normal dash
                # plain_content=$(sed -r -e "s/–/-/g" <<< "$plain_content");











		#
		#
		# get only the content of <p> tags
                plain_content=$(recode -d ..html <<< "$plain_content")
		plain_content=$(xmllint --html --xpath "//p//child::text()" --recover --nowarning - 2> /dev/null <<< "$plain_content")
		plain_content=$(recode html..utf8 <<< "$plain_content")
		#
		#
		#






                # remove <td></td> and <th></th> tags
                if [[ $plain_content == *"<td"* ]]; then
                        plain_content=$(perl -0777 -p -e 's/<td([^>]*)>(\S|\s)*<\/td>/\n/ig' <<< "$plain_content");
                        plain_content=$(perl -0777 -p -e 's/<th([^>]*)>(\S|\s)*<\/th>/\n/ig' <<< "$plain_content");

                        plain_content=$(perl -0777 -p -e 's/<td([^>]*)>/ /ig' <<< "$plain_content");
                        plain_content=$(perl -0777 -p -e 's/<th([^>]*)>/ /ig' <<< "$plain_content");
                fi


		if [[ $plain_content = *"&"* ]]; then
			# convert html entities, if any
	#               plain_content=$(echo "$plain_content" | perl -MHTML::Entities -pe 'decode_entities($_);' 2> /dev/null)
			plain_content=$(echo "$plain_content" | php -r 'echo html_entity_decode(file_get_contents("php://stdin"), ENT_QUOTES|ENT_HTML401);' 2> /dev/null)
		fi


                if [[ $plain_content == *"[["* ]]; then
			# remove [[[:anything]]] wiki links
			if [[ $plain_content == *"[[[:"* ]]; then
                		plain_content=$(sed -r -e "s/\[\[\[:([^]]*)\]\]\]//g" <<< "$plain_content");
                		plain_content=$(sed -r -e "s/\[\[\[([^]]*)\]\]\]/\1/g" <<< "$plain_content");
			fi


                	# fix [[:|text]] style wiki links
			if [[ $plain_content == *"[[:"* ]]; then
                		plain_content=$(sed -r -e "s/\[\[:\|([^]]*)\]\]/\1/g" <<< "$plain_content");
			fi


			# fix [[Link text|page url]] style wiki links
               		plain_content=$(sed -r -e 's/\[\[([^]|]*?)\|([^]]*)\]\]/\1/g' <<< "$plain_content");
                #        plain_content=$(sed -r -e 's/\[\[([^]]*?)\]\]/\1/g' <<< "$plain_content");
		fi


		# remove {{#invoke:Portal ... }} and similar tags
                if [[ $plain_content == *"{{#"* ]]; then
                        plain_content=$(perl -0777 -p -e 's/\{{#[^}]*}}//ig' <<< "$plain_content");
		fi



                # remove <source></source> tags
                if [[ $plain_content == *"<source"* ]]; then
                        plain_content=$(perl -0777 -p -e 's/<source([^>]*)>(\S|\s)*?<\/source>//ig' <<< "$plain_content");
                fi


		# remove <syntaxhighlight></syntaxhighlight> tags
                if [[ $plain_content == *"<syntaxhighlight"* ]]; then
                        plain_content=$(perl -0777 -p -e 's/<syntaxhighlight([^>]*)>(\S|\s)*?<\/syntaxhighlight>//ig' <<< "$plain_content");
                fi

                # remove <math></math> tags
		if [[ $plain_content == *"<math"* ]]; then
			plain_content=$(perl -0777 -p -e 's/<math([^>]*)>(\S|\s)*?<\/math>/MATHFORMULA/ig' <<< "$plain_content");
		fi

                # remove lines only of codeblocks
                if [[ $plain_content == *"MATHFORMULA"* ]]; then
	                plain_content=$(sed '/^MATHFORMULA$/d' <<< "$plain_content");
		fi

                # remove <poem> tags
                if [[ $plain_content == *"<poem"* ]]; then
                        plain_content=$(perl -0777 -p -e 's/<poem([^>]*)>(\S|\s)*?<\/poem>//ig' <<< "$plain_content");
                fi

                if [[ $plain_content == *"<ref"* ]]; then
			plain_content=$(sed -r -e 's|<ref([^>]*)/>||g' <<< "$plain_content");
                        plain_content=$(perl -0777 -p -e 's/<ref([^>]*)>(\S|\s)*?<\/ref>//ig' <<< "$plain_content");
		fi

                # remove <timeline> tags
		if [[ $plain_content == *"<timeline"* ]]; then
                	plain_content=$(perl -0777 -p -e 's/<timeline([^>]*)>(\S|\s)*?<\/timeline>//ig' <<< "$plain_content");
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

                # remove URLs
                plain_content=$(perl -0777 -p -e 's/([a-zA-Z]+:\/\/){0,1}[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/LINKURL/g' <<< "$plain_content");

                # remove any closing tags
                plain_content=$(perl -0777 -p -e 's/<\/[a-zA-Z0-9]*>//ig' <<< "$plain_content");

                if [[ $plain_content == *"<td"* ]]; then
	                plain_content=$(sed '/^<td/d' <<< "$plain_content");
                fi
                if [[ $plain_content == *"<ref"* ]]; then
                        plain_content=$(sed '/^<ref/d' <<< "$plain_content");
                fi
                if [[ $plain_content == *"<poem"* ]]; then
                        plain_content=$(sed '/^<poem/d' <<< "$plain_content");
                fi

		# fix double comma
                plain_content=$(sed -r -e 's/, ,/,/g' <<< "$plain_content");

		### Remove empty lines
                plain_content=$(sed '/^$/d' <<< "$plain_content");

                plain_content=$(sed -r -e 's/\[edit\]//g' <<< "$plain_content");

		### Trim leading whitespaces ###
		plain_content="${plain_content##*( )}"
 
		### trim trailing whitespaces  ##
		plain_content="${plain_content%%*( )}"


                if [[ $plain_content == *"|"* ]]; then
                	plain_content=$(sed -r -e "s/\|[a-zA-Z0-9]*=[a-zA-Z0-9]*/ /g" <<< "$plain_content");
	                plain_content=$(sed '/^|/d' <<< "$plain_content");
        	        plain_content=$(sed '/^!/d' <<< "$plain_content");
		fi


                plain_content=$(sed '/^Last updated:/d' <<< "$plain_content");

                echo "$plain_content" > $plainfilename;
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
   else
        echo "$name" >> $skipped_files;
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


