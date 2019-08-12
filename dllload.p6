{
    use NativeCall;

    sub mbc_size(uint32 $idx --> size_t) is native<store.dll> {*}
    sub mbc_copy(uint32 $idx, buf8:D $buf) is native<store.dll> {*}
    sub mbc_name(uint32 $idx --> Str) is native<store.dll> {*}
    sub mbc_auth(uint32 $idx --> Str) is native<store.dll> {*}
    sub mbc_ver(uint32 $idx --> Str) is native<store.dll> {*}

    class CompUnit::Stored is CompUnit {
        has Blob $.bytecode;

        method load {
            without $.handle {
                use nqp;
                nqp::bindattr(self, CompUnit, '$!handle',
                    CompUnit::Loader.load-precompilation($!bytecode));
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

    BEGIN PROCESS::<$REPO> := (my class CompUnit::Repository::DLLJail
        does CompUnit::Repository {

        has %!units = {}.push: gather loop (my uint32 $i = 0;; ++$i) {
            my $size = mbc_size($i);
            last unless $size;

            my $bytecode := buf8.allocate($size);
            mbc_copy($i, $bytecode);

            my $short-name = mbc_name($i);
            my $auth = mbc_auth($i);
            my $ver = mbc_ver($i);
            my $version = $ver.defined ?? Version.new($ver) !! Version;
            my $repo = self;
            my $repo-id = "$i";

            take $short-name => CompUnit::Stored.new:
                :$bytecode,
                :$short-name,
                :$version
                :$auth,
                :$repo,
                :$repo-id,
                :precompiled;
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
        method id(--> "dlljail") {}
        method repo-chain { (self, ) }
        method path-spec { self.id ~ '#' ~ 'store.dll'.IO.absolute }
        multi method gist(::?CLASS:D:) { self.path-spec }

        method load-all {
            .load for %!units.values;
            self;
        }

    }).new.load-all;
}
