#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TODAY=$(date '+%Y-%m-%d')

###############################################################################
# Handle script parameters
###############################################################################

function usage()
{
    cat <<-END
usage: $(basename -- "$BASH_SOURCE") -v VERSION -b BUILD_DIR [-h]

required arguments:
  -v    The version number of the published release.
  -b    The directory with the compiled HTML and PDF.

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
# Main
###############################################################################

cd ${SCRIPT_DIR}/../..

echo
echo "Upload to GitHub Pages"
echo

git fetch origin
git checkout gh-pages

mv ${BUILD_DIR} ./${VERSION}
echo "| ${VERSION} | ${TODAY} | [quality-manual.html](./${VERSION}/html/quality-manual.html) | [quality-manual.pdf](./${VERSION}/pdf/quality-manual.pdf) |" \
  >> index.md
git add .
git commit -m "Add release artifacts for version ${VERSION}"
git push
