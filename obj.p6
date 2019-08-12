for @*ARGS {
    m/^ [ 'no-auth' | 'auth-' (\w+) ]
       '.' (\w+)
       '.' [ 'no-ver' | 'ver-' (\w+) ]
       '.moarvm' $/ or do {
       say "skipped $_";
       next;
    }

    my $file = $_;
    my $name = join 'I', $0 ?? $0.lc !! 'X', $1.lc, $2 ?? $2.lc !! 'X';
    my $obj = S/\.moarvm$/.o/;

    my @cmd = |<as - -o>, $obj;
    note '  ', @cmd.join(' ');
    
    .in.spurt(qq:to/EOF/, :close) given run :in, @cmd;
            .section .rodata
            .global mbc_{$name}
            .align  8
        mbc_{$name}:
            .incbin "$file"
        EOF
}
