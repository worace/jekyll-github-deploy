#!/bin/bash
set -x
set -e
set -o pipefail

URL=$1
BRANCH=$2
BRANCH_FROM=$3
SRC=$(pwd)
TEMP=$(mktemp -d -t jgd-XXX)
trap "rm -rf ${TEMP}" EXIT
CLONE=${TEMP}/clone
COPY=${TEMP}/copy

echo -e "Cloning Github repository:"
git clone -b "${BRANCH_FROM}" "${URL}" "${CLONE}"
cp -R ${CLONE} ${COPY}

cd "${CLONE}"

echo -e "\nBuilding Jekyll site:"
rm -rf _site

if [ -r _config-deploy.yml ]; then
  jekyll build --config _config.yml,_config-deploy.yml
else
  jekyll build
fi

if [ ! -e _site ]; then
  echo -e "\nJekyll didn't generate anything in _site!"
  exit -1
fi

cp -R _site ${TEMP}

cd ${TEMP}
rm -rf ${CLONE}
mv ${COPY} ${CLONE}
cd ${CLONE}

echo -e "\nPreparing ${BRANCH} branch:"
if [ -z "$(git branch -a | grep origin/${BRANCH})" ]; then
  git checkout --orphan "${BRANCH}"
else
  git checkout "${BRANCH}"
fi

echo -e "\nDeploying into ${BRANCH} branch:"
rm -rf *
cp -R ${TEMP}/_site/* .
rm -f README.md
git add .
git commit -am "new version $(date)" --allow-empty
git push origin ${BRANCH} 2>&1 | sed 's|'$URL'|[skipped]|g'

echo -e "\nCleaning up:"
rm -rf "${CLONE}"
rm -rf "${SITE}"
