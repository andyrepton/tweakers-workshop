#!/bin/bash

# Automatically do each of the steps of the workshop

check_tools() {
  local kubectlFound="Found"
  local dockerFound="Found"
  hash kubectl 2>/dev/null || kubectlFound="NOT FOUND"
  hash docker 2>/dev/null || dockerFound="NOT FOUND"
  if [[ ${dockerFound} != "Found" || ${kubectlFound} != "Found" ]]; then
    echo "Some requirements are not met"
    echo
    echo "Docker is ${dockerFound}"
    echo "Kubectl is ${kubectlFound}"
    echo "These tools can be installed with brew on mac or using your local package manager if you are on Linux."
    exit 1
  fi
}

download_dockerfile() {
  echo "Downloading Dockerfile"
  curl -s -Lo guestbook/Dockerfile https://gist.githubusercontent.com/Seth-Karlo/01a3b35cf7f7a373d0764dbff819735b/raw/346e05797294566922ecfe4b56f8ea74c58c0297/Dockerfile
}

build_image() {
  echo "Building Image"
  cd guestbook
  docker build -t sbpdemo/guestbook .
}

run_image() {
  echo "Running Image"
  docker run -p 80:80 sbpdemo/guestbook
}

run_image_with_vol() {
  echo "Running Image with a volume"
  docker kill $(docker ps | grep sbpdemo/guestbook | awk '{print $1}')
  docker run -p 80:80 --mount source=test,target=/usr/src/app/db/ -d sbpdemo/guestbook
  docker ps
}

run_image_with_env() {
  echo "Running Image with a volume and environment variable"
  docker kill $(docker ps | grep sbpdemo/guestbook | awk '{print $1}')
  docker run -p 80:80 --env NAME="Andy" --mount source=test,target=/usr/src/app/db/ -d sbpdemo/guestbook
  docker ps
}

tag_image() {
  echo "Running Image with a volume"
  cluster_name=$1
  docker tag sbpdemo/guestbook sbpdemo/guestbook:${cluster_name}
}

push_image() {
  echo "Pushing Image"
  cluster_name=$1
  docker login
  docker push sbpdemo/guestbook:${cluster_name}
}

create_deployment() {
  echo "Creating deployment"
  cluster_name=$1
  kubectl run my-guestbook --image sbpdemo/guestbook:${cluster_name}
}

expose_deployment() {
  echo "Creating Load Balancer"
  kubectl expose deployment my-guestbook --type=LoadBalancer --port=80
}

add_env_to_deployment() {
  echo "Redeploying with env variable"
  kubectl delete deployment my-guestbook
  kubectl run my-guestbook --image sbpdemo/guestbook:user1 --env NAME="Andy"
}

connect_to_my_cluster() {
  echo Hello $1
  cluster_name=$1
  curl -s -LO https://s3-eu-west-1.amazonaws.com/sbp-demo-public/${cluster_name}.kubeconfig 
  cat <<EOF
  ####

  Your cluster's kubeconfig is now in the current directory as ${cluster_name}.kubeconfig.
  Please copy this to ~/.kube/config
  *** This script will NOT move the file for you ***
  PLEASE BACK UP YOUR EXISTING CONFIG FIRST!!

  ####
EOF
    read -p "Please confirm you will back up your config by typing yes (and that Andy is not responsible if you don't): "
    echo
    if [ ${REPLY} == "yes" ]; then
      exit 0
    else
      echo "Well, you can't say you weren't warned"
      exit 1
    fi
}

usage() {
  cat <<EOF
Welcome to the containers and Kubernetes workshop! Please re-run this script with your user number and the argument 'connect'. For example, if you are user 22, run:

./workshop.sh connect user22

Any questions at any time please just ask Andy. I hope you enjoy the workshop!
EOF

}

if [ -z $1 ]; then usage ; exit 0; fi

for cmd in "$@"; do
shift
case ${cmd} in
  check)
  check_tools
  ;;
  connect)
  check_tools
  connect_to_my_cluster "$@"
  ;;
  workshop-2-2)
  check_tools
  download_dockerfile
  ;;
  workshop-2-3)
  check_tools
  build_image "$@"
  run_image
  exit 0
  ;;
  workshop-2-4)
  check_tools
  run_image_with_vol
  exit 0
  ;;
  workshop-2-5)
  check_tools
  run_image_with_env
  exit 0
  ;;
  push_image)
  check_tools
  push_image "$@"
  ;;
  *)
  usage
  ;;
esac
done
