#!/bin/bash

set -e

dir="$1"

if [ ! -d "$dir" ]; then
    echo "dir missing :(" >&2
    exit 1
fi

godi_gui_dir="${dir}/gui"
godi_root_dir="$(dirname "$(godi_confdir)")"
godi_bin_dir="${godi_root_dir}/bin"


if [ -z "$OBJDUMP" ]; then
    echo "OBJDUMP not defined" >&2
    exit 1
fi

if ! mkdir -p "${godi_gui_dir}/bin" \
    "${godi_gui_dir}/etc" \
    "${godi_gui_dir}/lib" \
    "${godi_gui_dir}/share/themes" 
then
    exit 1
fi


cdir="$(pwd)"

cd "${godi_bin_dir}"
cp -p gspawn-win*-helper*.exe "${godi_gui_dir}/bin"
cd "$cdir"

cp -a "${godi_root_dir}/etc/fonts" "${godi_gui_dir}/etc"
cp -a "${godi_root_dir}/etc/gtk-2.0" "${godi_gui_dir}/etc"
cp -a "${godi_root_dir}/lib/gtk-2.0" "${godi_gui_dir}/lib"
cp -a "${godi_root_dir}/lib/gdk-pixbuf-2.0" "${godi_gui_dir}/lib"
cp -a "${godi_root_dir}/lib/pango" "${godi_gui_dir}/lib"
cp -a "${godi_root_dir}/lib/libglade" "${godi_gui_dir}/lib"
cp -a "${godi_root_dir}/share/themes/MS-Windows" "${godi_gui_dir}/share/themes"
cp -a "${godi_root_dir}/share/gtksourceview-2.0" "${godi_gui_dir}/share"


cd "${godi_gui_dir}/share/gtksourceview-2.0/language-specs/"
for f in *.* ; do
    [ ! -f "$f" ] && continue
    case "$f" in
        c.lang|cpp.lang|def.lang|language.rng|language2.rng|ocaml.lang|styles.rng)
            continue
            ;;
        *)
            rm "$f"
    esac
done
cd "$cdir"


#1: found
#2: checked
declare -A mymap

cd "${godi_bin_dir}"
for f in \
    libgobject*.dll \
    libglib*.dll \
    libgtk-win32*.dll \
    libgdk*.dll \
    libpango*.dll \
    libgtksourceview*.dll \
    libglade*.dll \
    libgnomecanvas*.dll \
    libgtkspell*.dll \
    librsvg*.dll \
    libcurl*.dll
do
    [ ! -f "$f" ] && continue
    mymap[$f]=1
done
cd ~-

list_dlls(){
    $OBJDUMP -p "$1" | /bin/grep 'DLL Name:' | /bin/awk '{print $3}'
    $STRINGS "$1" | /bin/grep '.dll$'
}

oldIFS=$IFS
IFS='
'
new_found=1
while [ $new_found -eq 1 ]; do
    new_found=0
    for dll in ${!mymap[@]} ; do
	value=${mymap[$dll]}
	if [ $value -eq 1 ]; then
	    mymap[$dll]=2
	    cp -p "${godi_bin_dir}/${dll}" "${godi_gui_dir}/bin"
	    for ndll in $(list_dlls "${godi_bin_dir}/${dll}") ; do
		if [ -z "$ndll" ] || [ ! -f "${godi_bin_dir}/${ndll}" ] \
		    || [ "${mymap[$ndll]}" = "1" ] || [ "${mymap[$ndll]}" = "2" ] ; then
		    continue
		fi
		mymap[$ndll]=1
		new_found=1
	    done
	fi
    done
done

IFS=$oldIFS

find "${godi_gui_dir}" -type l -delete
find "${godi_gui_dir}" -type f -name '*~' -delete
find "${godi_gui_dir}" -type f -name '*README*' -delete
find "${godi_gui_dir}" -type d -empty -delete

exit 0
