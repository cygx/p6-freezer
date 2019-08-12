constant NUL = blob8.new(0);

my ($index, $data) = (open $_, :w :bin for <store.index store.data>);
LEAVE .close for $index, $data;

my $records := 'units.record'.IO.lines.rotor(4).sort: { [||] $^a Zcmp $^b };
for $records -> ($name, $auth, $ver, $path) {
    FIRST my \first = True;
    $index.write: NUL unless first;
   
    my $bc = do given open $path {
        while .get {} # skip meta-info
        .slurp(:bin, :close);
    }

    $index.write: join("\0", $name, $auth, $ver, $bc.bytes).encode;
    $data.write: $bc;
}
