#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

###############################################################################
# Handle script parameters
###############################################################################

function usage()
{
    cat <<-END
usage: $(basename -- "$BASH_SOURCE") -v VERSION -b BUILD_DIR [-h]

required arguments:
  -v    The version number of the published release.
  -b    The directory where the compiled HTML and PDF should be moved to.

optional arguments:
  -h    Show this help message and exit.

END
}

while getopts "h v: b:" o; do
  case "${o}" in
    v)
      VERSION=${OPTARG}
      ;;
    b)
      BUILD_DIR=${OPTARG}
      ;;      
    h | *)
      usage
      exit 0
      ;;
  esac
done
shift $((OPTIND-1))

if [[ -z "${VERSION}" ]] ; then
  echo -e "ERROR: Missing required parameter '-v'.\n" >&2
  usage
  exit 1
fi

if [[ -z "${BUILD_DIR}" ]] ; then
  echo -e "ERROR: Missing required parameter '-b'.\n" >&2
  usage
  exit 1
fi

###############################################################################
# Functions
###############################################################################

function has_untracked_files() {
  local UNTRACKED_FILES=$(git ls-files --others --exclude-standard)
  [[ ! -z "${UNTRACKED_FILES}" ]]
}

function remove_untracked_files() {
  rm $(git ls-files --others --exclude-standard) && rmdir ./src/img 2> /dev/null
}

###############################################################################
# Main
###############################################################################

if has_untracked_files ; then
  echo "ERROR: when this script gets called, there should be no untracked files" >&2
  exit 1
fi

echo
echo "Compile HTML"
echo
if [[ -d ./build ]]; then
  rm -r ./build
fi
mkdir ./build
find src -name "img" -exec cp -r {} ./build \;
docker run -v $(pwd):/documents/ asciidoctor/docker-asciidoctor asciidoctor ./src/index.adoc --out-file ./build/quality-manual.html
if [[ ${BUILD_DIR} != "./build" ]] ; then
  mv ./build ${BUILD_DIR}/html
else
  TEMP_DIR=$(mktemp -d)
  mv ./build/* ${TEMP_DIR}
  mv ${TEMP_DIR} ./build/html
fi

echo
echo "Compile PDF"
echo
find src -name "img" -exec cp -r {} ./src \;
mkdir ${BUILD_DIR}/pdf
docker run -v $(pwd):/documents/ -v ${BUILD_DIR}/pdf:/target asciidoctor/docker-asciidoctor asciidoctor-pdf ./src/index.adoc --out-file /target/quality-manual.pdf
remove_untracked_files
