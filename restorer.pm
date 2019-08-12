use nqp;

my @loaded;
my $UNITS := nqp::hash();

my $repo := nqp::create(my class CompUnit::Repository::StoredJail
    does CompUnit::Repository {

    method need(CompUnit::DependencySpecification $specification,
                CompUnit::PrecompilationRepository $precomp?
                --> CompUnit:D) {

        my str $name = $specification.short-name;
        nqp::if(nqp::existskey($UNITS, $name),
            nqp::atpos(nqp::atkey($UNITS, $name), 0),
            X::CompUnit::UnsatisfiedDependency.new(:$specification).throw);
    }

    method resolve(CompUnit::DependencySpecification $spec --> CompUnit:D) {
        X::NYI.new(feature => "resolving modules").throw;
    }

    method load(IO::Path:D $file --> CompUnit:D) {
        X::NYI.new(feature => "loading modules by path").throw;
    }

    method loaded { @loaded.Seq }
    method id(--> "jail") {}
    method repo-chain { (self, ) }
    method path-spec { self.id ~ '#' }
    multi method gist(::?CLASS:D:) { self.path-spec }

});

my int $idxsize = nqp::stat('store.index', nqp::const::STAT_FILESIZE);
my $buf := buf8.allocate($idxsize);

my $idxfh := nqp::open('store.index', 'r');
nqp::readfh($idxfh, $buf, $idxsize);
nqp::closefh($idxfh);

my $lines := nqp::split("\0", nqp::decode($buf, 'utf8'));
my int $len = nqp::elems($lines);

my $datfh := nqp::open('store.data', 'r');

loop (my int $i = 0; $i < $len; $i = $i + 4) {
    my $name := nqp::atpos($lines, $i);
    my $auth := nqp::atpos($lines, $i + 1);
    my $ver := nqp::atpos($lines, $i + 2);
    my $version := nqp::if(nqp::chars($ver), Version.new($ver), Version);
    my int $bcsize = +nqp::atpos($lines, $i + 3);
    my $bc := nqp::readfh($datfh, buf8.allocate($bcsize), $bcsize);
    my $handle := CompUnit::Loader.load-precompilation($bc);
    my $unit := CompUnit.new(
        short-name => $name, :$version, :$auth,
        :$handle, :$repo, repo-id => "$i", :precompiled);

    my $list;
    nqp::if(nqp::existskey($UNITS, $name),
        ($list := nqp::atkey($UNITS, $name)),
        nqp::stmts(
            ($list := nqp::list()), nqp::bindkey($UNITS, $name, $list)));

    nqp::push($list, $unit);

    @loaded.push($unit);
}

nqp::closefh($datfh);

PROCESS::<$REPO> := $repo;
