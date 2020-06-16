#!/usr/bin/env python
# gen-docs.py
# This script generates documentation for the default values of Grey Matter services

import yaml
import os
import pprint
import sys
import re

import flatten_dict
from pytablewriter import MarkdownTableWriter

import collections
import argparse
import datetime
import logging

pp = pprint.PrettyPrinter(indent=4)

logging.basicConfig(
    level=logging.INFO, format="[%(name)s] - %(levelname)s: %(message)s"
)

startDT = datetime.datetime.now()

# The dot reducer or JS property access reducer reduces a nested dictionary into a string of the form `a.b.c`
# following JS property access notation
def dot_reducer(k1, k2):
    if k1 is None:
        return k2
    else:
        if type(k2) == int:
            return k1 + f"[{k2}]"
        return k1 + "." + k2


optionTableConfig = [
    {"name": "Parameter", "value": "k"},
    {"name": "Description"},
    {"name": "Default", "value": "v"},
]
envVarTableConfig = [
    {"name": "Environment Variable", "value": "k"},
    {"name": "Default", "value": "v"},
]


def mkRow(key, value, tblConfig):
    def f(item):
        if "value" in item:
            if item["value"] == "k":
                return key
            elif item["value"] == "v":
                return value
        else:
            return

    return list(map(f, tblConfig))


def gen_section(sectionConfig, flattenedData, sectionKeys, svc, logger):

    output = sectionConfig["name"] + "\n\n"

    # This next section handles the keys and makes sure that this section only prints
    # its immediate children that are not going to be printed by a different section

    # Gets all keys relating to that section
    sc = sectionConfig["key"]
    r = re.compile(sc + ".*")
    k = flattenedData.keys()
    allValues = filter(r.match, k)

    others = list(sectionKeys)
    others.remove(sc)

    # If this is a child path, make sure to remove the parents from the others list, we don't want the parents deleting their children
    if "." in sc:

        def tryremove(x):
            try:
                others.remove(x)
            except Exception:
                return
            return

        [tryremove(x) for x in sc.split(".")]

    pattern = "|".join([re.escape(key) for key in others])
    subKeyRegex = re.compile(pattern)
    subKeys = filter(subKeyRegex.match, k)

    allValues = list(allValues)
    subKeys = list(subKeys)

    # with counters the order is preserved more than with sets. I'm not sure if it's a garuntee though
    sectionValues = collections.Counter(allValues) - collections.Counter(subKeys)

    writer = MarkdownTableWriter()

    def sectionFmt(x):
        if x["name"]:
            return x["name"]
        else:
            return

    tblConfig = sectionConfig["table"]
    writer.headers = list(map(sectionFmt, tblConfig))
    table = []

    sv = list(sectionValues)
    for item in sv:
        key = item
        value = flattenedData[key]

        # these values are currently lists or embedded JSON and we don't want to display they yet
        rmValues = ["jwt.users", "jwt.secrets", "data.deploy.secrets"]
        if any(x in key for x in rmValues):
            value = ""
        # If the envvars key is a list
        if "envvars" in key and type(value) == list:
            # If it's a subkey (aka service.envvars or sidecar.envvars), skip it b/c it would repeat
            if len(sv) > 1:
                continue
            err = "WARNING: Depracated envvars format. You'll need to add this documentation yourself"
            logger.warning(err)
            value = err

        row = mkRow(key, value, tblConfig)
        table.append(row)

    if table == []:
        return ""
    writer.value_matrix = table
    output += writer.dumps()
    output += "\n"

    return output


