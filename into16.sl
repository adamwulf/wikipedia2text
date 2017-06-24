$handle = openf(@ARGV[0]);

@handles = @();
for ($x = 0; $x < 40; $x++)
{
   push(@handles, openf(">files $+ $x $+ .sh"));
}

$x = 0;
while $txt (readln($handle))
{
   $out = strrep($txt, '.txt', '.xml');
   println(@handles[$x % 40], "[ -f ../ $+ $out ] || php ../mediawiki-1.28.2/maintenance/parse.php ../ $+ $txt > ../ $+ $out");

#<asdf>   println(@handles[$x % 40], "php ./wiki2xml/php/wiki2xml_command.php ../ $+ $txt ../ $+ $out"); #</asdf>


   $x++;
}

foreach $handlez (@handles)
{
   closef($handlez);
}

closef($handle);
