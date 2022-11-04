#!/usr/bin/env python3

import argparse
import datetime
import mysql.connector as mariadb
import os
import sys

def inClauseMarkers(parts):
    list = ['%s'] * len(parts)
    clauses = ','.join(list)
    return f"({clauses})"

with mariadb.connect(host="10.20.14.24", database="rosenfeld", user="mysql") as connection:
    with connection.cursor() as insertCursor:
        with connection.cursor() as selectCursor:
            insertCursor.execute("INSERT INTO rosenfeld_TAPRun (runner, runtime) VALUES (%s, %s)", (os.getlogin(), datetime.datetime.now()))
            runid = insertCursor.lastrowid
    
            for fileinfo in sys.argv[1:]:
                parts = fileinfo.split('/')
                filename = parts[0]
                slxIds = parts[1:]

                insertCursor.execute("INSERT INTO rosenfeld_TAPRunFile (runid, filename) VALUES (%s, %s)", (runid, filename))
                infoid = insertCursor.lastrowid
                
                if len(slxIds) > 0:
                    selectCursor.execute(f"SELECT id FROM rosenfeld_Sequence WHERE SLX_id IN {inClauseMarkers(slxIds)}", tuple(slxIds))
                    
                    for sequenceTuple in selectCursor:
                        print(f"Have sequence id {sequenceTuple[0]} for {slxIds}")
                        insertCursor.execute("INSERT INTO rosenfeld_TAPRunFile_Sequence_Join (sequenceid, taprunfileid) VALUES (%s, %s)", (sequenceTuple[0], infoid))
        
    connection.commit()
