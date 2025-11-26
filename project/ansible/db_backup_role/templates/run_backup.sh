#!/bin/bash
/usr/bin/mysqldump --single-transaction --all-databases --routines --triggers --events > /backup/mysql/all-$(date +%F).sql