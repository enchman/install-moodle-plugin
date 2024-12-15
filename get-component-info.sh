#!/bin/bash

# Argument: URL of the repository
url=$1
repo_name=$(basename $url .git)
component_name=${repo_name#"moodle-"}
ref=${2:-""}
moodle_dir=${3:-"$GITHUB_ACTION_PATH/moodle"}
clone_dir=${4:-"$GITHUB_ACTION_PATH/plugin/$component_name"}

if [ -z $url ]; then
    echo "Please provide the URL of the repository"
    exit 1
fi
if [ ! -f "$moodle_dir/lib/classes/component.php" ]; then
    echo "The Moodle directory does not have the lib/classes/component.php file"
    exit 1
fi
if [ ! -f "$moodle_dir/config.php" ]; then
    echo "The Moodle directory does not have the config.php file"
    exit 1
fi

download_file () {
    repo=$1
    branch=$2
    file=$3
    save_as=$4
    if [ -z "$GITHUB_TOKEN" ]; then
        curl -o $save_as \
            -s "https://raw.githubusercontent.com/$repo/$branch/$file"
    else
        curl -o $save_as \
            -H "Authorization: Bearer $GITHUB_TOKEN" \
            -s "https://raw.githubusercontent.com/$repo/$branch/$file"
    fi
}

version_file="$clone_dir/version.php"
download_file $repo_name $ref version.php $version_file

if [ ! -f "$version_file" ]; then
    echo "The component does not have a version.php file"
    exit 1
fi

# Get the compoent name from the version.php file
component_name=$(grep '$plugin->component' $version_file | cut -d"'" -f2)

if [ -z "$component_name" ]; then
    echo "The component does not have a component name"
    exit 1
fi

moodle_cmd="define('MOODLE_INTERNAL', true);
use \core\component;
if (!class_exists(component::class)) {
    class component extends \core_component {}
}
require_once '$moodle_dir/config.php';
require_once '$moodle_dir/lib/classes/component.php';"

moodle_get_dir="${moodle_cmd} [\$type, \$plugin] = component::normalize_component('$component_name');
echo component::get_plugin_directory(\$plugin_type, \$plugin_name);"

plugin_dir=$(php -r "$moodle_get_dir")

# Save the plugin directory to GitHub Actions environment
echo "PLUGIN_DIR=$plugin_dir" >> $GITHUB_ENV