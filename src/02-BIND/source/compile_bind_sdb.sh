#!/bin/bash
#
# compile_bind_sdb.sh
#
# Copyright (C) 2016 frnmst (Franco Masotti) <franco.masotti@student.unife.it>
#                    dannylessio (Danny Lessio)
#
# This file is part of networks-lab.
#
# networks-lab is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# networks-lab is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with networks-lab.  If not, see <http://www.gnu.org/licenses/>.
#


# Variable definitions
bindDir="bind-9.9.7"
bindSdbDir="bind-sdb-ldap-1.0"
usrIncludeDir="/usr/include"
usrLibDir="/usr/lib"


cp "$bindSdbDir/ldapdb.c" "$bindDir/bin/named"
cp "$bindSdbDir/ldapdb.h" "$bindDir/bin/named/include"

# sed scrive male in Makefile.in
#sed "s/DBDRIVER_OBJS*/DBDRIVER_OBJS = ldapdb.@O@/" "$bindDir/bin/named/Makefile.in"
#sed "s/DBDRIVER_SRCS*/DBDRIVER_SRCS = ldapdb.c/" "$bindDir/bin/named/Makefile.in"
#sed "s/DBDRIVER_INCLUDES*/DBDRIVER_INCLUDES = -I$usrIncludeDir/" "$bindDir/bin/named/Makefile.in"
#sed "s/DBDRIVER_LIBS*/DBDRIVER_LIBS = -L$usrLibDir -lldap -llber -lresolv/" "$bindDir/bin/named/Makefile.in"

# Delete any previous entries.
sed -i "/ldapdb.h\|ldapdb_init()\|ldap_clear()/ d" "$bindDir/bin/named/main.c"
# Add new entries.
sed -i '/#include \"xxdb.h\"/a #include <ldapdb.h>' "$bindDir/bin/named/main.c"
sed -i '/xxdb_init();/a ldapdb_init();' "$bindDir/bin/named/main.c"
sed -i '/xxdb_clear();/a ldapdb_clear();' "$bindDir/bin/named/main.c"

cd "$bindDir"
./configure
make
sudo make install

# Write systemd file

#sudo systemctl daemon-reload
