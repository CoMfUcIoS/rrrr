#!/bin/bash

# Script to build alerts module
# flags to accept:
# envarg: build for enterprise edition.
# Default will be OSS build.

# Usage: IMAGE_TAG=latest DOCKER_REPO=myDockerHubID bash build.sh <ee>

function make_submodule() {
    # -- this part was generated by modules_lister.py --
    mkdir alerts
    cp -R ./{app_alerts}.py ./alerts/
    mkdir -p ./alerts/sers/tahayk/asayer/openreplay/ee/api/chalicelib/
    cp -R /Users/tahayk/asayer/openreplay/ee/api/chalicelib/__init__.py ./alerts/sers/tahayk/asayer/openreplay/ee/api/chalicelib/
    mkdir -p ./alerts/sers/tahayk/asayer/openreplay/ee/api/chalicelib/core/
    cp -R /Users/tahayk/asayer/openreplay/ee/api/chalicelib/core/{__init__,alerts_processor,sessions,events,sessions_metas,metadata,projects,users,authorizers,tenants,roles,assist,issues,events_ios,sessions_mobs,errors,dashboard,sourcemaps,sourcemaps_parser,resources,alerts,notifications,slack,collaboration_slack,webhook}.py ./alerts/sers/tahayk/asayer/openreplay/ee/api/chalicelib/core/
    mkdir -p ./alerts/sers/tahayk/asayer/openreplay/ee/api/
    cp -R /Users/tahayk/asayer/openreplay/ee/api/schemas.py ./alerts/sers/tahayk/asayer/openreplay/ee/api/
    mkdir -p ./alerts/sers/tahayk/asayer/openreplay/ee/api/chalicelib/utils/
    cp -R /Users/tahayk/asayer/openreplay/ee/api/chalicelib/utils/{__init__,TimeUTC,helper,pg_client,event_filter_definition,dev,SAML2_helper,email_helper,email_handler,smtp,s3,args_transformer,ch_client,metrics_helper}.py ./alerts/sers/tahayk/asayer/openreplay/ee/api/chalicelib/utils/
    # -- end of generated part

    cp -R ./{Dockerfile.alerts,requirements_alerts.txt,.env.default,entrypoint.sh} ./alerts/
    cp ./chalicelib/utils/html ./alerts/chalicelib/utils/html
}

git_sha1=${IMAGE_TAG:-$(git rev-parse HEAD)}
envarg="default-foss"
check_prereq() {
    which docker || {
        echo "Docker not installed, please install docker."
        exit=1
    }
    [[ exit -eq 1 ]] && exit 1
}

function build_api(){
    tag=""
    # Copy enterprise code
    [[ $1 == "ee" ]] && {
        cp -rf ../ee/api/* ./
        envarg="default-ee"
        tag="ee-"
    }
    make_submodule
    cd alerts
    docker build -f ./Dockerfile.alerts --build-arg envarg=$envarg -t ${DOCKER_REPO:-'local'}/alerts:${git_sha1} .
    cd ..
    rm -rf alerts
    [[ $PUSH_IMAGE -eq 1 ]] && {
        docker push ${DOCKER_REPO:-'local'}/alerts:${git_sha1}
        docker tag ${DOCKER_REPO:-'local'}/alerts:${git_sha1} ${DOCKER_REPO:-'local'}/alerts:${tag}latest
        docker push ${DOCKER_REPO:-'local'}/alerts:${tag}latest
    }
}

check_prereq
build_api $1