INIT {
    sub enc($_) {
        my \ENC = BEGIN @(flat '0'..'9', 'a'..'z');
        m/  ^[
            || (<[a..z 0..9]>+ { make "$/" })
            || (<[A..Z]>+ { make "_{$/}_" })
            || (<-[a..z A..Z 0..9]>+ {
                    my $chars = $/.Str.NFC.map: {
                        my @digits;
                        my int $cp = $_;
                        while $cp {
                            @digits.unshift(ENC[$cp % 36]);
                            $cp div= 36;
                        }
                        "{+@digits}{@digits.join}";
                    }
                    make "_{$chars.join}_";
               })
            ]*$
            { make $0>>.made.join }
        /.made;
    }

    sub roots {
        $*REPO.repo-chain.map(*.loaded.Slip);
    }

    sub precomp-unit($cu) {
        given $cu.repo.precomp-store {
            when CompUnit::PrecompilationStore::File {
                use nqp;
                nqp::getattr($_, CompUnit::PrecompilationStore::File,
                    '%!loaded'){$cu.repo-id};
            }

            default {
                X::NYI.new(feature => "freezing unit stored in {.^name}").throw;
            }
        }
    }

    sub deps($pcu) {
        $pcu.dependencies.map: { $*REPO.resolve(.spec) }
    }

    sub frozen-name($cu) {
        my $name = enc $cu.short-name;
        my $auth = ($cu.auth andthen "auth-{.&enc}" orelse 'no-auth');
        my $ver  = ($cu.version andthen "ver-{.Str.&enc}" orelse 'no-ver');
        my $ext  = Rakudo::Internals.PRECOMP-EXT;
        join '.', $auth, $name, $ver, $ext;
    }

    sub long-name($cu) {
        my $name = $cu.short-name;
        my $auth = $cu.auth // '?';
        my $ver  = $cu.version // '?';
        "{$name}:auth<{$auth}>:ver<{$ver}>";
    }

    my %units;
    sub process($cu --> Nil) {
        my $pcu = $cu.&precomp-unit;
        my $path = ~$pcu.path;
        return if %units{$path}:exists;

        %units{$path} = $cu;
        .&process for deps $pcu;
    }

    sub freeze($src, $dest) {
        my $fh = open $src;
        while $fh.get {} # skip meta-info
        $dest.IO.spurt($fh.slurp(:bin, :close));
    }

    .&process for roots;
    for %units.kv -> $path, $cu {
        note "  freezing {$cu.&long-name}";
        try freeze $path, $cu.&frozen-name;
        .rethrow with $!;
    }

    exit;
}
