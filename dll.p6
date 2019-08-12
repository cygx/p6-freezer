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


my @store;

for @*ARGS.sort {
    unless /^ [ 'no-auth' | 'auth-' <auth=&encoded> ]
              '.' <name=&encoded>
              '.' [ 'no-ver' | 'ver-' <ver=&encoded> ]
              '.o' $/ {
        say "skipped $_";
        next;
    }

    my $ident = 'mbc_' ~ join 'I',
        $<auth> ?? $<auth>.lc !! 'X',
        $<name>.lc,
        $<ver> ?? $<ver>.lc !! 'X';

    my $name  = $<name>.made.perl;
    my $auth  = ($<auth> andthen .made.perl) || 'NULL';
    my $ver   = ($<ver>  andthen .made.perl) || 'NULL';
    my $size  = S/\.o$/.moarvm/.IO.s;

    @store.push: %(:$ident, :$name, :$auth, :$ver, :$size);
}

say q:to/CODE_END/;
    #include <stdint.h>
    #include <string.h>
    CODE_END

say "extern const uint8_t {.<ident>}\[];"
    for @store;

say "";

say q:to/CODE_END/;
    static const struct {
        const uint8_t *bc;
        size_t size;
        const char *name, *auth, *ver; } STORE[] = {
    CODE_END

say "    \{ {.<ident>}, {.<size>}, {.<name>}, {.<auth>}, {.<ver>} },"
    for @store;

say q:to/CODE_END/;
    };

    enum { STORE_LEN = sizeof STORE / sizeof *STORE };

    __declspec(dllexport)
    size_t mbc_size(uint32_t idx)
    {
        return idx < STORE_LEN ? STORE[idx].size : 0;
    }

    __declspec(dllexport)
    void mbc_copy(uint32_t idx, void *buf)
    {
        if(idx < STORE_LEN)
            memcpy(buf, STORE[idx].bc, STORE[idx].size);
    }

    __declspec(dllexport)
    const char *mbc_name(uint32_t idx)
    {
        return idx < STORE_LEN ? STORE[idx].name : NULL;
    }

    __declspec(dllexport)
    const char *mbc_auth(uint32_t idx)
    {
        return idx < STORE_LEN ? STORE[idx].auth : NULL;
    }

    __declspec(dllexport)
    const char *mbc_ver(uint32_t idx)
    {
        return idx < STORE_LEN ? STORE[idx].ver : NULL;
    }
    CODE_END
