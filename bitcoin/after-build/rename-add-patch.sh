#!/bin/bash

echo
echo "Attention:"
echo "You should run this script in the directory where you copied the binary files"
echo "resulting from the Gitian build you done (the .exe, .dmg, .tar.gz with linux binary and so on)"
echo "Enter the name of this build (patchname), for example we used name:"
patchname_default="uasfsegwit1.0"
echo "$patchname_default"
echo "Enter this name or other (empty name will end this script)."
read  -p "Patchname for this files: " -i "$patchname_default" patchname

if [[ -z "$patchname" ]]
then
	exit
fi

version_and_patch='unknown' # we will detect the full name like bitcoin-0.14.2-uasfsegwit1.0
# from looking at the files we process

while IFS= read -r fname; do
	expr='s/^\(bitcoin\)-\([0-9]\+.[0-9]\+.[0-9]\+\)\(.*\)$/\1-\2-'"$patchname"'\3/g'
	expr_get_version='s/^\(bitcoin\)-\([0-9]\+.[0-9]\+.[0-9]\+\)\(.*\)$/\1-\2/g'

	fname2=$(echo "$fname" | sed -e "$expr")
	if [[ "$fname" != "$fname2" ]]
	then
		version_and_patch=$(echo "$fname" | sed -e "$expr_get_version")

		if [[ "$fname" =~ $patchname ]]
		then
			echo
			echo "Already renamed $fname - skipping it"
			continue
		fi
		if [[ "$fname" =~ .sums. ]]
		then
			continue
		fi

		echo
		echo "Will rename:"
		echo "$fname"
		echo "$fname2"
		mv -i "$fname" "$fname2" || exit 1
	fi
done < <(ls)
echo "Renamed files to $patchname."

mkdir -p debug
mv -i *-debug* debug/

echo
echo "Checksums for $version_and_patch"
checksums_fname="$version_and_patch.sums.sha256"
if [[ -e "$checksums_fname" ]]
then
	rm "$checksums_fname"
fi
sha256sum * debug/* | grep -v .sh | sort --key 2 > "$checksums_fname"
echo "Checksums saved to $checksums_fname"

