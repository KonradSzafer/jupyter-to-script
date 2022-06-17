#!/usr/bin/env bash

set -e

FILENAME="${1}"
SPACES_COUNT=${2:-4}

# convert to raw python script
jupyter nbconvert --to script "$FILENAME"

# read file
FILENAME="${FILENAME%.*}.py"
readarray -t file_lines < "$FILENAME"
truncate -s 0 "$FILENAME"

# indent size
indent=""
for ((i = 0; i < SPACES_COUNT; i++)); do
    indent="$indent "
done

# add indents and boilerplate
script=()
add_indent=False
skip_next=False
cell_regex="# In[\[0-9]+\]:"

for line in "${file_lines[@]}"; do
    # remove cell beginning
    if [[ "$line" =~ $cell_regex ]]; then
        skip_next=True
        continue
    fi
    # remove new line after cell beginning
    if [ "$skip_next" == True ]; then
        skip_next=False
        continue
    fi
    # add indents
    if [ "$add_indent" == True ]; then
        # don't add indents if empty line
        if [[ "$line" == *[![:space:]]* ]]; then
            line="$indent$line"
        fi
        script+=("$line")
    else
        script+=("$line")
    fi
    # search for the beginning of the script
    if [ "$line" == "# !script" ]; then
        script+=("if __name__ == '__main__':")
        add_indent=True
    fi
done

# rewrite file
for line in "${script[@]}"; do
    echo "$line" >> "$FILENAME"
done

echo "Notebook successfully converted."

set +e
