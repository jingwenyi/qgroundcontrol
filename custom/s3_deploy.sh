#!/bin/bash

# exit 1 on error
set -e

# deploy to s3
$(aws ecr get-login --region eu-central-1 --no-include-email)
S3_BUCKET_NAME=2c70f0fa-1d5f-fbbd-e789-ead53fd00456
export AWS_CREDENTIAL_FILE=/var/lib/jenkins/.aws/credentials

apk_path=/tmp/datapilot_build/release/package
prefix="DataPilot-"
suffix=".apk"
FIRST_BUILD=3564
build=$(($(git rev-list master --first-parent --count) - $FIRST_BUILD))
filename=$(ls $apk_path | grep $prefix | grep $suffix | grep $build )

if [[ $(ls $apk_path | grep $filename | wc -l) -eq 1 ]]; then
    echo "s3_deploy: apk found: $filename"
else 
    echo "s3_deploy: error, no apk found in $apk_path"
    exit 1
fi

version=${filename#$prefix}
version=${version%$suffix}

echo -n "$version" > ${apk_path}/version
echo -n "$(sha256sum ${apk_path}/${prefix}${version}${suffix} | head -c 64)" > ${apk_path}/hash

if [[ "$1" == "master" ]]; then
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m application/octet-stream --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/$filename s3://${S3_BUCKET_NAME}/datapilot/latest/datapilot.apk;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m application/octet-stream --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/$filename s3://${S3_BUCKET_NAME}/datapilot/$version/datapilot.apk;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/version s3://${S3_BUCKET_NAME}/datapilot/latest/version;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/version s3://${S3_BUCKET_NAME}/datapilot/$version/version;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/hash s3://${S3_BUCKET_NAME}/datapilot/latest/hash;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/hash s3://${S3_BUCKET_NAME}/datapilot/$version/hash;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put ./custom/CHANGELOG.md s3://${S3_BUCKET_NAME}/datapilot/latest/changelog;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put ./custom/CHANGELOG.md s3://${S3_BUCKET_NAME}/datapilot/$version/changelog;
else
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m application/octet-stream --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/$filename s3://${S3_BUCKET_NAME}/datapilot/$1/latest/datapilot.apk;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m application/octet-stream --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/$filename s3://${S3_BUCKET_NAME}/datapilot/$1/$version/datapilot.apk;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/version s3://${S3_BUCKET_NAME}/datapilot/$1/latest/version;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/version s3://${S3_BUCKET_NAME}/datapilot/$1/$version/version;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/hash s3://${S3_BUCKET_NAME}/datapilot/$1/latest/hash;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put $apk_path/hash s3://${S3_BUCKET_NAME}/datapilot/$1/$version/hash;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put ./custom/CHANGELOG.md s3://${S3_BUCKET_NAME}/datapilot/$1/latest/changelog;
    s3cmd --add-header=x-amz-meta-firmware-version:${version} -m text/plain --acl-public --add-header='Cache-Control: public, max-age=0' put ./custom/CHANGELOG.md s3://${S3_BUCKET_NAME}/datapilot/$1/$version/changelog;
fi
