#!/usr/bin/env python3

import os
import sys
import shutil

# requires python 3.6

configFilesDir = "./kibana-observables-proxy"

listOfFiles = os.listdir(configFilesDir)

# find and replace kibana-observables
target = "kibana-observables"
replacement = "kibana-observables2"

try:
    sys.argv[1]
except:
    print("No argument passed")
    replacement = input("Input the name of the kibana-proxy: ").lower()
else:
    print("Argument: [%s]" % sys.argv[1])
    replacement = sys.argv[1].lower()
    print("Using [%s] as the kibana-proxy's name " % (replacement))

# Make export directory
export_dir = "%s/export/%s" % (".", replacement)
if os.path.isdir(export_dir):
    yn = input(
        "[%s] already exists.  Do you want to overwrite? [Yn]" % (export_dir)
    ).lower()
    if yn == "y":
        shutil.rmtree(export_dir)
    else:
        print("Not deleting.  Bye!")
        quit()
if not os.path.isdir(export_dir):
    # make an export directory
    try:
        os.makedirs(export_dir)
    except OSError:
        print("Creation of the directory %s failed" % (export_dir))
    else:
        print("Successfully created the directory %s " % export_dir)

# find and replace
for file in listOfFiles:
    fin = open("%s/%s" % (configFilesDir, file), "rt")
    split = os.path.splitext(file)
    name = split[0]
    ext = split[1]

    fout = open("%s/%s%s" % (export_dir, name, ext), "wt")

    for line in fin:
        fout.write(line.replace(target, replacement))

    fin.close()
    fout.close()

print("Done Builder")
print(
    "Next step is to apply the Grey Matter objects (in %s) to the mesh." % (export_dir)
)
