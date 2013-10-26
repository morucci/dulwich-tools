#!/usr/bin/python
# swift-init-repo - Simple script to create an empty bare repo
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Fabien Boucher <fabien.boucher@enovance.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; version 2
# or (at your option) a later version of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.

import sys

from dulwich.swift import (
        SwiftConnector,
        SwiftRepo,
        load_conf,
        )

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    conf = load_conf()
    root = sys.argv[1]
    scon = SwiftConnector(root, conf)
    SwiftRepo.init_bare(scon, conf)

