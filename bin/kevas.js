#!/usr/bin/env node
require('./command')(process.argv[2..], process.stdin, process.stdout);
