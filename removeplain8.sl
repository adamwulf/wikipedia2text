$handle = openf(@ARGV[0]);

@handles = @();
for ($x = 0; $x < 8; $x++)
{
   push(@handles, openf(">../../data/wikipedia-xml/remove.plain- $+ $x $+ .sh"));
}

$x = 0;
while $txt (readln($handle))
{
   $out = strrep($txt, '.txt', '.plain.txt');
   println(@handles[$x % 8], "rm -f $out");

   $x++;
}

foreach $handlez (@handles)
{
   closef($handlez);
}

closef($handle);
