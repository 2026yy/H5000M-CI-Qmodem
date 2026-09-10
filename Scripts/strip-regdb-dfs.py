#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Strip DFS channel flags from wireless-regdb db.txt without touching DFS-ETSI/FCC/JP."""
from __future__ import annotations

import re
import sys
from pathlib import Path


def strip_dfs_flags(text: str) -> str:
	text = re.sub(r", DFS", "", text)
	text = re.sub(r" DFS,", " ", text)
	text = re.sub(r" DFS$", "", text, flags=re.M)
	return text


def main() -> int:
	if len(sys.argv) != 2:
		print(f"usage: {sys.argv[0]} <db.txt>", file=sys.stderr)
		return 2
	path = Path(sys.argv[1])
	original = path.read_text(encoding="utf-8")
	updated = strip_dfs_flags(original)
	path.write_text(updated, encoding="utf-8")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
