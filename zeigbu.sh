#!/bin/bash
ps -Alf|egrep 'bu[^gs]'|grep -v grep
