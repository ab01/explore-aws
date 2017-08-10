# Assignment

#### Basic problem
You need to create two environments - training and production. Initially, production environment should be on limited release (only one server) and you must plan for the scale out during fully public release.

#### Assumptions
 -    The development team has a continuous integration build that produces two artifacts:
 -    .zip file with the image and stylesheet used for the application
 -    .war file with the dynamic parts of the application
 -    You should deploy the static assets to a web server and the .war file to a separate application server. Any compatible servers are acceptable.
 -    The app (companyNews) uses Prevayler for persistence. Prevayler essentially persists data to a file. The dev team chose this to simplify the development effort, rather than having to deal with an RDBMS.

####  Tools used
  1.  Docker  - Containers
  2. Docker-Compose - Orchestration
  3. Consul - Service Discovery
  4. Registrator - Service Registration
  5. Nginx - Load Banlancer and Reverse Proxy
  6. Consul-template - populate values from Consul into the file system using the consul-template daemon

## HowTo

#1. Create tomcat/war Application Server docker image from Dockerfile named Dockerfile.myapp

    docker create -t myapp .

#2. Create Nginx/Consul-template with static content Server docker image Dockerfile named Dockerfile.proxy

    docker create -t proxy/web .

#3. Now we can create both training and production environment using docker-compose file provided

      - set variables HOST_IP,DOCKER_IP,CONSUL_IP with Network IP of local machine
          - example export HOST_IP=10.0.0.34

      - Building Training environment
          - docker-compose -f docker-compose-setup.yml up -d consul-server
          - docker-compose -f docker-compose-setup.yml up -d registrator
          - docker-compose -f docker-compose-setup.yml up -d training-myapp
          - docker-compose -f docker-compose-setup.yml up -d training-proxy

      - Building Production environment
          - docker-compose -f docker-compose-setup.yml up -d consul-server
          - docker-compose -f docker-compose-setup.yml up -d registrator
          - docker-compose -f docker-compose-setup.yml up -d production-myapp
          - docker-compose -f docker-compose-setup.yml up -d production-proxy

#4. To scale out in Production :nginx would discover new application tomcat docker containers with help of consul and updates its configuration and reload without any downtime

       docker run -it -d -e "SERVICE_NAME=tomcat" -p 8081:8080 --name production02 myapp
