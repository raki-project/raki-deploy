#!/usr/bin/env bash
key_content1=$(cat $KEY1_PATH)
key_content2=$(cat $KEY2_PATH)
key_content3=$(cat $KEY3_PATH)
docker build \
         --progress=plain \
         --rm -t raki-verbalizer-webapp \
         --no-cache \
         --build-arg \
         KEY_VERBALIZER="${key_content1}" \
         --build-arg \
         KEY_PIPELINE="${key_content2}" \
         --build-arg \
         KEY_WEBAPP="${key_content3}" \
         -f Dockerfile . 

#         --target cloner .
#         --no-cache \
