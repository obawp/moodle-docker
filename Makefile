include ./.env
export

build:
	- docker build -t ${REPO}-${WEBSERVER} ./docker-files/moodle/${WEBSERVER}/

build_verbose:
	- docker build --progress=plain -t ${REPO}-${WEBSERVER} ./docker-files/moodle/${WEBSERVER}/

build_no_cache:
	- docker build --no-cache --pull -t ${REPO}-${WEBSERVER} ./docker-files/moodle/${WEBSERVER}/

login:
	- echo "${DOCKERHUB_PASS}" | docker login -u ${DOCKERHUB_USER} --password-stdin

push:
	- docker push ${REPO}-${WEBSERVER}

pull:
	- docker pull ${REPO}-${WEBSERVER}

run:
	- docker run -d --name ${STACK}_aux ${REPO}-${WEBSERVER}

mkdir:
	- sudo mkdir -p ${VOLUME_DIR}/moodle/data
	- sudo mkdir -p ${VOLUME_DIR}/${DBTYPE}/data
	- sudo chown $$USER:www-data ${VOLUME_DIR}/
	- sudo chown $$USER:www-data ${VOLUME_DIR}/moodle/
	- sudo chown $$USER:www-data ${VOLUME_DIR}/${DBTYPE}/
	- sudo chown $$USER:www-data ./config/moodle/config.${DBTYPE}.php
	- sudo chmod 640 ./config/moodle/config.${DBTYPE}.php
	- sudo chown $$USER:www-data ${VOLUME_DIR}/moodle/data
	- sudo chown $$USER:www-data ${VOLUME_DIR}/${DBTYPE}/data
	- docker cp ${STACK}_aux:/var/www/html ./src

rmdir:
	- make --no-print-directory rmdir_html
	- make --no-print-directory rmdir_db

rmdir_html:
	- sudo rm -Rf ./src/
	- sudo rm -Rf ${VOLUME_DIR}/moodle/data/

rmdir_db:
	- sudo rm -Rf ${VOLUME_DIR}/${DBTYPE}/data/

up:
	- docker compose -p ${STACK} --project-directory ./ -f "./docker-compose/docker-compose.${DBTYPE}.yml" up -d

bash:
	- docker exec -it -u 0 -w /var/www/html ${STACK}_moodle_web bash

install:
	- docker exec -u www-data -w /var/www/html/admin/cli ${STACK}_moodle_web /usr/bin/php install_database.php --lang=en --adminuser=${MOODLE_ADMIN_USER} --adminpass=${MOODLE_ADMIN_PASSWORD} --adminemail=${MOODLE_ADMIN_EMAIL} --fullname=${MOODLE_SITE_FULLNAME} --shortname=${MOODLE_SITE_SHORTNAME}  --agree-license
	- docker cp ./docker-files/moodle/apache/.htaccess ${STACK}_moodle_web:/var/www/html 
	- docker exec -u 0 ${STACK}_moodle_web chown www-data:www-data -R /var/www/html/.htaccess
	- docker exec -u 0 ${STACK}_moodle_web chmod 640 /var/www/html/.htaccess

cron: #install
	- docker exec -u 0 ${STACK}_moodle_web bash -c "echo '* * * * * /usr/bin/php /var/www/html/admin/cli/cron.php >/dev/null 2>&1' | sudo crontab -u www-data -"

perm:
	- make --no-print-directory perm_html
	- make --no-print-directory perm_moodledata

perm_html:
	- docker exec -u 0 ${STACK}_moodle_web chown www-data:www-data -R /var/www/html/
	- sudo chown $$USER:www-data ./config/moodle/config.${DBTYPE}.php
	- sudo chmod 0660 ./config/moodle/config.${DBTYPE}.php
	- docker exec -u 0 ${STACK}_moodle_web find /var/www/html -type d -exec chmod 0750 {} \;
	- docker exec -u 0 ${STACK}_moodle_web find /var/www/html -type f -exec chmod 0640 {} \;
	-  docker exec -u 0 ${STACK}_moodle_web find /var/www/html -not -path '/var/www/html/php.ini' -type f -iname php.ini  -exec chown $$USER:root {} \;

