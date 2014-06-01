#!/usr/bin/env python3
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

import time
import json
import urllib.request
import os

def start():
    while  True:
        check_update()
        time.sleep(10800)  # wait 3 hours

def check_update():
    url = 'https://api.github.com/repos/OpenRA/OpenRA/git/refs/tags'
    try:
        stream = data_from_url(url, None)
    except Exception as e:
        print("*** %s ***" % e)
        return
    release, release_url, release_commit = get_version(stream, 'release')
    playtest, playtest_url, playtest_commit = get_version(stream, 'playtest')
    serverdata = {}
    serverdata['release'] = release
    serverdata['playtest'] = playtest
    try:
        file = open('version.txt', 'r')
        filedata = file.readlines()
        file.close()
    except:
        open('version.txt','w').close()

    if ( filedata == [] ):
        flush(json.dumps(serverdata))
        return
    
    filedata_in_json = json.loads(filedata[0])

    # run prepared bash script to fetch tarball, compile and set up a server in screen session
    if release != filedata_in_json['release']:
        os.system("./setup-openra.sh -v %s -u %s -c %s" % (release, release_url, release_commit) )
        filedata_in_json['release'] = release
        flush(json.dumps(filedata_in_json))
    if playtest != filedata_in_json['playtest']:
        os.system("./setup-openra.sh -v %s -u %s -c %s" % (playtest, playtest_url, playtest_commit) )
        filedata_in_json['playtest'] = playtest
        flush(json.dumps(filedata_in_json))

def get_version(stream, version):
    result = []
    y = json.loads(stream)
    for item in y:
        if version in item['ref']:
            result = [item['ref'].split('tags/')[1], 'https://github.com/OpenRA/OpenRA/tarball/'+item['ref'].split('tags/')[1], item['object']['sha'][0:7]]
            break
    return result

def flush(data):
        file = open('version.txt', 'w')
        file.write(data)
        file.close()

def data_from_url(url, bytes):
    opener = urllib.request.build_opener()
    opener.addheaders = [('User-agent', 'Mozilla/5.0')] # fake our user-agent
    data = opener.open(url).read(bytes)
    try:
        encoding = str(data).lower().split('charset=')[1].split('"')[0]
        data = data.decode(encoding)
    except: # encoding was not found
        data = data.decode('utf-8')
    return data

start()
