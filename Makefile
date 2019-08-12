test:
	cat freeze.p6 test.p6 | perl6 -Ilib -
	perl6 obj.p6 *.moarvm
	perl6 dll.p6 *.o | gcc -shared -o store.dll *.o -xc -
	cat dllload.p6 test.p6 | perl6 -

freeze:
	cat freeze.p6 test.p6 | perl6 -Ilib -

jail-test:
	cat jail.p6 test.p6 | perl6 -

objects:
	perl6 obj.p6 *.moarvm

dll:
	perl6 dll.p6 *.o | gcc -shared -o store.dll *.o -xc -

log:
	cat logger.p6 test.p6 | perl6 -Ilib -

clean:; rm -rf *.moarvm lib/.precomp *.o *.dll
