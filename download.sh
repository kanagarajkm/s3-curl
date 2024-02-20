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


signedHeaders="host;x-amz-algorithm;x-amz-content-sha256;x-amz-credential;x-amz-date"
# this hash is created via echo -n ''|sha256sum
contentHash="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

# contentHash=`cat $file | sha256sum`

canonicalRequest="GET\n$resource\n"\
"\n"\
"host:$host\n"\
"x-amz-algorithm:$X_amz_algorithm""\n"\
"x-amz-content-sha256:$contentHash""\n"\
"x-amz-credential:$X_amz_credential""\n"\
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

echo $authorization

curl -s -X "GET" \
    -H "Host: $host" \
    -H "X-Amz-Algorithm: $X_amz_algorithm" \
    -H "X-Amz-Content-SHA256: ${contentHash}" \
    -H "X-Amz-Credential: $X_amz_credential" \
    -H "X-Amz-Date: ${X_amz_date}" \
    -H "Authorization: $authorization" \
    -o test.json \
    "https://$host/$bucket/$file"
