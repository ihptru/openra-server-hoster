#!/bin/bash
#
# Copyright 2013 ihptru (Igor Popov)
#
# This file is part of openra-server-hoster, which is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

usage() { echo "Usage: $0 -v <version> -u <url> -c <commit_tag>" 1>&2; exit 1; }

while getopts ":v:u:c:" o; do
    case "${o}" in
        v)
            OPENRA_VERSION=${OPTARG}
            ;;
        u)
            OPENRA_URL=${OPTARG}
            ;;
        c)
            OPENRA_COMMIT=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${OPENRA_VERSION}" ] || [ -z "${OPENRA_URL}" ] || [ -z "${OPENRA_COMMIT}" ]; then
    usage
fi

cd dump

wget --no-check-certificate "${OPENRA_URL}" > /dev/null 2>&1

tar -xzvf "${OPENRA_VERSION}" > /dev/null 2>&1

cd OpenRA-OpenRA-${OPENRA_COMMIT}

make all > make_log 2>&1

cat mods/ra/mod.yaml | perl -0777 -ne "s/Version: {DEV_VERSION}/Version: ${OPENRA_VERSION}/g;print" > temp
cat temp > mods/ra/mod.yaml

cat mods/cnc/mod.yaml | perl -0777 -ne "s/Version: {DEV_VERSION}/Version: ${OPENRA_VERSION}/g;print" > temp
cat temp > mods/cnc/mod.yaml

cat mods/d2k/mod.yaml | perl -0777 -ne "s/Version: {DEV_VERSION}/Version: ${OPENRA_VERSION}/g;print" > temp
cat temp > mods/d2k/mod.yaml

PORT_N=`shuf -i 1235-4999 -n 1`

screen -dmS ${OPENRA_VERSION}_ra bash -c "mono OpenRA.Game.exe Game.Mod=ra Server.Dedicated=True Server.Name=ihptru-ra Server.ListenPort=${PORT_N} Server.ExternalPort=${PORT_N} Server.AdvertiseOnline=True"
echo "Hosted RA version ${OPENRA_VERSION}"

PORT_N=`shuf -i 1235-4999 -n 1`

screen -dmS ${OPENRA_VERSION}_cnc bash -c "mono OpenRA.Game.exe Game.Mod=cnc Server.Dedicated=True Server.Name=ihptru-cnc Server.ListenPort=${PORT_N} Server.ExternalPort=${PORT_N} Server.AdvertiseOnline=True"
echo "Hosted CNC version ${OPENRA_VERSION}"

PORT_N=`shuf -i 1235-4999 -n 1`

screen -dmS ${OPENRA_VERSION}_d2k bash -c "mono OpenRA.Game.exe Game.Mod=d2k Server.Dedicated=True Server.Name=ihptru-d2k Server.ListenPort=${PORT_N} Server.ExternalPort=${PORT_N} Server.AdvertiseOnline=True"
echo "Hosted D2K version ${OPENRA_VERSION}"
