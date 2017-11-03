sed ':a;N;$!ba;s/\\n/\n/g' out-0.txt > test.txt

# this will replace "\n" with actual newlines. out-0.txt => out-0.clean.txt
