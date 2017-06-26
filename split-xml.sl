$handle = openf(@ARGV[0]);

@handles = @();
for ($x = 0; $x < 16; $x++)
{
   push(@handles, openf(">en.xml.split. $+ $x $+ .xml"));
}

$x = 0;
while $txt (readln($handle))
{
   println(@handles[$x % 16], "$txt");

#<asdf>   println(@handles[$x % 16], "php ./wiki2xml/php/wiki2xml_command.php ../ $+ $txt ../ $+ $out"); #</asdf>


   $x++;
}

foreach $handlez (@handles)
{
   closef($handlez);
}

closef($handle);
