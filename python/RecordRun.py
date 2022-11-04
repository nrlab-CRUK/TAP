#!/usr/bin/env python3

import argparse
import datetime
import json
import mysql.connector as mariadb
import os
import sys


class RecordRun:
    def __init__(self):
        self.parser = argparse.ArgumentParser(description="RecordRun.py - Record the execution of the TAP into the database.")
        self.parser.add_argument("--infofile", help="The pipeline parameters in JSON format.", type=str, required=False)
        self.parser.add_argument("files", help="The name of the BAM file with a list of SLX ids in it. Separator is '/'.", type=str, nargs='*')

    def inClauseMarkers(self, parts):
        list = ['%s'] * len(parts)
        clauses = ','.join(list)
        return f"({clauses})"

    def run(self):
        args = self.parser.parse_args()

        pipelineParams = dict()
        pipelineRunId = None
        pipelineRunName = None

        if args.infofile:
            with open(args.infofile, "r") as fh:
                pipelineParams = json.load(fh)
                pipelineRunId = pipelineParams['runUUID']
                pipelineRunName = pipelineParams['runName']

        with mariadb.connect(host="10.20.14.24", database="rosenfeld", user="mysql") as connection:
            with connection.cursor() as insertCursor:
                with connection.cursor() as selectCursor:

                    proceed = True
                    if pipelineRunId is not None:
                        selectCursor.execute("SELECT id FROM rosenfeld_TAPRun WHERE runuuid = %s", [pipelineRunId])

                        if selectCursor.fetchone():
                            print(f"Run {pipelineRunId} has already been recorded.")
                            proceed = False

                    if proceed:
                        insertCursor.execute("INSERT INTO rosenfeld_TAPRun (runner, runtime, runname, runuuid) VALUES (%s, %s, %s, %s)",
                                             (os.getlogin(), datetime.datetime.now(), pipelineRunName, pipelineRunId))
                        runid = insertCursor.lastrowid

                        for fileinfo in sys.argv[1:]:
                            parts = fileinfo.split('/')
                            filename = parts[0]
                            slxIds = parts[1:]

                            insertCursor.execute("INSERT INTO rosenfeld_TAPRunFile (runid, filename) VALUES (%s, %s)", (runid, filename))
                            infoid = insertCursor.lastrowid

                            if len(slxIds) > 0:
                                inClause = self.inClauseMarkers(slxIds)
                                selectCursor.execute(f"SELECT id FROM rosenfeld_Sequence WHERE SLX_id IN {inClause}", tuple(slxIds))

                                for sequenceTuple in selectCursor:
                                    insertCursor.execute("INSERT INTO rosenfeld_TAPRunFile_Sequence_Join (sequenceid, taprunfileid) VALUES (%s, %s)", (sequenceTuple[0], infoid))

            connection.commit()


if __name__ == '__main__':
    RecordRun().run()
