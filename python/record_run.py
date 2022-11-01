#!/usr/bin/env python3

import argparse
import datetime
import mysql.connector as mariadb
import os
import sys

with mariadb.connect(host="10.20.14.24", database="rosenfeld", user="mysql") as connection:
    with connection.cursor() as cursor:
        cursor.execute("INSERT INTO rosenfeld_TAPRun (runner, runtime) VALUES (%s, %s)", (os.getlogin(), datetime.datetime.now()))
        runid = cursor.lastrowid

        for file in sys.argv[1:]:
            cursor.execute("INSERT INTO rosenfeld_TAPRunFile (runid, filename) VALUES (%s, %s)", (runid, file))
        
    connection.commit()
