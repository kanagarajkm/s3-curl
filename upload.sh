#!/bin/bash

function hmac_sha256 {
  key="$1"
  data="$2"
  echo -n "$data" | openssl dgst -sha256 -mac HMAC -macopt "$key" | sed 's/^.* //'
}

accessKey="minioadmin"
s3Secret="minioadmin"

file="test.json"

bucket="mktest2"
host="play.min.io"
resource="/$bucket/$file"
contentType="text/plain"

dateValue="`date +'%Y%m%d'`"
X_amz_date="`date --utc +'%Y%m%dT%H%M%SZ'`"
X_amz_algorithm="AWS4-HMAC-SHA256"
awsRegion="us-east-1"
awsService="s3"
X_amz_credential="$accessKey%2F$dateValue%2F$awsRegion%2F$awsService%2Faws4_request"
X_amz_credential_auth="$accessKey/$dateValue/$awsRegion/$awsService/aws4_request"


signedHeaders="content-type;host;x-amz-content-sha256;x-amz-date"

contentHash="UNSIGNED-PAYLOAD"
contentType="application/json"

canonicalRequest="PUT\n$resource\n"\
"\n"\
"content-type:$contentType\n"\
"host:$host\n"\
"x-amz-content-sha256:$contentHash""\n"\
"x-amz-date:$X_amz_date""\n\n"\
"$signedHeaders\n"\
"$contentHash"

canonicalHash=`/bin/echo -en "$canonicalRequest" | openssl sha256 -binary | xxd -p -c256`

stringToSign="$X_amz_algorithm\n$X_amz_date\n$dateValue/$awsRegion/s3/aws4_request\n$canonicalHash"


# Four-step signing key calculation
dateKey=$(hmac_sha256 key:"AWS4$s3Secret" $dateValue)
dateRegionKey=$(hmac_sha256 hexkey:$dateKey $awsRegion)
dateRegionServiceKey=$(hmac_sha256 hexkey:$dateRegionKey $awsService)
signingKey=$(hmac_sha256 hexkey:$dateRegionServiceKey "aws4_request")


signature=`/bin/echo -en $stringToSign | openssl dgst -sha256 -mac HMAC -macopt hexkey:$signingKey -binary | xxd -p -c256`

authorization="$X_amz_algorithm Credential=$X_amz_credential_auth,SignedHeaders=$signedHeaders,Signature=$signature"

curl -X "PUT" \
    -H "Content-Type: $contentType" \
    -H "Host: $host" \
    -H "X-Amz-Content-SHA256: $contentHash" \
    -H "X-Amz-Date: ${X_amz_date}" \
    -H "Authorization: $authorization" \
    --upload-file "$file" \
    -w "%{http_code}\n" \
    "https://$host/$bucket/$file"
