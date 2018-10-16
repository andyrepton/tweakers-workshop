Function check-tools {
    $tools = 0
    $docker = (get-command docker -ErrorAction SilentlyContinue)
    $kubectl = (get-command kubectl -ErrorAction SilentlyContinue)
    $dockerservice = ((get-service com.docker.service).Status -eq 'Running')
    if (!($docker)) { 
    Write-Error "Docker commands not found"
    }
    if (!($dockerservice)) {
    Write-Error "Cannot find a running docker service (com.docker.service)"
    }
    if (!($kubectl)) {
    Write-Error "Kubectl commands not found"
    }
}
function download_dockerfile() {
  Write-Output "Downloading Dockerfile"
  Invoke-WebRequest "https://gist.githubusercontent.com/Seth-Karlo/01a3b35cf7f7a373d0764dbff819735b/raw/346e05797294566922ecfe4b56f8ea74c58c0297/Dockerfile" -UseBasicParsing -OutFile '.\guestbook\dockerfile'
}
function build_image() {
  write-output "Building Image"
  cd guestbook
  docker build -t sbpdemo/guestbook .
}
function run_image() {
  Write-Output "Running Image"
  docker run -p 80:80 sbpdemo/guestbook
}
function run_image_with_vol() {
  Write-Output "Running Image with a volume"
  $InStuff = (docker ps).Split("`n").Trim("`r")
  foreach ($Index in 0..$InStuff.GetUpperBound(0))
  {
  # the 1st -replace handles the blank PORTS column
  $InStuff[$Index] = $InStuff[$Index] -replace '\s{23,}', ',,' -replace '\s{2,}', ','
  }
  $DockerPSA_Objects = $InStuff |
  ConvertFrom-Csv
  $id = ($DockerPSA_Objects | Where-Object {$_.IMAGE -match 'guestbook'})."Container id"
  docker kill $id
  docker run -p 80:80 --mount source=test,target=/usr/src/app/db/ -d sbpdemo/guestbook
  docker ps
}
function run_image_with_env() {
  Write-Output "Running Image with a volume and environment variable"
  
  $InStuff = (docker ps).Split("`n").Trim("`r")
  foreach ($Index in 0..$InStuff.GetUpperBound(0))
  {
  # the 1st -replace handles the blank PORTS column
  $InStuff[$Index] = $InStuff[$Index] -replace '\s{23,}', ',,' -replace '\s{2,}', ','
  }
  $DockerPSA_Objects = $InStuff |
  ConvertFrom-Csv
  $id = ($DockerPSA_Objects | Where-Object {$_.IMAGE -match 'guestbook'})."Container id"
  docker kill $id
  docker run -p 80:80 --env NAME="Andy" --mount source=test,target=/usr/src/app/db/ -d sbpdemo/guestbook
  docker ps
}
function tag_image() {
  Write-Output "Log in to sbpdemo docker hub account"
  Write-output $cluster_name
  docker login
  Write-Output "Tagging Image"
  docker tag sbpdemo/guestbook sbpdemo/guestbook:$($cluster_name)
}
function push_image() {
  Write-Output "Pushing Image"
  docker push sbpdemo/guestbook:$($cluster_name)
}
function create_deployment() {
  Write-Output "Creating deployment"
  kubectl run my-guestbook --image sbpdemo/guestbook:$($cluster_name)
  $output = kubectl get pods
  $porttoforward = $output.split("`n")[1].substring(0,$output.split("`n")[1].indexof(" "))
  kubectl port-forward $porttoforward 8080:80
}
function expose_deployment() {
  Write-Output "Creating Load Balancer"
  kubectl expose deployment my-guestbook --type=LoadBalancer --port=80
}
function add_env_to_deployment() {
  Write-Output "Redeploying with env variable"
  kubectl delete deployment my-guestbook
  kubectl run my-guestbook --image sbpdemo/guestbook:$($cluster_name) --env NAME="Andy"
}

function copy-kubeconfig() {
  Write-Output "Copying your $($workshop_step).kubeconfig to ~/.kube/config"
  if(!(Test-path "~/.kube"))
  {
    New-Item -Path "~/" -Name ".kube" -ItemType Directory
  }
  copy-item .\$($cluster_name).kubeconfig ~/.kube/config -Force
}

function create_database() {
  kubectl apply -f mariadb/
  kubectl patch deployment mysql -p '{"spec":{"template":{"spec":{"containers":[{"name":"mysql","image":"sbpdemo/mysql:5.6"}]}}}}'
  kubectl delete deployment my-guestbook
  kubectl run my-guestbook --image sbpdemo/guestbook:$($cluster_name) --env NAME=Andy --env DATABASE_TYPE="mysql"
}

function quote_limits() {
  kubectl create --f quotas-limits/quota.yml
  kubectl scale deployment my-guestbook --replicas=10
}

function connect_to_my_cluster() {
  Write-Output Hello $cluster_name
  Invoke-WebRequest "https://s3-eu-west-1.amazonaws.com/sbp-demo-public/$($cluster_name).kubeconfig" -UseBasicParsing -OutFile ".\$($cluster_name).kubeconfig"
  Write-Output @"
  ####
  Your cluster's kubeconfig is now in the current directory as $($cluster_name).kubeconfig.
  Please copy the contents of this file this to ~/.kube/config (config is a file not a directory!)
  for example: copy-item .\userX.kubeconfig c:\users\YOURUSERNAME\.kube\config
  *** This script will NOT move the file for you ***
  PLEASE BACK UP YOUR EXISTING CONFIG FIRST!!
  ####
"@
    $response = Read-Host "Please confirm you will back up your config by typing yes (and that Andy is not responsible if you don't): "

    if ($response -eq 'yes') {
      exit 0
    }
    else {
      Write-Output "Well, you can't say you weren't warned"
      exit 1
    }
  }
function usage() {
Write-Output @"
Welcome to the containers and Kubernetes workshop! Please re-run this script with your user number and the argument 'connect'. For example, if you are user 22, run:
.\workshop.ps1 connect user22
Any questions at any time please just ask Andy, he will assign a instructor to help you. We hope you enjoy the workshop!
"@
}

$workshop_step = $Args[0]
$cluster_name = $Args[1]

switch ( $workshop_step ) {
        'check' { 
            check-tools
         }
         'connect' {
            check-tools
            connect_to_my_cluster $cluster_name
         }        
         'workshop-2-2' {
            check-tools
            download_dockerfile
         }
         'workshop-2-3' {
            check-tools
            build_image $cluster_name
            run_image
         }
         'workshop-2-4' {
            check-tools
            run_image_with_vol
         }
         'workshop-2-5' {
            check-tools
            run_image_with_env
         }
         'workshop-3-1' {
            check-tools
            copy-kubeconfig
         }
         'workshop-3-2' {
          check-tools
          tag_image
          push_image $cluster_name
         }
         'workshop-3-3' {
          check-tools
          create_deployment
          expose_deployment
         }
         'workshop-3-4' {
          check-tools
          add_env_to_deployment
         }
         'workshop-3-5' {
          check-tools
          create_database 
         }
         'workshop-4-2' {
          check-tools
          quote_limits
         }
         'push_image' {
            check-tools
            push_image $cluster_name
         }
         default { usage }
}
