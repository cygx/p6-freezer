test:
	cat freeze.p6 test.p6 | perl6 -Ilib -
	perl6 --target=mbc --output=store.moarvm store.pm
	cat load.p6 test.p6 | perl6 -

jail-test:
	cat jail.p6 test.p6 | perl6 -

log:
	cat logger.p6 test.p6 | perl6 -Ilib -

clean:; rm -rf *.moarvm lib/.precomp
