#!/bin/bash
/usr/bin/mysqldump --single-transaction --all-databases --routines --triggers --events --set-gtid-purged=OFF > /backup/mysql/all-$(date +'%F_%T').sql