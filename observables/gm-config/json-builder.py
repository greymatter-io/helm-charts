#!/usr/bin/env python3

import os
import sys
import shutil

# requires python 3.6
path = os.getcwd()
path = path + "/observables/gm-config"

spire = input("Is SPIRE enabled? True or False: ")
if spire == "True":
    configFilesDir = path + "/kibana-observables-proxy-spire"
else:
    configFilesDir = path + "/kibana-observables-proxy"

listOfFiles = os.listdir(configFilesDir)

# find and replace kibana-observables
target = "kibana-name"
replacement = "kibana-observables-proxy"
ns_target = "obs-namespace"
ns_replacement = "observables"
display_target = "display-name"
display_name = "Kibana Proxy"

try:
    sys.argv[1]
except:
    print("No argument for observables namespace passed, using default \"observables\"")
    ns_replacement = "observables"
else:
    print("Argument: [%s]" % sys.argv[1])
    ns_replacement = sys.argv[1].lower()
    print("Using [%s] as the observables namespace " % (ns_replacement))

try:
    sys.argv[2]
except:
    print("No argument for Kibana display name passed, using default \"Kibana Observables Proxy\"")
    display_name = "Kibana Observables Proxy"
else:
    print("Argument: [%s]" % sys.argv[2])
    display_name = sys.argv[2]
    print("Using [%s] as the display name " % (display_name))

try:
    sys.argv[3]
except:
    print("No argument for kibana name passed, using default \"kibana-observables-proxy\"")
    replacement = "kibana-observables-proxy"
else:
    print("Argument: [%s]" % sys.argv[3])
    replacement = sys.argv[3].lower()
    print("Using [%s] as the kibana-proxy's name " % (replacement))

# Make export directory
export_dir = "%s/export/%s" % (path, replacement)
if os.path.isdir(export_dir):
    yn = input(
        "[%s] already exists.  Do you want to overwrite? [Yn] \n" % (export_dir)
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
        if file == "00.cluster.json":
            line = line.replace(target, replacement)
            line = line.replace(ns_target, ns_replacement)
            fout.write(line)
        elif file == "06.catalog.json":
            line = line.replace(target, replacement)
            line = line.replace(display_target, display_name)
            fout.write(line)
        elif (file == "create.sh") or (file == "delete.sh"):
            line = line.replace(target, replacement)
            line = line.replace("path-to-dir", export_dir)
            fout.write(line)
        else:
            fout.write(line.replace(target, replacement))

    fin.close()
    fout.close()

os.chmod(export_dir + "/create.sh", 0o777)
os.chmod(export_dir + "/delete.sh", 0o777)

print(
    "Success! To apply, run \'./observables/gm-config/export/kibana-observables-proxy/create.sh\'"
)
