#!/usr/bin/env python

import sys

try:
	import foo
except ImportError:
    sys.exit("""You need foo!
                install it from http://pypi.python.org/pypi/foo
                or run pip install foo.""")
