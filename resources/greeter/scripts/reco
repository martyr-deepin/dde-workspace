#!/usr/bin/env python2

# Copyright (c) 2011 ~ 2012 Deepin, Inc.
#               2011 ~ 2012 Liqiang Lee
#
# Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
# Maintainer:  Liqiang Lee <liliqiang@linuxdeepin.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.


from __future__ import print_function
import sys

from facepp import File, API

API_KEY = '0b8c0488e457432f04e38b79982f66db'
API_SCRET ='Bs-ncYt88ewu9euvhBzVo6YjHDzxJpTG'

TARGET_IMAGE = '/tmp/deepin_user_face.png'
GROUP_NAME = 'User'


from pprint import pformat


def print_result(hint, result):
    def encode(obj):
        if type(obj) is unicode:
            return obj.encode('utf-8')
        if type(obj) is dict:
            return {encode(k): encode(v) for (k, v) in obj.iteritems()}
        if type(obj) is list:
            return [encode(i) for i in obj]
        return obj
    print(hint)
    result = encode(result)
    prefix = '  ' if hint else ''
    print('\n'.join([prefix + i for i in pformat(result, width =
        75).split('\n')]))


api = API(API_KEY, API_SCRET, timeout=10, max_retries=3)

try:
    result = api.recognition.recognize(img=File(TARGET_IMAGE), group_name=GROUP_NAME)
except:
    print("has no target image")
    sys.exit(1)

try:
    print(result['face'][0]['candidate'][0]['person_name'], end='')
except:
    print_result('[Error]: ', result)