perm_moodledata:
	- docker exec -u 0 ${STACK}_moodle_web chown www-data:www-data -R /var/www/moodledata
	- docker exec -u 0 ${STACK}_moodle_web find /var/www/moodledata -type d -exec chmod 0770 {} \;
	- docker exec -u 0 ${STACK}_moodle_web find /var/www/moodledata -type f -exec chmod 0660 {} \;

perm_dev:
	- sudo chown $$USER:www-data -R ./src
	- sudo chown $$USER:www-data ./config/moodle/config.${DBTYPE}.php
	- sudo chmod 0660 ./config/moodle/config.${DBTYPE}.php
	- sudo find ./src -type d -exec chmod 0770 {} \;
	- sudo find ./src -type f -exec chmod 0660 {} \;
	- sudo find ${VOLUME_DIR}/moodle/data -type d -exec chmod 0770 {} \;
	- sudo find ${VOLUME_DIR}/moodle/data -type f -exec chmod 0660 {} \;
	- sudo chown www-data:www-data -R ${VOLUME_DIR}/moodle/data
	- docker exec -u 0 ${STACK}_moodle_web find /var/www/html -not -path '/var/www/html/php.ini' -type f -iname php.ini  -exec chown $$USER:root {} \;

perm_dev_dir:
	- sudo chown $$USER:www-data -R ./src/${WORK_DIR}
	- sudo find ./src/${WORK_DIR} -type d -exec chmod 0770 {} \;
	- sudo find ./src/${WORK_DIR} -type f -exec chmod 0660 {} \;

perm_db:
	- docker exec -u 0 ${STACK}_moodle_db chown -R mysql:mysql /var/lib/mysql

phpu_mkdir:
	- sudo mkdir -p ${VOLUME_DIR}/phpunit/moodle/data
	- sudo mkdir -p ${VOLUME_DIR}/phpunit/${DBTYPE}/data
	- sudo chown $$USER:www-data ${VOLUME_DIR}/phpunit/

phpu_perm:
	- sudo chown -R $$USER:www-data ${VOLUME_DIR}/phpunit/moodle/data/+2
	- sudo chmod 0770 ${VOLUME_DIR}/phpunit/moodle/data/
	- sudo find ${VOLUME_DIR}/phpunit/moodle/data -type d -exec chmod 0770 {} \;
	- sudo find ${VOLUME_DIR}/phpunit/moodle/data -type f -exec chmod 0660 {} \;

phpu_install:
	-  docker exec -u www-data -w /var/www/html/ ${STACK}_moodle_web composer install
	-  docker exec -u www-data -w /var/www/html/ ${STACK}_moodle_web /usr/bin/php admin/tool/phpunit/cli/init.php

phpu_rmdir:
	- sudo rm -Rf ${VOLUME_DIR}/phpunit/moodle/data/*
	- sudo rm -Rf ${VOLUME_DIR}/phpunit/${DBTYPE}/data/*


rm:
	- docker rm ${STACK}_aux -f
	- docker compose -p ${STACK} -f "./docker-compose/docker-compose.${DBTYPE}.yml" down

purge_caches:
	-  docker exec -u www-data -w /var/www/html/admin/cli ${STACK}_moodle_web /usr/bin/php purge_caches.php

upgrade:
	-  docker exec -u www-data -w /var/www/html/admin/cli ${STACK}_moodle_web /usr/bin/php upgrade.php

backup:
	- docker exec -u 0 ${STACK}_moodle_db mariadb-backup --backup --target-dir=/var/mariadb/backup/ --user=root --password=mypassword



install_missing_plugins:
	- make --no-print-directory -f ./dump/Makefile install_missing_plugins

uninstall_missing_plugins:
	- make --no-print-directory -f ./dump/Makefile uninstall_missing_plugins