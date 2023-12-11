#!/bin/bash
for A in $(ssh administrator@virtwin net sess|grep "\.2. "|cut -d" " -f1); do ssh administrator@virtwin net sess $A /delete /y; done
