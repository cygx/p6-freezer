{
    class CompUnit::Stored is CompUnit {
        has Blob $.bytecode;

        method load(CompUnit::Repository $repo) {
            without $.handle {
                use nqp;
                nqp::bindattr(self, CompUnit, '$!handle',
                    CompUnit::Loader.load-precompilation($!bytecode));
                nqp::bindattr(self, CompUnit, '$!repo', $repo);
            }

            self;
        }

        method set-bytecode(Blob:D $bytecode) {
            $!bytecode = $bytecode;
            self;
        }

        method new(::?CLASS:U: Blob:D :$bytecode, *%_) {
            self.CompUnit::new(|%_).set-bytecode($bytecode);
        }
    }

    constant DEC = %(flat ('0'..'9' Z=> 0..9), ('a'..'z' Z=> 10..*));
    constant $DIR = $*CWD;

    my token encoded {
        [
        || ('_' (<[a..z A..Z]>+) '_' { make $0.uc })
        || ('_' ((<[0..9]>) <[0..9 a..z A..Z]> ** {+$0} {
                my int $cp = 0;
                for $/.substr(1).comb {
                    $cp *= 36;
                    $cp += DEC{$_};
                }
                make $cp.chr;
           })+ '_' { make $0>>.made.join })
        || (<[0..9 a..z A..Z]>+ { make "$/" })
        ]+
        { make $0>>.made.join }
    }

    constant %UNITS = {}.push: $DIR.dir(test => /\.moarvm$/)>>.basename.map: {
        if /^ [ 'no-auth' | 'auth-' <auth=&encoded> ]
              '.' <name=&encoded>
              '.' [ 'no-ver' | 'ver-' <ver=&encoded> ]
              '.moarvm' $/ {

            my $name = $<name>.made;
            $name => CompUnit::Stored.new:
                bytecode => $DIR.add($_).slurp(:bin),
                short-name => $name,
                version => $<ver> ?? Version.new($<ver>.made) !! Version,
                auth => $<auth>.made // Str,
                repo => CompUnit::Repository,
                repo-id => $_,
                precompiled => True;
        }
    }

    INIT PROCESS::<$REPO> := (my class CompUnit::Repository::StoredJail
        does CompUnit::Repository {

        has %!units = %UNITS.values.map: |*.map: *.load(self);

        method need(CompUnit::DependencySpecification $spec,
                    CompUnit::PrecompilationRepository $precomp?
                    --> CompUnit:D) {

            with %UNITS{$spec.short-name} {
                # TODO: check ver/auth
                return .head;
            }

            X::CompUnit::UnsatisfiedDependency.new(:specification($spec)).throw
        }

        method resolve(CompUnit::DependencySpecification $spec --> CompUnit:D) {
            X::NYI.new(feature => "resolving modules").throw;
        }

        method load(IO::Path:D $file --> CompUnit:D) {
            X::NYI.new(feature => "loading modules by path").throw;
        }

        method loaded { %!units.values }
        method id(--> "jail") {}
        method repo-chain { (self, ) }
        method path-spec { self.id ~ '#' ~ $DIR.absolute }
        multi method gist(::?CLASS:D:) { self.path-spec }

    }).new;
}
