#!/bin/sh

set -e

BASEDIR="${BASEDIR:-$(dirname -- "${0}")/..}"
BASEDIR="$(readlink -f -- ${BASEDIR})"

. ${BASEDIR}/functions

if [ -e "${BUILDDIR}/dist" ]
then
  rm -rf "${BUILDDIR}/dist"
fi
mkdir "${BUILDDIR}/dist"
cd "${BUILDDIR}/dist"

if [ "${MM_TYPE}" = "opensips" ]
then
  git clone -b "${MM_BRANCH}" git://github.com/OpenSIPS/opensips.git
  perl -pi -e 's|-O[3-9]|-O0 -g3|' ${BUILDDIR}/dist/opensips/Makefile.defs
  if [ "${MM_BRANCH}" != "1.11" -a "${MM_BRANCH}" != "2.1" ]
  then
    patch -p1 -s -d opensips < ${BUILDDIR}/install_depends/opensips/rtpproxy_ip6.patch
  fi
  #if [ "${MM_BRANCH}" = "1.11" ]
  #then
  #  patch -p1 -s -d opensips < ${BUILDDIR}/install_depends/tm_none_on_cancel.patch 
  #fi
fi
if [ "${MM_TYPE}" = "b2bua" ]
then
  pip install git+https://github.com/sippy/b2bua@${MM_BRANCH}
else
  pip install git+https://github.com/sippy/b2bua
fi
git clone -b "${RTPP_BRANCH}" git://github.com/sippy/rtpproxy.git
if [ "${MM_TYPE}" = "kamailio" ]
then
  git clone -b "${MM_BRANCH}" git://github.com/kamailio/kamailio.git kamailio
  perl -pi -e 's|-O[3-9]|-O0 -g3| ; s|^run_target = .[(]run_prefix[)]/.[(]run_dir[)]|run_target = /tmp/kamailio|' \
   ${BUILDDIR}/dist/kamailio/Makefile.defs
  if [ "${MM_BRANCH}" = "4.1" -o "${MM_BRANCH}" = "4.2" ]
  then
    patch -p1 -s -d kamailio < ${BUILDDIR}/install_depends/kamailio/rtpproxy_ip6.patch
  fi
fi

##bash
if [ "${MM_TYPE}" = "opensips" ]
then
  ${MAKE_CMD} -C "${BUILDDIR}/dist/opensips" CC_NAME=gcc CC="${CC}" all modules
fi
if [ "${MM_TYPE}" = "kamailio" ]
then
  ${MAKE_CMD} -C "${BUILDDIR}/dist/kamailio" CC_NAME=gcc CC="${CC}" LD="${CC}" \
   include_modules="sl tm rr maxfwd rtpproxy textops" skip_modules="erlang" all modules
fi
cd rtpproxy
./configure
${MAKE_CMD} all
