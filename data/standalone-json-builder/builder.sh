#!/bin/sh
set -e

# input cluster_name of data (must be unique and match sidecar envar for cluster_name)
read -p "Input the cluster name of the standalone data instance: " DATACLUSTERNAME

PWD=$(pwd)

SRC=$PWD/standalone-data-template-json/
DEST=$PWD/builder-output-$DATACLUSTERNAME

# Clean output directory
if [ -d $DEST ]
then
    # ask if the user is ok destroying the old directory
    echo "There is a directory ($DEST) that has the same cluster name you entered.\n If you continue this will be overwritten."
    read -p "Continue [Y/n]" CONFIRM
    if [ "$CONFIRM" == "Y" ] || [ "$CONFIRM" == "y" ]
    then
        echo "Cleaning old output directory"
        rm -rf $DEST
    else
        echo "Exiting!"
        exit 15
    fi
fi
mkdir $DEST

cd $SRC
DIRECTORIES=*/

# Build configs from templates and place in correct output directories
for dir in $DIRECTORIES
do
    mkdir $DEST/$dir
    echo "Processing $dir files"
    (
        cd $dir
        FILES=*
        for file in $FILES
        do
            echo "replacing strings in $file"
            sed "s/REPLACESTRING/$DATACLUSTERNAME/g" $file > $DEST/$dir/$file
            
        done
    )    
done

# Scripts to populate and remove gm configs
echo "Building populate/remove config scripts"
sed "s/REPLACESTRING/$DATACLUSTERNAME/g" populate.sh > $DEST/populate.sh
sed "s/REPLACESTRING/$DATACLUSTERNAME/g" remove.sh > $DEST/remove.sh


# Make scripts executable 
chmod +x $DEST/catalog/add-entry.sh
chmod +x $DEST/catalog/remove-entry.sh

chmod +x $DEST/populate.sh
chmod +x $DEST/remove.sh
