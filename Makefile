test:
	cat freeze.p6 test.p6 | perl6 -Ilib -
	cat jail.p6 test.p6 | perl6 -

clean:; rm -rf *.moarvm
