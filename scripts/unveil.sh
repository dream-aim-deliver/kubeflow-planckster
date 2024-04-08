#!/bin/bash
set -e

# FIXME: drop this script and use a better solution

# Check if the correct number of arguments is provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <encrypt|decrypt> <environment> <file1> [<file2> ...]"
    echo "(pass --all flag to detect all files in the repository)"
    exit 1
fi

# Get the operation (encrypt or decrypt)
operation=$1

# Check if operation is valid
if [ "$operation" != "encrypt" ] && [ "$operation" != "decrypt" ]; then
    echo "Invalid operation: $operation"
    exit 1
fi

environment=$2
if [ "$environment" == "brain12" ]; then
    env="brain12"
else
    echo "Invalid environment: $environment"
    exit 1
fi

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Shift the arguments to get the list of files
shift 2

if [ "$1" == "--all" ]; then
    files=$(find "$SCRIPT_DIR/../env" -type f)
    # if [ "$operation" == "encrypt" ]; then
    #     files=$(find "$SCRIPT_DIR/.." -type f) # \( -name "*.yaml" -o -name "*.yml" -o -name "*.env" \) -a -not -name "*kustomization.yaml" -a -not -name "*profile-instance.yaml" -a -not -name "*namespace.yaml" -a -not -path "*/.github/*")
    # elif [ "$operation" == "decrypt" ]; then
    #     files=$(find "$SCRIPT_DIR/.." -type f) # -name "*.yaml.enc" -o -name "*.yml.enc" -o -name "*.env.enc")
    # fi
else
    # Get the list of files from the arguments
    files=$@
fi

if [ ! -f "${SCRIPT_DIR}/../cert/$env/public.crt" ] || [ ! -f "${SCRIPT_DIR}/../cert/$env/private.key" ]; then
    echo "Public certificate or private key not found in the repository."
    exit 1
fi


echo "Decrypting the symmetric key"
# encrypted before with
# openssl rand -base64 32 > symmetric.key
# openssl rsautl -encrypt -inkey public.crt -certin -in symmetric.key -out symmetric.key.enc
openssl pkeyutl -decrypt -inkey $SCRIPT_DIR/../cert/$env/private.key -in $SCRIPT_DIR/../cert/$env/symmetric.key.enc -out $SCRIPT_DIR/../cert/$env/symmetric-decrypted.key
echo "Done."

# Perform the operation on each file
for file in $files; do
    if [[ "$file" != */$env/* ]]; then
        continue
    fi

    # filter out files that do not end with .yaml
    if [ "$operation" == "encrypt" ]; then
        if [[ "$file" != *.yaml ]] && \
        [[ "$file" != *.yml ]] && \
        [[ "$file" != *.env ]] || \
        [[ "$file" == *kustomization.yaml ]] || \
        [[ "$file" == *namespace.yaml ]] || \
        [[ "$file" == *profile-instance.yaml ]] || \
        [[ "$file" == */github/* ]]
        then
            continue
        fi
    elif [ "$operation" == "decrypt" ]; then
        if [[ "$file" != *.yaml.enc ]] && \
        [[ "$file" != *.yml.enc ]] && \
        [[ "$file" != *.env.enc ]]
        then
            continue
        fi
    fi

    echo "Working on '$file'"

    if [ "$operation" == "encrypt" ]; then
        openssl enc --aes-256-cbc -md sha512 -pbkdf2 -iter 1000000 -salt -in $file -out "${file}.enc" -pass file:$SCRIPT_DIR/../cert/$env/symmetric-decrypted.key
        echo "Encrypted $file to $file.enc"
    elif [ "$operation" == "decrypt" ]; then
        # openssl rsautl -decrypt -inkey private.key -in "$file" -out "${file%.enc}.dec"
        output="${file%.enc}"
        if [ -f "${output}" ]; then
            new_output="${output}.dec"
            echo "File ${output} already exists. Will decrypt to ${new_output} instead."
            output="${new_output}"
        fi
        openssl enc -d --aes-256-cbc -md sha512 -pbkdf2 -iter 1000000 -in "$file" -out "${output}" -pass file:$SCRIPT_DIR/../cert/$env/symmetric-decrypted.key
        # openssl enc -aes-256-cbc -d -in "$file" -out "${file%.enc}" -pass pass:"$password"
        echo "Decrypted $file to ${output}"
    else
        echo "Invalid operation: $operation"
        exit 1
    fi
done

echo "Removing symmetric key"
rm "${SCRIPT_DIR}/../cert/$env/symmetric-decrypted.key"
echo "Done."