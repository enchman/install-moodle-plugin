#!/bin/bash

moodle_dir=$1

if [ -z "$moodle_dir" ]; then
    echo "Undefined moodle directory"
    exit 1
fi

if [ ! -d "$moodle_dir" ]; then
    echo "Moodle directory not found"
    exit 1
fi

if [ ! -f "$moodle_dir/version.php" ]; then
    echo "Moodle not found in the specified directory"
    exit 1
fi

if [ ! -f "$moodle_dir/config.php" ]; then
    echo "Moodle config.php not found in $moodle_dir"
    exit 1
fi

apt install -y curl php-cli