def gen_docs(svc, logger):
    try:
        with open(os.path.join("./", svc, "values.yaml"), "r") as stream:
            try:
                config = yaml.safe_load(stream)
                logger.info("generating")

                sections = [
                    {
                        "key": "global",
                        "name": "### Global Configuration",
                        "table": optionTableConfig,
                    },
                    {
                        "key": svc,
                        "name": "### Service Configuration",
                        "table": optionTableConfig,
                    },
                    {
                        "key": svc + ".envvars",
                        "name": "#### Environment Configuration",
                        "table": envVarTableConfig,
                    },
                    {
                        "key": "dockerCredentials",
                        "name": "#### Docker Credentials Configuration",
                        "table": envVarTableConfig,
                    },
                     {
                        "key": "data",
                        "name": "#### Data Secret Configuration",
                        "table": envVarTableConfig,
                    },                   
                    {
                        "key": "mongo",
                        "name": "### Mongo Secret Configuration",
                        "table": optionTableConfig,
                    },
                   {
                        "key": "internaldata",
                        "name": "### Internal Data Secret Configuration",
                        "table": optionTableConfig,
                    },
                   {
                        "key": "internalmongo",
                        "name": "### Internal Mongo Secret Configuration",
                        "table": optionTableConfig,
                    },
                   {
                        "key": "slo",
                        "name": "### SLO Secret Configuration",
                        "table": optionTableConfig,
                    },
                   {
                        "key": "postgres",
                        "name": "### Postgres Secret Configuration",
                        "table": optionTableConfig,
                    },
                   {
                        "key": "internalredis",
                        "name": "### Internal Redis Secret Configuration",
                        "table": optionTableConfig,
                    },
                   {
                        "key": "internaljwt",
                        "name": "### Internal JWT Secret Configuration",
                        "table": optionTableConfig,
                    },
                   {
                        "key": "redis",
                        "name": "### Internal Redis Secret Configuration",
                        "table": optionTableConfig,
                    },
                   {
                        "key": "jwt",
                        "name": "### Internal JWT Secret Configuration",
                        "table": optionTableConfig,
                    },
                    {
                        "key": svc + ".certificates",
                        "name": "### Secret Configuration",
                        "table": optionTableConfig,
                    },
                    {
                        "key": "edge",
                        "name": "### Edge Secret Configuration",
                        "table": optionTableConfig,
                    },
                    {
                        "key": "edge.certificates",
                        "name": "### Edge Secret Certificate Configuration",
                        "table": optionTableConfig,
                    },
                    {
                        "key": "controlApi",
                        "name": "### Control API Secret Configuration",
                        "table": optionTableConfig,
                    },
                    {
                        "key": "control",
                        "name": "### Control Secret Configuration",
                        "table": optionTableConfig,
                    },
                    {
                        "key": "dashboard",
                        "name": "### Dashboard Secret Configuration",
                        "table": optionTableConfig,
                    },
                    {
                        "key": "sidecar.envvars",
                        "name": "#### Environment Variables",
                        "table": envVarTableConfig,
                    },
                    {
                        "key": "global.sidecar.envvars",
                        "name": "#### Global Sidecar Environment Variables",
                        "table": envVarTableConfig,
                    },
                ]

                flat = flatten_dict.flatten(
                    config, reducer=dot_reducer, enumerate_types=(list,)
                )

                sectionKeys = list(map(lambda x: x["key"], sections))

                final = ""
                for section in sections:
                    final += gen_section(section, flat, sectionKeys, svc, logger=logger)
                return final

            except yaml.YAMLError as exc:
                print(exc)
                return
    except IOError as err:
        logger.error(f'Failed opening values file. Does the service "{svc}" exist?')
        raise err


# from https://stackoverflow.com/a/800201
def get_immediate_subdirectories(a_dir):
    return [
        name for name in os.listdir(a_dir) if os.path.isdir(os.path.join(a_dir, name))
    ]


defaultServices = set(get_immediate_subdirectories(".")).difference(
    set(["ci", "examples", ".git", "docs"])
)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Autogenerate documentation for Grey Matter services."
    )
    parser.add_argument(
        "services",
        metavar="SERVICES",
        nargs="*",
        default=list(defaultServices),
        help="a list of services to generate docs for",
    )
    parser.add_argument(
        "--embed",
        type=bool,
        default=True,
        help="Whether to embed the docs in the service folders or store them in a separate output directory. (defaults to true)",
    )
    parser.add_argument(
        "--out-dir",
        dest="output_directory",
        default="./docs/",
        help="where to output documentation to, when embedding is off (default ./docs/))",
    )

    args = parser.parse_args()

    def formattedDateTime():
        dt = datetime.datetime.now()
        return dt.strftime("%Y-%m-%d %H:%M:%S")

    logging.info(
        f"Starting documentation generation for services: {','.join(args.services)}"
    )

    for s in args.services:
        logger = logging.getLogger(s)
        logger.info("starting")
        try:
            output = f"# {s} Configuration Options\n\nAutogenerated by `{parser.prog}` at {formattedDateTime()}\n\n"
            output += gen_docs(s, logger=logger)
        except Exception:
            logger.error("Failed generating service. Skipping ...")
            continue
        if not args.embed:
            d = os.path.join(args.output_directory, s)
        else:
            d = s
        filename = os.path.join(d, "configuration.md")
        logger.info(f"writing to {filename}")
        os.makedirs(d, exist_ok=True)
        try:
            with open(filename, "w") as file:
                file.write(output)
        except IOError as err:
            logger.exception(f"Error writing file {filename}")
