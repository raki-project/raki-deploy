cd build
# export path to the private key
export KEY1_PATH=./raki-verbalizer/deployKey
export KEY2_PATH=./raki-verbalizer-pipeline/deployKey
export KEY3_PATH=./raki-verbalizer-webapp/deployKey
./dockerBuild.sh
