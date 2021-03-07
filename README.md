- [go-web-hello-world](#go-web-hello-world)
  - [Task 0: Install a ubuntu server 64-bit in VirtualBox](#task-0-install-a-ubuntu-server-64-bit-in-virtualbox)
  - [Task 1: Update system](#task-1-update-system)
  - [Task 2: Install gitlab-ce version in the host](#task-2-install-gitlab-ce-version-in-the-host)
  - [Task 3: Create a demo group/project in gitlab and set up Golang env](#task-3-create-a-demo-groupproject-in-gitlab-and-set-up-golang-env)
  - [Task 4: Build the web app and expose the service to 8081 port](#task-4-build-the-web-app-and-expose-the-service-to-8081-port)
  - [Task 5: Install docker](#task-5-install-docker)
  - [Task 6: Run the web app in container](#task-6-run-the-web-app-in-container)
  - [Task 7: Push image to docker hub](#task-7-push-image-to-docker-hub)
## go-web-hello-world

This guide will introduce how to install gitlab ce, build golang web app and run the web app in container.

If the pictures can not show, it's due to the network access restriction from your area, try to download the repo or check pictures in images subfolder.

### Task 0: Install a ubuntu server 64-bit in VirtualBox

**0.1 Download VirtualBox and install it**

Download link: https://www.virtualbox.org/wiki/Downloads

Install VirtualBox 6.1.

**0.2 Download ubuntu server iso**

Download link: http://releases.ubuntu.com/16.04/ubuntu-16.04.7-server-amd64.iso

To accelerate the downloading speed, we can use the mirrors in China: http://mirrors.zju.edu.cn/ubuntu-releases/

**0.3 Install ubuntu  server in VirtualBox**

My desktop system is Win10, there is issue after installing ubuntu server 16.04  in VirtulBox6.1.  The cursor keeps blinking in the upper left corner of the screen and the system can not start successfully.

I changed to install ubuntu server 20.04 in VirtualBox.

In VitualBox, go to the global preferences setting -> Network, add new NAT Networks, set Port Forwarding rules as below：

- 22->2222 for ssh (2222 is the Host Port)
- 80->8080 for gitlab
- 8081/8082->8081/8082 for go app
- 31080/31081->31080/31081 for go app in k8s

In ubuntu VM, go to the Network setting, attach to he NAT Network made just now.

### Task 1: Update system

We can use XShell to ssh to the VM with port 2222. Upgrade the kernel to the latest.

```
$ sudo apt-get update
$ sudo apt-get upgrade
```

### Task 2: Install gitlab-ce version in the host

**2.1 Install and configure the necessary dependencies**

```
$ sudo apt-get update
$ sudo apt-get install -y curl openssh-server ca-certificates tzdata perl
```

Next, install Postfix to send notification emails. It's not mandatory.

If you want to use another solution to send emails please skip this step and configure an external SMTP server after GitLab has been installed. During Postfix installation a configuration screen may appear. Select 'Internet Site' and press enter. 

```
$ sudo apt-get install -y postfix
```

**2.2 Add the GitLab package repository and install the package**

Add the GitLab package repository

```
$ cd /tmp
$ curl -LO https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh
$ sudo bash /tmp/script.deb.sh
```

Update to use the package source mirror in China.

```
$ cat > /etc/apt/sources.list.d/gitlab_gitlab-ce.list <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu focal main
deb-src https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu focal main
EOF
```

Next, install the GitLab package. In VM, just ignore the EXTERNAL_URL setting. (Installation will automatically configure and start GitLab at EXTERNAL_URL)

```
$ sudo apt-get update
$ sudo apt-get install gitlab-ee
$ # sudo EXTERNAL_URL="http://gitlab.example.com" apt-get install gitlab-ee
```

After installation, if you want to change the configuration, you can edit `/etc/gitlab/gitlab.rb` and run `sudo gitlab-ctl reconfigure` to apply it.

```
$ sudo vim /etc/gitlab/gitlab.rb
$ sudo gitlab-ctl reconfigure
$ sudo gitlab-ctl restart
$ sudo gitlab-ctl status
```

Start gitlab when system restarts.

```
$ sudo systemctl enable gitlab-runsvdir.service
```

**2.3 Access it from host machine**

Access http://127.0.0.1:8080/.

When you access gitlab at the first time, you need to input the password for admin user "root". 

![image-20210306123831606](images/image-20210306123831606.png?raw=true)

**2.4 Issue Solving**

After runing a while, the webpage returns error: Whoops, GitLab is taking too much time to respond. 

It's because the storage space is not enough. Make sure your VM has 4G base memory and 20G storage.

![image-20210306132936047](images/image-20210306132936047.png?raw=true)

### Task 3: Create a demo group/project in gitlab and set up Golang env

**3.1 Create a demo group/project in gitlab**

Register a gitlab user and login into gitlab, create new group named "demo", create new project "go-web-hello-world". 

You can access the project at http://127.0.0.1:8080/demo/go-web-hello-world:

![image-20210306130001376](images/image-20210306130001376.png?raw=true)

**3.2 set up Golang env**

Install golang.

```
$ sudo apt-get install golang
$ go version  
go version go1.13.8 linux/amd64
```

Configure golang environments. You can check golang environments using `go env`.

```
$ mkdir ~/workspace
$ mkdir ~/workspace/bin
$ mkdir ~/workspace/pkg
$ mkdir ~/workspace/src
$ echo 'export GOPATH="$HOME/workspace"' >> ~/.bashrc
$ echo 'export GOBIN="$HOME/workspace/bin"' >> ~/.bashrc
$ source ~/.bashrc
```

### Task 4: Build the web app and expose the service to 8081 port

Create file `helloworld.go`, below is the complete code. The web app port is set to 8081.

```go
package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        // fmt.Fprintf(w, "Hello, you've requested: %s\n", r.URL.Path)
        fmt.Fprintf(w, "Go Web Hello World!\n")
    })

    http.ListenAndServe(":8081", nil)
}
```

Run `go run`  to start web app.

```
$ go run helloworld.go
```

Or run `go install`  to generate executable file and execute it.

```
$ go install helloworld.go 
$ $GOBIN/helloworld 
```

Now you can access the web app.

```
$ curl http://localhost:8081
Go Web Hello World!
```

![image-20210306130610636](images/image-20210306130610636.png?raw=true)

### Task 5: Install docker

Install docker.

```
$ sudo curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
```

Add your account to group "docker" so that you have related permissions to operate docker.

```
$ sudo usermod -aG docker <account>
```

Start docker service and set docker as auto starting service.

```
$ sudo systemctl start docker
$ sudo systemctl enable docker
```

Update to use the docker source mirror in China.

```
$ sudo mkdir -p /etc/docker

$ sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://t7mjep56.mirror.aliyuncs.com"]
}

$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```

### Task 6: Run the web app in container

**6.1 Pull golang image**

We can access https://hub.docker.com/_/golang?tab=tagto find out the suitable image, I choose `golang:alpine3.13` in this case.

```
docker pull golang:alpine3.13
```

**6.2 Make dockerfile and build image**

The dockerfile is as below. Check in the dockerfile to gitlab project.

```
FROM golang:alpine3.13

WORKDIR /go/src
COPY helloworld.go ./

RUN go install helloworld.go 
EXPOSE 8081

CMD ["/go/bin/helloworld"]
```

Build image `go-web-hello-world:v0.1`.

```
$ docker build -f dockerfile -t go-web-hello-world:v0.1 .
```

**6.3 Run web app container**

Run container using  image `go-web-hello-world:v0.1`. Expose the service to VM port 8082.

```
$ docker run -dit --name go-helloword -p 8082:8081 go-web-hello-world:v0.1
```

Access the web app.

```
$ curl http://127.0.0.1:8082
Go Web Hello World!
```

![image-20210307000622613](images/image-20210307000622613.png?raw=true)

### Task 7: Push image to docker hub

Register account in docker hub https://hub.docker.com/. My account is "liangwq".

Tag the docker image with `liangwq/go-web-hello-world:v0.1`.

```
$ docker tag go-web-hello-world:v0.1 liangwq/go-web-hello-world:v0.1
```

Push the image to docker hub.

```
$ docker login
$ docker push liangwq/go-web-hello-world:v0.1
```

Now we can access the image in docker hub: https://hub.docker.com/r/liangwq/go-web-hello-world/

Pull the image.

```
$ docker pull liangwq/go-web-hello-world:v0.1
```


