$handle = openf(@ARGV[0]);

@handles = @();
for ($x = 0; $x < 8; $x++)
{
   push(@handles, openf(">../../data/wikipedia-xml/en.xml.split $+ $x $+ .files"));
}

$x = 0;
while $txt (readln($handle))
{
   println(@handles[$x % 8], "$txt");

   $x++;
}

foreach $handlez (@handles)
{
   closef($handlez);
}

closef($handle);
