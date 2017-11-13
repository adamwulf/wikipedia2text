$handle = openf(">launch-all.sh");

for ($x = 0; $x < 8; $x++)
{
   println($handle, "sh ../../data/wikipedia-xml/files $+ $x $+ .sh  > /dev/null  2> error $+ $x $+ .log &");
}

closef($handle);
