#!/bin/bash

curl -X POST "http://$1:8765/alias" -H  "accept: */*" -H  "Content-Type: application/json" -d "{\"newUserId\":\"23422\",\"originalUserId\":\"22111\",\"timestampUTC\":4341412312}"
curl -X POST "http://$1:8765/alias" -H  "accept: */*" -H  "Content-Type: application/json" -d "{\"newUserId\":\"1\",\"originalUserId\":\"22111\",\"timestampUTC\":4341412312}"

curl -X POST "http://$1:8765/profile" -H  "accept: */*" -H  "Content-Type: application/json" -d "{\"attributes\":{\"n\":\"h\"},\"timestampUTC\":34234234234,\"userId\":\"asdc3arc3\"}"
curl -X POST "http://$1:8765/profile" -H  "accept: */*" -H  "Content-Type: application/json" -d "{  \"attributes\": {\"Hello\": 2},  \"timestampUTC\": 123,  \"userId\": \"41fsd\"}"

curl -X POST "http://$1:8765/track" -H  "accept: */*" -H  "Content-Type: application/json" -d "{  \"events\": [    {      \"eventName\": \"click\",      \"metadata\": {\"cookie\":123},      \"timestampUTC\": 21313123    }  ],  \"userId\": \"fdf32\"}"
curl -X POST "http://$1:8765/track" -H  "accept: */*" -H  "Content-Type: application/json" -d "{  \"events\": [    {      \"eventName\": \"hover\",      \"metadata\": {\"cookie\":123},      \"timestampUTC\": 1231231111    }  ],  \"userId\": \"asdsd\"}"