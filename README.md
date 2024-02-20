### PUT
```
curl -X PUT --user minioadmin:minioadmin --aws-sigv4 "aws:amz:us-east-1:s3" --upload-file data.json https://play.min.io/mktest/data.json
```

### GET
```
curl -X GET --user minioadmin:minioadmin --aws-sigv4 "aws:amz:us-east-1:s3" -o data.json https://play.min.io/mktest/data.json
```
