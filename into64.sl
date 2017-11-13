$handle = openf(@ARGV[0]);

@handles = @();
for ($x = 0; $x < 64; $x++)
{
   push(@handles, openf(">../../data/wikipedia-xml/files $+ $x $+ .sh"));
}

$x = 0;
while $txt (readln($handle))
{
   $out = strrep($txt, '.txt', '.xml');
   println(@handles[$x % 64], "[ -f $out ] || php ../mediawiki-1.28.2/maintenance/parse.php  $txt > $out");

   $x++;
}

foreach $handlez (@handles)
{
   closef($handlez);
}

closef($handle);
