test:
	cat freeze.p6 test.p6 | perl6 -Ilib -
	cat jail.p6 test.p6 | perl6 -

log:
	cat logger.p6 test.p6 | perl6 -Ilib -

clean:; rm -rf *.moarvm
