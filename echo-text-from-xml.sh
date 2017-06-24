cat header ../articles/49/65/White_Island%2C_Otago.xml footer | xmllint --xpath "//p[(count(a) > 0 and count(*) > count(a)) or (count(a) = 0)]//child::text()" --recover --nowarning - 2> /dev/null

# paragraph must have multiple kinds of tags if it has an <a> tag. otherwise anything goes.


cat header articles/c1/c1/Wikipedia%3APeer_review%2FFrancis_Drake%2Farchive1.xml footer | xmllint --xpath "//p[count(a)!=1 or (count(a) =1 and count(*) > 1)]//child::text()" --recover --nowarning - 2> /dev/null

# the above will find all paragraph nodes that have zero or more than 1 <a> tag. or will find paragraphs that have 1 <a> tag as well as other kinds of tags.

cat header articles/c1/c1/Wikipedia%3APeer_review%2FFrancis_Drake%2Farchive1.xml footer | xmllint --xpath "//p//child::text()" --recover --nowarning - 2> /dev/null



# the following will restore html entities:

[ec2-user@ip-172-31-3-98 ~]$ cat header articles/49/65/White_Island%2C_Otago.xml footer | xmllint --xpath "//p[(count(a) > 0 and count(*) > count(a)) or (count(a) = 0) or (count(*) = 0)]//child::text()" --recover --nowarning - | php -r 'while(($line=fgets(STDIN)) !== FALSE) echo html_entity_decode($line, ENT_QUOTES|ENT_HTML401);' 2> /dev/null


# then i'll need to strip out the content inside of html nodes like <ref>. so i'll probably need to do a 2nd pass on this content
# using another xml parsing pass.


