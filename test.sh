#!/usr/bin/env bash

filter_charts() {
    while read chart; do
        [[ ! -d "$chart" ]] && continue
        local file="$chart/Chart.yaml"
        if [[ -f "$file" ]]; then
            echo $chart
        else
           echo "WARNING: $file is missing, assuming that '$chart' is not a Helm chart. Skipping." 1>&2
        fi
    done
}

lookup_changed_charts() {

	charts_dir="."
	commit="2.2.0"

	changed_files=$(git diff --find-renames --name-only "$commit" -- "$charts_dir")

	if [[ "$charts_dir" == '.' ]]; then
		fields='1'
	else
		fields='1,2'
	fi

	cut -d '/' -f "$fields" <<< "$changed_files" | uniq | filter_charts
}

package_chart() {
    local chart="$1"

    echo "Packaging chart '$chart'..."
    helm package "$chart" --destination .cr-release-packages --dependency-update
}

latest_tag="2.2.0"
changed_charts=()


charts=$(lookup_changed_charts)

changed_charts=($(echo $charts | tr " " "\n"))


    if [[ -n "${changed_charts[*]}" ]]; then

        rm -rf .cr-release-packages
        mkdir -p .cr-release-packages

        rm -rf .cr-index
        mkdir -p .cr-index

        for chart in "${changed_charts[@]}"; do
            if [[ -d "$chart" ]]; then
                package_chart "$chart"
            else
                echo "Chart '$chart' no longer exists in repo. Skipping it..."
            fi
        done
    else
        echo "Nothing to do. No chart changes detected."
    fi
