#!/bin/sh
swaynag -m 'Do you want shutdown or hibernate?' -b 'Poweroff' 'poweroff' -b 'Hibernate' 'systemctl hibernate'
