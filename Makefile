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
	- sudo mkdir -p ./vol/moodle/html
	- sudo mkdir -p ./vol/moodle/data
	- sudo mkdir -p ./vol/mariadb/data
	- sudo mkdir -p ./vol/mysql/data
	- sudo mkdir -p ./vol/pgsql/data

	- sudo mkdir -p ./backup/moodle/
	- sudo mkdir -p ./backup/mariadb/
	- sudo mkdir -p ./backup/mysql/
	- sudo mkdir -p ./backup/pgsql/
	- sudo mkdir -p ./backup/phpu/

	- sudo chown $$USER:www-data ./vol/
	- sudo chown $$USER:www-data ./vol/moodle/
	- sudo chown $$USER:www-data ./vol/mariadb/
	- sudo chown $$USER:www-data ./vol/mysql/
	- sudo chown $$USER:www-data ./vol/pgsql/
	- sudo chown $$USER:www-data ./vol/moodle/config.mariadb.php
	- sudo chown $$USER:www-data ./vol/moodle/config.mysql.php
	- sudo chown $$USER:www-data ./vol/moodle/config.pgsql.php
	- sudo chmod 640 ./vol/moodle/config.mariadb.php
	- sudo chmod 640 ./vol/moodle/config.mysql.php
	- sudo chmod 640 ./vol/moodle/config.pgsql.php
	- sudo chown $$USER:www-data ./vol/moodle/html
	- sudo chown $$USER:www-data ./vol/moodle/data
	- sudo chown $$USER:www-data ./vol/mariadb/data
	- sudo chown $$USER:www-data ./vol/mysql/data
	- sudo chown $$USER:www-data ./vol/pgsql/data
	- docker cp ${STACK}_aux:/var/www/html ./vol/moodle/

rmdir:
	- sudo rm -Rf ./vol/moodle/html/ 
	- sudo rm -Rf ./vol/moodle/data/

rmdir_db:
	- sudo rm -Rf ./vol/mariadb/data/
	- sudo rm -Rf ./vol/mysql/data/
	- sudo rm -Rf ./vol/pgsql/data/

up:
	- docker compose -p ${STACK} -f "./docker-compose.${DBTYPE}.yml" up -d

bash:
	-  docker exec -it -u 0 -w /var/www/html ${STACK}_moodle_web bash

install:
	-  docker exec -u www-data -w /var/www/html/admin/cli ${STACK}_moodle_web /usr/bin/php install_database.php --lang=en --adminuser=${MOODLE_ADMIN_USER} --adminpass=${MOODLE_ADMIN_PASSWORD} --adminemail=${MOODLE_ADMIN_EMAIL} --fullname=${MOODLE_SITE_FULLNAME} --shortname=${MOODLE_SITE_SHORTNAME}  --agree-license

cron: #install
	- docker exec -u 0 ${STACK}_moodle_web bash -c "echo '* * * * * /usr/bin/php /var/www/html/admin/cli/cron.php >/dev/null 2>&1' | sudo crontab -u www-data -"

perm:
	-  docker exec -u 0 ${STACK}_moodle_web chown www-data:www-data -R /var/www/html/
	-  sudo chown $$USER:www-data ./vol/moodle/config.mariadb.php
	-  sudo chown $$USER:www-data ./vol/moodle/config.mysql.php
	-  sudo chown $$USER:www-data ./vol/moodle/config.pgsql.php
	-  sudo chmod 0660 ./vol/moodle/config.mariadb.php
	-  sudo chmod 0660 ./vol/moodle/config.mysql.php
	-  sudo chmod 0660 ./vol/moodle/config.pgsql.php
	-  docker exec -u 0 ${STACK}_moodle_web find /var/www/html -type d -exec chmod 0750 {} \;
	-  docker exec -u 0 ${STACK}_moodle_web find /var/www/html -type f -exec chmod 0640 {} \;

perm_moodledata:
	-  docker exec -u 0 ${STACK}_moodle_web chown www-data:www-data -R /var/www/moodledata
	-  docker exec -u 0 ${STACK}_moodle_web find /var/www/moodledata -type d -exec chmod 0770 {} \;
	-  docker exec -u 0 ${STACK}_moodle_web find /var/www/moodledata -type f -exec chmod 0660 {} \;

perm_dev:
	-  sudo chown $$USER:www-data -R ./vol/moodle/html
	-  sudo chown $$USER:www-data ./vol/moodle/config.mariadb.php
	-  sudo chown $$USER:www-data ./vol/moodle/config.mysql.php
	-  sudo chown $$USER:www-data ./vol/moodle/config.pgsql.php
	-  sudo chmod 0660 ./vol/moodle/config.mariadb.php
	-  sudo chmod 0660 ./vol/moodle/config.mysql.php
	-  sudo chmod 0660 ./vol/moodle/config.pgsql.php
	-  sudo find ./vol/moodle/html -type d -exec chmod 0770 {} \;
	-  sudo find ./vol/moodle/html -type f -exec chmod 0660 {} \;
	-  sudo find ./vol/moodle/data -type d -exec chmod 0770 {} \;
	-  sudo find ./vol/moodle/data -type f -exec chmod 0660 {} \;
	-  sudo chown www-data:www-data -R ./vol/moodle/data

perm_dev_dir:
	-  sudo chown $$USER:www-data -R ./vol/moodle/html/${WORK_DIR}
	-  sudo find ./vol/moodle/html/${WORK_DIR} -type d -exec chmod 0770 {} \;
	-  sudo find ./vol/moodle/html/${WORK_DIR} -type f -exec chmod 0660 {} \;

perm_db:
	-  docker exec -u 0 ${STACK}_moodle_db chown -R mysql:mysql /var/lib/mysql

phpu_mkdir:
	- sudo mkdir -p ./vol/phpu/data
	- sudo mkdir -p ./vol/phpu/${DBTYPE}/data
	- sudo chown $$USER:www-data ./vol/phpu/

phpu_perm:
	- sudo chown -R $$USER:www-data ./vol/phpu/data/+2
	- sudo chmod 0770 ./vol/phpu/data/
	- sudo find ./vol/phpu/data -type d -exec chmod 0770 {} \;
	- sudo find ./vol/phpu/data -type f -exec chmod 0660 {} \;

phpu_install:
	-  docker exec -u www-data -w /var/www/html/ ${STACK}_moodle_web composer install
	-  docker exec -u www-data -w /var/www/html/ ${STACK}_moodle_web /usr/bin/php admin/tool/phpunit/cli/init.php

phpu_rmdir:
	- sudo rm -Rf ./vol/phpu/data/*
	- sudo rm -Rf ./vol/phpu/${DBTYPE}/data/*


rm:
	- docker rm ${STACK}_aux -f
	- docker compose -p ${STACK} -f "./docker-compose.${DBTYPE}.yml" down

purge_caches:
	-  docker exec -u www-data -w /var/www/html/admin/cli ${STACK}_moodle_web /usr/bin/php purge_caches.php

upgrade:
	-  docker exec -u www-data -w /var/www/html/admin/cli ${STACK}_moodle_web /usr/bin/php upgrade.php

backup:
	- docker exec -u 0 ${STACK}_moodle_db mariadb-backup --backup --target-dir=/var/mariadb/backup/ --user=root --password=mypassword

install_missing_plugins:
	- make --no-print-directory -f ./wg/Makefile install_missing_plugins

uninstall_missing_plugins:
	- make --no-print-directory -f ./wg/Makefile uninstall_missing_plugins

	