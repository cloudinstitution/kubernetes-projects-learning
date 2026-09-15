## apply nging app
kubectl apply -f nginx.yaml

## apply node port service 

kubectl apply -f nodeport.yaml

## get your minikube ip 
echo $(minikube ip)

## Enable network for your ip
sudo socat TCP-LISTEN:30080,fork,reuseaddr TCP:192.168.49.2:30080

## Alternatively do the following.
sudo vi /etc/systemd/system/socat-30080.service

## daemon-reload
sudo systemctl daemon-reload
## enable 30080 service
sudo systemctl enable --now socat-30080.service
