# Copyright 2023 Jacques de Laval
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the “Software”), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

assert() {
	ASSERTIONS_TOTAL="$((ASSERTIONS_TOTAL + 1))"
	if eval "test $*"; then
		ASSERTIONS_PASSED="$((ASSERTIONS_PASSED + 1))"
		printf "\t$CSI%sm✔" "$FG_GREEN"
	else
		printf "\t$CSI%sm✘" "${FG_RED}"
	fi
	printf "$CSIRST %s\n" "$*"
}

header() {
	printf "$CSI${FG_BLACK};${2}m%-80s$CSIRST\n" "$1"
}

say() {
	printf "$CSI%sm%s$CSIRST\n" "$FG_BLUE" "$*"
}

dbg() {
	[ "$VERBOSE" -gt 0 ] && printf "$CSI%sm%s$CSIRST\n" "$FG_YELLOW" "$*"
	return 0
}

run() {
	dbg 'run' "$@"
	"$@"
}

test_end() {
	if [ "$?" -ne 0 ]; then
		status='Invalid'
		bg="$BG_YELLOW"
		err=2
	elif [ "$ASSERTIONS_PASSED" -ne "$ASSERTIONS_TOTAL" ]; then
		status='Failed'
		bg="$BG_RED"
		err=1
	else
		status='Passed'
		bg="$BG_GREEN"
		err=0
	fi

	command -v teardown > /dev/null && teardown

	passed="passed $ASSERTIONS_PASSED"/"$ASSERTIONS_TOTAL"
	header "TEST $TEST_NAME: $status ($passed assertions)" "$bg"
	if in_suite; then
		echo "TEST $TEST_NAME: $status ($passed assertions)" \
			>> "$SUITE_RESULTS"
	fi

	return "$err"
}

test_start() {
	set -e

	[ "$VERBOSE" -gt 1 ] && set -x

	ASSERTIONS_TOTAL=0
	ASSERTIONS_PASSED=0

	TEST_NAME="$(basename -s.test "$0") $*"

	in_suite && echo
	header "TEST $TEST_NAME" "$FG_WHITE"

	trap 'test_end' EXIT

	return 0
}

in_suite() {
	[ -f "$SUITE_RESULTS" ] || return 1
}

suite_end() {
	echo
	header "SUITE $(basename -s.suite "$0") summary" \
	       "$BOLD;$FG_WHITE;$BG_BRIGHT_BLACK"
	cat "$SUITE_RESULTS"
	passing="$(grep -c ': Passed' "$SUITE_RESULTS")"
	failing="$(grep -c ': Failed' "$SUITE_RESULTS")"
	invalid="$(grep -c ': Invalid' "$SUITE_RESULTS")"
	echo Total passing/failing/invalid: "$passing/$failing/$invalid"
	rm "$SUITE_RESULTS"

	if [ "$failing" -gt 0 ] && [ "$invalid" -gt 0 ]; then
		exit 3
	elif [ "$invalid" -gt 0 ]; then
		exit 2
	elif [ "$failing" -gt 0 ]; then
		exit 1
	fi
}

suite_start() {
	header "SUITE $(basename -s.suite "$0") $*" \
	       "$BOLD;$FG_WHITE;$BG_BRIGHT_BLACK"
	trap 'suite_end' EXIT
	SUITE_RESULTS="$(mktemp)"
	export SUITE_RESULTS
}

# Select Graphic Rendition
CSI='\033['
CSIRST='\033[0m'
BOLD=1
eval "$(
	i=0
	for color in BLACK RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
		echo FG_"$color"="3$i"
		echo BG_"$color"="4$i"
		echo FG_BRIGHT_"$color"="9$i"
		echo BG_BRIGHT_"$color"="10$i"
		i=$((i + 1))
	done
)"

VERBOSE="${VERBOSE:-0}"
[ "$1" = "-v" ] && VERBOSE=1 && shift
[ "$1" = "-vv" ] && VERBOSE=2 && shift
export VERBOSE

if [ "${SUITE:=0}" -eq 1 ]; then
	SUITE=0
	export SUITE
	suite_start "$@"
else
	test_start "$@"
fi
