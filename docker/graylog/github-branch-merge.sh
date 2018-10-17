#!/bin/bash -xe

# Personal Access Token generated by GitHub
ACCESS_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXX

ACCOUNT=
#ACCOUNT=

REPOSITORY1=nation
#REPOSITORY
#REPOSITORY1=Hoge
#REPOSITORY2=Hoge


BASE=develop
HEAD=feature06

CURL=/bin/curl

STATUS_CODE1=`$CURL -X POST -H 'Content-Type:application/json' -H "Authorization: Bearer ${ACCESS_TOKEN}" -d "{\"base\":\"${BASE}\",\"head\":\"${HEAD}\",\"commit_message\":\"Merged by Jenkins Bot.\"}" https://api.github.com/repos/${ACCOUNT}/${REPOSITORY1}/merges -o /dev/null -w "%{http_code}\n" -s`

case ${STATUS_CODE1} in
  "201" ) echo "${REPOSITORY1} ${HEAD} --> ${BASE} : Merged.";;
  "204" ) echo "${REPOSITORY1} ${HEAD} --> ${BASE} : No update.";;
  "409" ) echo "${REPOSITORY1} ${HEAD} --> ${BASE} : Conflicted.";;
  * ) echo "${REPOSITORY1} ${HEAD} --> ${BASE} : Unexpected status (${STATUS_CODE1})" ;;
esac

#STATUS_CODE2=`$CURL -X POST -H 'Content-Type:application/json' -H "Authorization: Bearer ${ACCESS_TOKEN}" -d "{\"base\":\"${BASE}\",\"head\":\"${HEAD}\",\"commit_message\":\"Merged by Jenkins Bot.\"}" https://api.github.com/repos/${ACCOUNT}/${REPOSITORY2}/merges -o /dev/null -w "%{http_code}\n" -s`
#
#case ${STATUS_CODE2} in
#  "201" ) echo "${REPOSITORY2} ${HEAD} --> ${BASE} : Merged.";;
#  "204" ) echo "${REPOSITORY2} ${HEAD} --> ${BASE} : No update.";;
#  "409" ) echo "${REPOSITORY2} ${HEAD} --> ${BASE} : Conflicted.";;
#  * ) echo "${REPOSITORY2} ${HEAD} --> ${BASE} : Unexpected status (${STATUS_CODE2})" ;;
#esac


if [ ${STATUS_CODE1} -eq 409 ]; then
    exit 1;
fi


if [ ${STATUS_CODE1} -eq 201 ]; then
    exit 0;
else
    exit 1;
fi
