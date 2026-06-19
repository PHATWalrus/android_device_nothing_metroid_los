cd ~/dev/metroid/lineage/device/nothing/metroid
rm -f proprietary-files-clean.txt
while IFS= read -r line; do
  [ -z "$line" ] && continue
  clean_line="${line#- }"
  clean_line="${clean_line%%|*}"
  if [ -e "../../../vendor/nothing/metroid/proprietary/$clean_line" ] || [ -L "../../../vendor/nothing/metroid/proprietary/$clean_line" ]; then
    echo "$line" >> proprietary-files-clean.txt
  fi
done < proprietary-files.txt
mv proprietary-files-clean.txt proprietary-files.txt
./setup-makefiles.sh
