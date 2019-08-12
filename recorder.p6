INIT {
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

    my %units;
    sub process($cu --> Nil) {
        my $pcu = $cu.&precomp-unit;
        my $path = ~$pcu.path;
        return if %units{$path}:exists;

        %units{$path} = $cu;
        .&process for deps $pcu;
    }

    .&process for roots;

    my $fh = open 'units.record', :w;
    LEAVE $fh.close;

    for %units.kv -> $path, $cu {
        $fh.put: $cu.short-name;
        $fh.put: $cu.auth // '';
        $fh.put: $cu.version // '';
        $fh.put: $path;
    }

    exit;
}
