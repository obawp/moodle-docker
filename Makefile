include ./.env
export

build:
	- docker build -t ${REPO}-${WEBSERVER} ./docker-files/moodle/${WEBSERVER}/

build_verbose:
	- docker build --progress=plain -t ${REPO}-${WEBSERVER} ./docker-files/moodle/${WEBSERVER}/

build_no_cache:
	- docker build --no-cache --pull -t ${REPO}-${WEBSERVER} ./docker-files/moodle/${WEBSERVER}/

login:
	- echo ${DOCKERHUB_PASS} | docker login -u ${DOCKERHUB_USER} --password-stdin

push:
	- docker push ${REPO}-${WEBSERVER}

pull:
	- docker pull ${REPO}-${WEBSERVER}

run:
	- docker run -d --name ${STACK}_aux ${REPO}-${WEBSERVER}

mkdir:
	- mkdir -p ./vol/moodle/html
	- mkdir -p ./vol/moodle/data
	- mkdir -p ./vol/${DBTYPE}/data
	- docker cp ${STACK}_aux:/var/www/html ./vol/moodle/

rmdir:
	- sudo rm -Rf ./vol/moodle/html
	- sudo rm -Rf ./vol/moodle/data
	- sudo rm -Rf ./vol/mysql/data
	- sudo rm -Rf ./vol/pgsql/data

up:
	- docker compose -p ${STACK} -f "./docker-compose.${DBTYPE}.yml" up -d

install:
	-  docker exec -u www-data -w /var/www/html/admin/cli ${STACK}_web /usr/bin/php install_database.php --lang=en --adminuser=${MOODLE_ADMIN_USER} --adminpass=${MOODLE_ADMIN_PASSWORD} --adminemail=${MOODLE_ADMIN_EMAIL} --fullname=${MOODLE_SITE_FULLNAME} --shortname=${MOODLE_SITE_SHORTNAME}  --agree-license

cron: #install
	- docker exec -u 0 ${STACK}_web bash -c "echo '* * * * * /usr/bin/php /var/www/html/admin/cli/cron.php >/dev/null 2>&1' | sudo crontab -u www-data -"

perm:
	-  docker exec -u 0 ${STACK}_web chown www-data:www-data -R /var/www/html/
	-  docker exec -u 0 ${STACK}_web chmod -R 0750 /var/www/html
	-  docker exec -u 0 ${STACK}_web find /var/www/html -type f -exec chmod 0640 {} \;
	-  docker exec -u 0 ${STACK}_web chown www-data:www-data -R /var/www/moodledata
	-  docker exec -u 0 ${STACK}_web chmod -R 0770 /var/www/moodledata
	-  docker exec -u 0 ${STACK}_web find /var/www/moodledata -type f -exec chmod 0660 {} \;

perm_dev:
	-  sudo chown antonio:www-data -R ./vol/moodle/config.mysql.php
	-  sudo chown antonio:www-data -R ./vol/moodle/config.pgsql.php
	-  sudo chmod -R 0770 ./vol/moodle/config.mysql.php
	-  sudo chmod -R 0770 ./vol/moodle/config.pgsql.php
	-  sudo chown antonio:www-data -R ./vol/moodle/html
	-  sudo chmod -R 0770 ./vol/moodle/html
	-  sudo chmod -R 0770 ./vol/moodle/data
	-  sudo chown www-data:www-data -R ./vol/moodle/data

perm_db:
	-  docker exec -u 0 ${STACK}_db chown -R mysql:mysql /var/lib/mysql

rm:
	- docker rm ${STACK}_aux -f
	- docker compose -p ${STACK} -f "./docker-compose.${DBTYPE}.yml" down

purge_caches:
	-  docker exec -u www-data -w /var/www/html/admin/cli ${STACK}_web /usr/bin/php purge_caches.php
