#!/bin/bash
swift run swift-openapi-generator generate \
    --mode types --mode client \
    --output-directory ../Sources/TonConnectAPI\
    ./openapi.yml