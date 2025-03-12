include ./.env
export

build:
	- docker build -t ${REPO} ./docker-files/moodle/

login:
	- echo ${DOCKERHUB_PASS} | docker login -u ${DOCKERHUB_USER} --password-stdin

push:
	- docker push ${REPO}

pull:
	- docker pull ${REPO}

run:
	- docker run -d --name ${STACK}_aux ${REPO}

mkdir:
	- mkdir -p ./vol/moodle/html
	- mkdir -p ./vol/postgresql/data

	- docker cp ${STACK}_aux:/var/www/html ./vol/moodle/
	- docker cp ${STACK}_aux:/etc/php/8.2/cli/php.ini ./vol/moodle/php.ini 
	- bash -c "echo 'max_input_vars = 10000' >> ./vol/moodle/php.ini"

rmdir:
	- sudo rm -Rf ./vol

up:
	- docker compose -p ${STACK} -f "./docker-compose.yml" up -d

install:
	-  docker exec -u www-data -w /var/www/html/admin/cli ${STACK}_web /usr/bin/php install_database.php --lang=${LANG} --adminuser=${MOODLE_ADMIN_USER} --adminpass=${MOODLE_ADMIN_PASSWORD}--adminemail=${MOODLE_ADMIN_EMAIL} --fullname=${MOODLE_SITE_FULLNAME} --shortname=${MOODLE_SITE_SHORTNAME}  --agree-license

cron: #install
	- docker exec -u 0 ${STACK}_web bash -c "echo '* * * * * /usr/bin/php /var/www/html/admin/cli/cron.php >/dev/null 2>&1' | sudo crontab -u www-data -"

perm:
	-  docker exec -u 0 ${STACK}_web chown www-data:www-data -R /var/www/html/
	-  docker exec -u 0 ${STACK}_web chmod -R 0750 /var/www/html
	-  docker exec -u 0 ${STACK}_web find /var/www/html -type f -exec chmod 0640 {} \;
	-  docker exec -u 0 ${STACK}_web chown www-data:www-data -R /var/www/html/moodledata
	-  docker exec -u 0 ${STACK}_web chmod -R 0770 /var/www/html/moodledata
	-  docker exec -u 0 ${STACK}_web find /var/www/html/moodledata -type f -exec chmod 0660 {} \;

perm_dev:
	-  sudo chown :antonio -R ./vol/moodle/html
	-  sudo chmod -R 0770 ./vol/moodle/html

down:
	- docker compose -p ${STACK} -f "./docker-compose.yml" down

rm:
	- docker rm ${STACK}_aux -f

purge_cache:
	-  docker exec -u www-data -w /var/www/html/admin/cli ${STACK}_web /usr/bin/php purge_caches.php
