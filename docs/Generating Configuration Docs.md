# Generating Configuration Docs

We've provided a handy script [gen-docs.py](../gen-docs.py) for generating configuration documentation for each top-level chart. The script will parse a chart's `values.yaml` file and produce a corresponding Markdown file containing tables of Kubernetes configuration.

## Preparing Python

**If you already have Python 3.x you can skip this step.**

It's recommended that you use [miniconda](https://docs.conda.io/en/latest/miniconda.html) to manage your Python versions. It allows you to easily create and manage separate Python environments and their respective packages.

## Generating Docs

- Install gen-docs.py dependencies

  ```sh
  conda install pyyaml
  pip install flatten-dict
  pip install pytablewriter
  ```

  **Note: it's best to install packages via `miniconda` but not all were available hence the two packages installed via `pip`. If you're not using `miniconda` install all packages using pip.**

- Run `./gen-docs.py` to generate config docs
