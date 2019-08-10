BEGIN PROCESS::<$REPO> := (my class CompUnit::Repository::Jail
    does CompUnit::Repository {

    my $DIR = $*CWD;
    my \DEC = %(flat ('0'..'9' Z=> 0..9), ('a'..'z' Z=> 10..*));

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

    has %!units = {}.push: $DIR.dir(test => /\.moarvm$/)>>.basename.map: {
        if /^ [ 'no-auth' | 'auth-' <auth=&encoded> ]
              '.' <name=&encoded>
              '.' [ 'no-ver' | 'ver-' <ver=&encoded> ]
              '.moarvm' $/ {

            my $name = $<name>.made;
            $name => CompUnit.new:
                short-name => $name,
                version => $<ver> ?? Version.new($<ver>.made) !! Version,
                auth => $<auth>.made // Str,
                repo => self,
                repo-id => $_,
                precompiled => True,
                handle => CompUnit::Loader.load-precompilation-file($DIR.add($_));
        }
    }

    method need(CompUnit::DependencySpecification $spec,
                CompUnit::PrecompilationRepository $precomp?
                --> CompUnit:D) {

        with %!units{$spec.short-name} {
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
