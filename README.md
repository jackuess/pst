PST - Posix Shell Test helper
=============================

Super simple helper for writing tests with (posix) shell scripts.

PST provides an assert function, keeps track of test results and presents them.
That is pretty much it. PST also provides some help for organizing multiple
tests in suites.

- A test is considered invalid if any statement has non-zero exit status
- A test is considered failing if any assert evaluates to false
- ...otherwise the test is considered passing

Test suite example
------------------

**suite**

```sh
	#!/bin/sh

	SUITE=1 . pst.sh

	./failing.test
	./invalid.test
	./passing.test
```

**failing.test**

```sh
#!/bin/sh

. pst.sh"

return_1() {
	echo 1
}

say Test that 1 and 1 are equal
assert 1 -eq 1
say Test that 1 and 2 are also equal
assert 1 -eq 2
say Test that my function returns 2
assert '$(return_1)' -eq 2
say Test that my function returns 2
assert 2 -eq '$(return_1)'
say Test that my function returns 1
assert '$(return_1)' -eq 1
```

**invalid.test**

```sh
#!/bin/sh

. pst.sh"

return_1() {
	echo 1
}

teardown() {
	dbg Run teardown
}

assert 1 -eq 1
assert 1 -eq 2
assert '$(return_1)' -eq 2
false
assert '$(return_1)' -eq 1
```


**passing.test**

```sh
#!/bin/sh

. pst.sh"

return_1() {
	echo 1
}

assert 1 -eq 1
dbg DBG
assert '$(return_1)' -eq 1
```

**output (sans pretty colors)**

```sh
	$ ./suite -v
	SUITE suite

	TEST failing
	Test that 1 and 1 are equal
	        ✔ 1 -eq 1
	Test that 1 and 2 are also equal
	        ✘ 1 -eq 2
	Test that my function returns 2
	        ✘ $(return_1) -eq 2
	Test that my function returns 2
	        ✘ 2 -eq $(return_1)
	Test that my function returns 1
	        ✔ $(return_1) -eq 1
	TEST failing : Failed (passed 2/5 assertions)

	TEST invalid
	        ✔ 1 -eq 1
	        ✘ 1 -eq 2
	        ✘ $(return_1) -eq 2
	Run teardown
	TEST invalid : Invalid (passed 1/3 assertions)

	TEST passing
	        ✔ 1 -eq 1
	DBG
	        ✔ $(return_1) -eq 1
	TEST passing : Passed (passed 2/2 assertions)

	SUITE suite summary
	TEST failing : Failed (passed 2/5 assertions)
	TEST invalid : Invalid (passed 1/3 assertions)
	TEST passing : Passed (passed 2/2 assertions)
	Total passing/failing/invalid: 1/1/1
```

API
---

### assert

	assert <EXPRESSION>

Evaluates `EXPRESSION`, in the same manner as test(1). Marks the test as failing
if `EXPRESSION` evaluates to false. Basically implemented as `eval "test $*"`.

### dbg

	dbg <STRING>...

Prints `STRING(s)` if the flag `-v` was passed when starting the test or suite.

### run

	run <CMD> [ARG]...

If the flag `-v` was passed when starting the test or suite `CMD` is printed and
then executed. I the `-v` flag was not provided, `CMD` is simply executed.

### say

	dbg <STRING>...

Like `dbg`, but disregards `-v`.

### SUITE

	SUITE=<INT>

Set to `1` to distinguish a suite from a test.

### teardown

Optionally defined in test. Run after the test has finished, even if the test is
invalid (ie. some command exited with non-zero status).
