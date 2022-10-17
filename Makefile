AWS_PROFILE               := paas-experiments-admin
GDS_CLI                   := gds
ASSUME_ROLE               := $(GDS_CLI) aws $(AWS_PROFILE) --   
DOMAIN                    := experiments.cloudpipeline.digital
DRAWIO                    := /Applications/draw.io.app/Contents/MacOS/draw.io
SHELL                     := bash
APP_NAME                  := hello-steampipe
DASHBOARD_SERVICE_NAME    := dashboard
NGINX_SERVICE_NAME        := mynginx3
DOCKER_USER               := dougapd
DIR                       := $(shell pwd)

menu:
	egrep -E "^[0-9]{2}" Makefile | gsed 's/://'

status:
	@copilot svc status -n dashboard
	@copilot svc status -n nginx

play:
	@find casts -type f | sort | header -a "asciinema_cast" | vd -f csv | gsed 1d | xargs -n 1 asciinema play -s 4

build:
	docker build -t $(DASHBOARD_SERVICE_NAME) steampipe
	docker build -t $(NGINX_SERVICE_NAME) nginx

env:
	$(ASSUME_ROLE) copilot env ls

init-request-driven-web-service: Dockerfile
	$(ASSUME_ROLE) \
	copilot app init --app $(APP_NAME) \
  	--name $(SERVICE_NAME) \
  	--dockerfile "./Dockerfile" \
	--port 8080 

init-load-balanced-web-service: Dockerfile
	$(ASSUME_ROLE) \
	copilot init \
	--app $(APP_NAME) \
  	--name $(SERVICE_NAME) \
  	--type "Load Balanced Web Service" \
	--port 8080 \
  	--dockerfile "./Dockerfile" 

init-back-end-service: Dockerfile
	$(ASSUME_ROLE) \
	copilot init \
	--app $(APP_NAME) \
  	--name $(SERVICE_NAME) \
  	--type "Backend Service" \
	--port 8080 \
  	--dockerfile "./Dockerfile" 

edit-diagram: docs/steampipe-deploy.drawio.xml
	$(DRAWIO) $^

publish-diagram: docs/steampipe-deploy.png docs/steampipe-deploy.svg

docs/steampipe-deploy.svg: docs/steampipe-deploy.drawio.xml
	$(DRAWIO) -x -e  -o $@ $<

docs/steampipe-deploy.png: docs/steampipe-deploy.drawio.xml
	$(DRAWIO) -x -e  -o $@ $<
 	
deploy:
	copilot deploy

delete:
	copilot app delete

docker-push:
	docker push $(DOCKER_USER)/$(DASHBOARD_SERVICE_NAME )

dashboard-run:
	docker run --rm -ti -p 8080:8080 $(DASHBOARD_SERVICE_NAME)

aws: aws-console aws-shell

aws-console:
	# check we are on the VPN else GDS CLI will fail
	gds aws paas-experiments-admin -l

aws-shell: 
	# check we are on the VPN else GDS CLI will fail
	$(ASSUME_ROLE) $(SHELL)

deps:
	brew install aws/tap/copilot-cli
	brew install steampipe
	steampipe plugin install aws
	steampipe plugin install csv
	steampipe plugin install github

pull:
	docker pull nginx
	docker pull turbot/steampipe

frontend-run-mountconfig:
	@echo "http://localhost:8081"
	docker run --name mynginx2 -v $(DIR)/nginx/www:/usr/share/nginx/html -p 8081:80 nginx

count-vpcs:
	steampipe query "select count(*) from aws_vpc where region = 'eu-west-2'"

aws-data:
	steampipe query "select * from aws_vpc" --output csv > data/vpc.csv
	steampipe query "select * from aws_ecs_cluster" --output csv > data/ecs_cluster.csv
	steampipe query "select * from aws_ecs_service" --output csv > data/ecs_service.csv
	steampipe query "select * from aws_ecs_task" --output csv > data/ecs_task.csv
	steampipe query "select * from aws_ecs_container_instance" --output csv > data/ecs_container_instance.csv
	steampipe query "select * from aws_ecr_repository" --output csv > data/ecr_repository.csv
	steampipe query "select * from aws_ecr_image" --output csv > data/ecr_image.csv

test:
	@steampipe query "select * from aws_account" --output csv

check_VPN:
	@echo $(shell ./bin/is_on_VPN)

warning:
	$(warning this is just a warnin)

info:
	$(info this is informational only)

error:
	$(error this is an error boo)

check:
	bin/check

01-app-init:
	asciinema rec -c 'copilot app init hello-steampipe --resource-tags department=GDS,team=govuk-paas,owner=paul.dougan --domain experiments.cloudpipelineapps.digital' 		casts/01-app-init.cast
	#asciinema rec -c 'copilot app init hello-steampipe --resource-tags department=GDS,team=govuk-paas,owner=paul.dougan,project=decommission' 	
	#asciinema rec --append -c 'copilot app ls; copilot app show' 	casts/01-app-init.cast
	
02-env-init:
	# add --region eu-west2
	asciinema rec          -c 'copilot env init -n dev --container-insights' 		casts/02-env-init.cast
	#asciinema rec --append -c 'copilot env init -n staging --container-insights' 	casts/02-env-init.cast
	#asciinema rec --append -c 'copilot env init -n production --container-insights'	casts/02-env-init.cast
	asciinema rec --append -c 'copilot env ls' 			casts/02-env-init.cast

03-env-deploy:
	asciinema rec          -c 'copilot env deploy -n dev' 		casts/03-env-deploy.cast
	asciinema rec --append -c 'copilot env ls' 			casts/03-env-deploy.cast
	asciinema rec --append -c 'copilot env show -n dev' 		casts/03-env-deploy.cast

04-svc-init-dashboard:
	asciinema rec          -c 'copilot svc init  -d dashboard/Dockerfile -n dashboard -t "Backend Service"' casts/04-svc-init-dashboard.cast
	asciinema rec --append -c 'copilot svc ls' 			casts/04-svc-init-dashboard.cast
	asciinema rec --append -c 'copilot svc show -n dashboard' 	casts/04-svc-init-dashboard.cast

05-svc-deploy-dashboard:
	asciinema rec          -c 'copilot svc deploy -e dev -n dashboard' casts/05-svc-deploy-dashboard.cast
	asciinema rec --append -c 'copilot svc ls' 			casts/05-svc-deploy-dashboard.cast
	asciinema rec --append -c 'copilot svc show -n dashboard'	casts/05-svc-deploy-dashboard.cast

06-svc-init-nginx:
	asciinema rec          -c 'copilot svc init -d nginx/Dockerfile.3 -n nginx -t "Load Balanced Web Service"' casts/06-svc-init-nginx.cast
	asciinema rec --append -c 'copilot svc ls' 			casts/06-svc-init-nginx.cast
	asciinema rec --append -c 'copilot svc show -n nginx' 		casts/06-svc-init-nginx.cast

07-svc-deploy-nginx:
	asciinema rec          -c 'copilot svc deploy -e dev -n nginx' casts/07-svc-deploy-nginx.cast
	asciinema rec --append -c 'copilot svc ls' 			casts/07-svc-deploy-nginx.cast
	asciinema rec --append -c 'copilot svc show -n nginx'		casts/07-svc-deploy-nginx.cast

08-svc-delete-nginx:
	asciinema rec          -c 'copilot svc delete -e dev -n nginx' casts/08-svc-delete-nginx.cast
	
09-app-delete:
	asciinema rec          -c 'copilot app delete' casts/09-app-delete.cast

0607: 06-svc-init-nginx 07-svc-deploy-nginx
