#!/bin/bash
read -d '' awkScript << 'EOF'
{if($6>1998) {print > "lineorder_1998.tbl"}
 else if ($6>1997) {print > "lineorder_1997.tbl"}
 else if ($6>1996) {print > "lineorder_1996.tbl"}
 else if ($6>1995) {print > "lineorder_1995.tbl"}
 else if ($6>1994) {print > "lineorder_1994.tbl"}
 else if ($6>1993) {print > "lineorder_1993.tbl"}
 else if ($6>1992) {print > "lineorder_1992.tbl"}
 else {print > "lineorder_other.tbl"}}
EOF
awk -F '|' "$awkScript" lineorder.tbl

if [ -f "lineorder_other.tbl" ]; then
  echo "ERROR: data generated to lineorder_other.tbl file which is not expected, please verify"
  exit 1
fi

mv lineorder_1992.tbl lineorder_sorted.tbl
for y in 1993 1994 1995 1996 1997 1998; do
  cat lineorder_$y.tbl >> lineorder_sorted.tbl
  #rm -f lineorder_$y.tbl
done
