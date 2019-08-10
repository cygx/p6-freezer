{
    use nqp;

    my enum <SPEC FILE>;
    my @log;

    INIT {
        for @log -> ($type, $key, $cu) {
            my $path = do given $cu.repo {
                when CompUnit::Repository::FileSystem
                   | CompUnit::Repository::Installation {
                    .{$cu.repo-id}.path
                        given nqp::getattr(.precomp-store, 
                            CompUnit::PrecompilationStore::File, '%!loaded');
                }

                default { X::NYI.new(feature => "logging {.^name}").throw }
            }

            note qq:to/DONE/;
                type {$type}
                key  {$key}
                name {$cu.short-name}
                auth {$cu.auth // ''}
                ver  {$cu.version // ''}
                path {$path}
                DONE
        }

        exit;
    }

    BEGIN CompUnit::RepositoryRegistry.use-repository:
        (my class CompUnit::Repository::Logger does CompUnit::Repository {
            method need(CompUnit::DependencySpecification $spec,
                CompUnit::PrecompilationRepository $precomp?
                --> CompUnit:D) {
                my $cu = self.next-repo.need($spec, |($precomp // Empty));
                @log.push((SPEC, ~$spec, $cu));
                $cu;
            }

            method load(IO::Path:D $file --> CompUnit:D) {
                my $cu = self.next-repo.load($file);
                @log.push((FILE, ~$file, $cu));
                $cu;
            }

            method loaded(--> Empty) {}
            method id(--> 'logger') {}
            method path-spec(--> 'logger#') {}
            multi method gist(::?CLASS:D:) { self.path-spec }
        }).new;
}
