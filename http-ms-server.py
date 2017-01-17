#!/usr/bin/python

import requests
import json
import datetime
import sys
import argparse

def sendHttp(arg,start,totalEnd,step):
    print(datetime.datetime.now())
    end = start + step
    
    while end <= totalEnd:
        a = datetime.datetime.now()
        for i in range(start,end):
            deleteUrl = 'http://localhost:8090/api/security/clients/aaaa' + str(i)
            addurl = 'http://localhost:8090/api/security/clients'
            if arg == "add":
                endPoint = 'aaaa' + str(i)
                secretKey = '04030201'
                data = json.dumps({"endpoint":endPoint,"psk":{"identity":endPoint,"key":secretKey}})
                resp = requests.put(addurl, data) 
            elif arg == "remove":
                resp = requests.delete(deleteUrl)
            else:
                print("None")
                sys.exit(2)
            if not (resp.status_code == requests.codes.ok or resp.status_code == requests.codes.no_content) :
                print("FAIL")
                print resp.status_code, resp.text, resp.headers
        b = datetime.datetime.now()
        delta = b - a
        print(delta.total_seconds())
        print("start ", start, "end ", end )
        start += step
        end = start + step

def main(argv):
    arg = ""
    start = 0
    step = 10
    end = 100
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['add','rem'], help="add|remove client endPoints")
    parser.add_argument('-start', type=int, action='store', nargs='?', 
                        default=start, help="start index (default: %(default)s)")
    parser.add_argument('-end', type=int, action='store', nargs='?', 
                        default=end, help="end index (default: %(default)s)")
    parser.add_argument('-step', type=int, action='store', nargs='?', 
                        default=step, help="step of index (default: %(default)s)")
    args = parser.parse_args()
    print(args)
    if args.mode == 'add':
        arg = "add"
    elif args.mode == 'rem':
        arg = "remove"
    if args.start:
        start = args.start
    if args.step:
        step = args.step
    if args.end:
        end = args.end

    sendHttp(arg,start,end,step)

if __name__ == "__main__":
   main(sys.argv[1:])

