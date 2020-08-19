#!/bin/bash

################# Installing Prerequisites #################

# Installing Istio command line tool.
BEFORE=$(ls)
curl -L https://istio.io/downloadIstio | sh -
AFTER=$(ls)
cd $(comm <(echo $BEFORE | tr " " "\n") <(echo $AFTER | tr " " "\n") -3)
export PATH=$PWD/bin:$PATH
cd ..

################# Installing Istio Service Mesh to cluster #################

istioctl manifest apply --set profile=demo