#!/bin/python
# find_charts.py
# Find all directories with a charts.yaml file in them and write the list to charts.txt

import yaml
import os


# from https://stackoverflow.com/a/800201
def get_immediate_subdirectories(a_dir):
    return [
        name for name in os.listdir(a_dir) if os.path.isdir(os.path.join(a_dir, name))
    ]


def dir_has_chart(dir_list):
    return [
        dir for dir in dir_list if os.path.exists(os.path.join(".", dir, "Chart.yaml"))
    ]


def write_list_to_file(a_list):
    with open("charts.txt", "w") as f:
        for item in a_list:
            f.write("%s\n" % item)


if __name__ == "__main__":
    # get all the directories
    directories = get_immediate_subdirectories(".")

    defaultServices = set(dir_has_chart(directories)).difference(set(["greymatter"]))

    print(defaultServices)

    write_list_to_file(defaultServices)
