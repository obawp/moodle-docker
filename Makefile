include ./.env
export

# if has IOMAD env variable, add "-iomad" to REPO variable
# if has IOMAD=true set _iomad suffix to ${STACK} else _moodle
ifeq ($(IOMAD),true)
REPO := $(REPO)-iomad
STACK_SUFFIX := iomad
else
STACK_SUFFIX := moodle
endif
STACK_NAME := ${STACK}_${STACK_SUFFIX}
STACK_SRC := ./src/${STACK_NAME}
STACK_VOLUME_WEB := ${VOLUME_DIR_WEB}/${STACK_NAME}
STACK_VOLUME_DB := ${VOLUME_DIR_DB}/${STACK_NAME}
STACK_VOLUME_BKP := ${VOLUME_DIR_BKP}/${STACK_NAME}
STACK_VOLUME_COURSES := ${VOLUME_DIR_COURSES}/${STACK_NAME}

build:
	- docker build --build-arg IOMAD=${IOMAD} -t ${REPO}-${WEBSERVER} ./docker-files/moodle/${WEBSERVER}/

build_verbose:
	- docker build --build-arg IOMAD=${IOMAD} --progress=plain -t ${REPO}-${WEBSERVER} ./docker-files/moodle/${WEBSERVER}/

build_no_cache:
	- docker build --build-arg IOMAD=${IOMAD} --no-cache --pull -t ${REPO}-${WEBSERVER} ./docker-files/moodle/${WEBSERVER}/

login:
	- echo "${DOCKERHUB_PASS}" | docker login -u ${DOCKERHUB_USER} --password-stdin

push:
	- docker push ${REPO}-${WEBSERVER}

pull:
	- docker pull ${REPO}-${WEBSERVER}

run:
	- docker run -d --name ${STACK_NAME}_aux -e DOMAIN=${DOMAIN} ${REPO}-${WEBSERVER}

mkdir:
	- sudo mkdir -p ${STACK_VOLUME_WEB}/moodle/data
	- sudo mkdir -p ${STACK_VOLUME_WEB}/moodle/certbot/www
	- sudo mkdir -p ${STACK_VOLUME_WEB}/moodle/certbot/conf
	- make --no-print-directory mkdir_db

	- sudo chown $$USER:www-data ${STACK_VOLUME_WEB}/
	- sudo chown $$USER:www-data ${STACK_VOLUME_WEB}/moodle/
	- sudo chown $$USER:www-data ${STACK_VOLUME_WEB}/moodle/data

	- sudo chown $$USER:www-data ${STACK_VOLUME_DB}
	- sudo chown $$USER:www-data ${STACK_VOLUME_DB}/master
	- sudo chown $$USER:www-data ${STACK_VOLUME_DB}/slave
	- sudo chown $$USER:www-data ${STACK_VOLUME_DB}/phpunit
	- sudo chown $$USER:www-data ${STACK_VOLUME_DB}/master/${DBTYPE}/
	- sudo chown $$USER:www-data ${STACK_VOLUME_DB}/slave/${DBTYPE}/
	- sudo chown $$USER:www-data ${STACK_VOLUME_DB}/phpunit/${DBTYPE}/
	- sudo chown $$USER:www-data ${STACK_VOLUME_DB}/master/${DBTYPE}/data
	- sudo chown $$USER:www-data ${STACK_VOLUME_DB}/slave/${DBTYPE}/data
	- sudo chown $$USER:www-data ${STACK_VOLUME_DB}/phpunit/${DBTYPE}/data

	- sudo chown $$USER:www-data ./config/moodle/config.${DBTYPE}.php
	- sudo chmod 640 ./config/moodle/config.${DBTYPE}.php
	- sudo chmod +x ./config/db/**/**/custom-docker-entrypoint.sh

	- make --no-print-directory mkdir_certbot
	- make --no-print-directory cp_aux
	- make --no-print-directory phpu_mkdir

mkdir_db:
	- sudo mkdir -p ${STACK_VOLUME_DB}/master/${DBTYPE}/data
	- sudo mkdir -p ${STACK_VOLUME_DB}/slave/${DBTYPE}/data
	- sudo mkdir -p ${STACK_VOLUME_DB}/phpunit/${DBTYPE}/data

mkdir_db_slave:
	- sudo mkdir -p ${STACK_VOLUME_DB}/slave/${DBTYPE}/data


mkdir_certbot:
	- sudo mkdir -p ${STACK_VOLUME_WEB}/moodle/certbot/www/.well-known/acme-challenge/
	- sudo mkdir -p ${STACK_VOLUME_WEB}/moodle/certbot/conf
	- sudo chown $$USER:$$USER ${STACK_VOLUME_WEB}/moodle/certbot
	- sudo chmod 755 ${STACK_VOLUME_WEB}/moodle/certbot
	- sudo chown $$USER:$$USER ${STACK_VOLUME_WEB}/moodle/certbot/www
	- sudo chmod 755 ${STACK_VOLUME_WEB}/moodle/certbot/www
	- sudo chown $$USER:$$USER ${STACK_VOLUME_WEB}/moodle/certbot/conf
	- sudo chmod 755 ${STACK_VOLUME_WEB}/moodle/certbot/conf

cp_aux:
	@if docker ps -a --format '{{.Names}}' | grep -q "^${STACK_NAME}_aux$$"; then \
		sudo rm -Rf ${STACK_SRC}; \
		mkdir ./src; \
		sudo chown $$USER:$$USER ./src; \
		docker cp ${STACK_NAME}_aux:/var/www/html ${STACK_SRC}; \
	else \
		echo "Skipping src folder copy of the container ${STACK_NAME}_aux."; \
	fi

cp_certbot:
	docker cp ${STACK_NAME}_aux:/etc/letsencrypt ${STACK_VOLUME_WEB}/moodle/certbot/conf;
	sudo find ${STACK_VOLUME_WEB}/moodle/certbot/conf -type d -exec chmod 0700 {} \;
	sudo find ${STACK_VOLUME_WEB}/moodle/certbot/conf -type f -exec chmod 0600 {} \;
	sudo chown -R root:root ${STACK_VOLUME_WEB}/moodle/certbot/conf

rmdir:
	- make --no-print-directory rmdir_html
	- make --no-print-directory rmdir_moodledata
	- make --no-print-directory rmdir_db
	- make --no-print-directory rmdir_certbot
	- make --no-print-directory phpu_rmdir
	- make --no-print-directory rmdir_db_slave
	
rmdir_html:
	- sudo rm -Rf ${STACK_SRC}/

rmdir_moodledata:
	- sudo rm -Rf ${STACK_VOLUME_WEB}/moodle/data/

rmdir_db:
	- sudo rm -Rf ${STACK_VOLUME_DB}/master/${DBTYPE}/data/

rmdir_db_slave:
	- sudo rm -Rf ${STACK_VOLUME_DB}/slave/${DBTYPE}/data/

rmdir_certbot:
	- sudo rm -Rf ${STACK_VOLUME_WEB}/moodle/certbot/

pre_up:
	make --no-print-directory rm_web
	make --no-print-directory rm_pma
	if sudo test ! -d "${STACK_VOLUME_WEB}/moodle/certbot/conf/live/${DOMAIN}"; then \
		mkdir -p ${STACK_VOLUME_WEB}/moodle/certbot/conf/live/${DOMAIN}; \
		openssl req -x509 -newkey rsa:4096 -keyout ${STACK_VOLUME_WEB}/moodle/certbot/conf/live/${DOMAIN}/privkey.pem -out ${STACK_VOLUME_WEB}/moodle/certbot/conf/live/${DOMAIN}/fullchain.pem -sha256 -days 3650 -nodes -subj "/C=${CERT_COUNTRY}/ST=${CERT_STATE}/L=${CERT_CITY}/O=${CERT_ORG}/OU=${CERT_ORG_UNIT}/CN=${DOMAIN}"; \
	else \
		echo "Certificate exists. Skipping."; \
	fi

up:
	make --no-print-directory pre_up
	- docker compose -p ${STACK} --project-directory ./ -f "./docker-compose/docker-compose.${DBTYPE}.yml" up -d

up_force_recreate:
	make --no-print-directory pre_up
	- docker compose -p ${STACK} --project-directory ./ -f "./docker-compose/docker-compose.${DBTYPE}.yml" up --force-recreate -d

bash:
	- docker exec -it -u 0 -w /var/www/html ${STACK_NAME}_web bash

install:
	- docker exec -u www-data -w /var/www/html/admin/cli ${STACK_NAME}_web /usr/bin/php install_database.php --lang=en --adminuser=${MOODLE_ADMIN_USER} --adminpass=${MOODLE_ADMIN_PASSWORD} --adminemail=${MOODLE_ADMIN_EMAIL} --fullname=${MOODLE_SITE_FULLNAME} --shortname=${MOODLE_SITE_SHORTNAME}  --agree-license
	- docker cp ./docker-files/moodle/apache/.htaccess ${STACK_NAME}_web:/var/www/html 
	- docker exec -u 0 ${STACK_NAME}_web chown www-data:www-data -R /var/www/html/.htaccess
	- docker exec -u 0 ${STACK_NAME}_web chmod 640 /var/www/html/.htaccess

perm:
	- make --no-print-directory perm_html
	- make --no-print-directory perm_moodledata

perm_html:
	- docker exec -u 0 ${STACK_NAME}_web chown www-data:www-data -R /var/www/html/
	- sudo chown $$USER:www-data ./config/moodle/config.${DBTYPE}.php
	- sudo chmod 0640 ./config/moodle/config.${DBTYPE}.php
	- docker exec -u 0 ${STACK_NAME}_web find /var/www/html -type d -exec chmod 0750 {} \;
	- docker exec -u 0 ${STACK_NAME}_web find /var/www/html -type f -exec chmod 0640 {} \;
	- make --no-print-directory perm_php_ini

perm_moodledata:
	- docker exec -u 0 ${STACK_NAME}_web chown www-data:www-data -R /var/www/moodledata
	- docker exec -u 0 ${STACK_NAME}_web find /var/www/moodledata -type d -exec chmod 0770 {} \;
	- docker exec -u 0 ${STACK_NAME}_web find /var/www/moodledata -type f -exec chmod 0660 {} \;

perm_dev:
	- sudo chown $$USER:www-data -R ${STACK_SRC}
	- sudo chown $$USER:www-data ./config/moodle/config.${DBTYPE}.php
	- sudo chmod 0660 ./config/moodle/config.${DBTYPE}.php
	- sudo find ${STACK_SRC} -type d -exec chmod 0770 {} \;
	- sudo find ${STACK_SRC} -type f -exec chmod 0660 {} \;
	- sudo find ${STACK_VOLUME_WEB}/moodle/data -type d -exec chmod 0770 {} \;
	- sudo find ${STACK_VOLUME_WEB}/moodle/data -type f -exec chmod 0660 {} \;
	- make --no-print-directory perm_php_ini

perm_php_ini:
	- sudo find ${STACK_SRC} -type l -iname php.ini  -exec sudo chown $$USER:www-data {} \;

perm_dev_dir:
	- sudo chown $$USER:www-data -R ${STACK_SRC}/${WORK_DIR}
	- sudo find ${STACK_SRC}/${WORK_DIR} -type d -exec chmod 0770 {} \;
	- sudo find ${STACK_SRC}/${WORK_DIR} -type f -exec chmod 0660 {} \;

perm_db:
	- docker exec -u 0 ${STACK_NAME}_db chown -R mysql:mysql /var/lib/mysql

phpu_mkdir:
	- sudo mkdir -p ${STACK_VOLUME_WEB}/phpunit/moodle/data
	- sudo mkdir -p ${STACK_VOLUME_DB}/phpunit/${DBTYPE}/data
	- sudo chown $$USER:www-data ${STACK_VOLUME_WEB}/phpunit/

phpu_perm:
	- sudo chown -R $$USER:www-data ${STACK_VOLUME_WEB}/phpunit/moodle/data/
	- sudo chmod 0770 ${STACK_VOLUME_WEB}/phpunit/moodle/data/
	- sudo find ${STACK_VOLUME_WEB}/phpunit/moodle/data -type d -exec chmod 0770 {} \;
	- sudo find ${STACK_VOLUME_WEB}/phpunit/moodle/data -type f -exec chmod 0660 {} \;

phpu_install:
	-  docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web composer install
	-  docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/tool/phpunit/cli/init.php

phpu_rmdir:
	- sudo rm -Rf ${STACK_VOLUME_WEB}/phpunit/moodle/data/*
	- sudo rm -Rf ${STACK_VOLUME_DB}/phpunit/${DBTYPE}/data/*

rm_web:
	- docker rm ${STACK_NAME}_web -f

rm_pma:
	- docker rm ${STACK_NAME}_phpmyadmin -f
	- docker rm ${STACK_NAME}_phpunit_phpmyadmin -f

rm_aux:
	- docker rm ${STACK_NAME}_aux -f

rm:
	- make --no-print-directory rm_aux
	- docker compose -p ${STACK} -f "./docker-compose/docker-compose.${DBTYPE}.yml" down

purge_caches:
	-  docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/cli/purge_caches.php

purge_caches_manual:
	-  docker exec -u www-data -w /var/www/moodledata/ ${STACK_NAME}_web rm -rf localcache
	-  docker exec -u www-data -w /var/www/moodledata/ ${STACK_NAME}_web rm -rf cache
	-  docker exec -u www-data -w /var/www/moodledata/ ${STACK_NAME}_web rm -rf temp

upgrade:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/cli/upgrade.php

plugins_list:
	- docker exec -u 0 ${STACK_NAME}_db mariadb -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} -e "SELECT p.plugin FROM mdl_config_plugins p WHERE p.plugin NOT IN ( 'adminpresets', 'adminpresets', 'aiplacement_courseassist', 'aiplacement_editor', 'aiprovider_azureai', 'aiprovider_openai', 'analytics', 'antivirus', 'antivirus_clamav', 'areafiles', 'assign', 'assignfeedback_comments', 'assignfeedback_editpdf', 'assignfeedback_file', 'assignfeedback_offline', 'assignsubmission_comments', 'assignsubmission_file', 'assignsubmission_onlinetext', 'atto_accessibilitychecker', 'atto_accessibilityhelper', 'atto_align', 'atto_backcolor', 'atto_bold', 'atto_charmap', 'atto_clear', 'atto_collapse', 'atto_emojipicker', 'atto_emoticon', 'atto_equation', 'atto_fontcolor', 'atto_h5p', 'atto_html', 'atto_image', 'atto_indent', 'atto_italic', 'atto_link', 'atto_managefiles', 'atto_media', 'atto_noautolink', 'atto_orderedlist', 'atto_recordrtc', 'atto_rtl', 'atto_strike', 'atto_subscript', 'atto_superscript', 'atto_table', 'atto_title', 'atto_underline', 'atto_undo', 'atto_unorderedlist', 'auth_cas', 'auth_db', 'auth_email', 'auth_ldap', 'auth_lti', 'auth_manual', 'auth_mnet', 'auth_nologin', 'auth_none', 'auth_oauth2', 'auth_shibboleth', 'auth_webservice', 'availability_completion', 'availability_date', 'availability_grade', 'availability_group', 'availability_grouping', 'availability_profile', 'backup', 'block_accessreview', 'block_activity_modules', 'block_activity_results', 'block_admin_bookmarks', 'block_badges', 'block_blog_menu', 'block_blog_recent', 'block_blog_tags', 'block_calendar_month', 'block_calendar_upcoming', 'block_comments', 'block_completionstatus', 'block_course_list', 'block_course_summary', 'block_feedback', 'block_globalsearch', 'block_glossary_random', 'block_html', 'block_login', 'block_lp', 'block_mentees', 'block_mnet_hosts', 'block_myoverview', 'block_myprofile', 'block_navigation', 'block_news_items', 'block_online_users', 'block_private_files', 'block_recent_activity', 'block_recentlyaccessedcourses', 'block_recentlyaccesseditems', 'block_rss_client', 'block_search_forums', 'block_section_links', 'block_selfcompletion', 'block_settings', 'block_site_main_menu', 'block_social_activities', 'block_starredcourses', 'block_tag_flickr', 'block_tag_youtube', 'block_tags', 'block_timeline', 'book', 'booktool_exportimscp', 'booktool_importhtml', 'booktool_print', 'cachelock_file', 'cachestore_apcu', 'cachestore_file', 'cachestore_redis', 'cachestore_session', 'cachestore_static', 'calendartype_gregorian', 'communication_customlink', 'communication_matrix', 'contentbank', 'contenttype_h5p', 'core_admin', 'core_competency', 'core_h5p', 'customfield_checkbox', 'customfield_date', 'customfield_number', 'customfield_select', 'customfield_text', 'customfield_textarea', 'datafield_checkbox', 'datafield_date', 'datafield_file', 'datafield_latlong', 'datafield_menu', 'datafield_multimenu', 'datafield_number', 'datafield_picture', 'datafield_radiobutton', 'datafield_text', 'datafield_textarea', 'datafield_url', 'dataformat_csv', 'dataformat_excel', 'dataformat_html', 'dataformat_json', 'dataformat_ods', 'dataformat_pdf', 'datapreset_imagegallery', 'datapreset_journal', 'datapreset_proposals', 'datapreset_resources', 'editor_atto', 'editor_textarea', 'editor_tiny', 'enrol_category', 'enrol_cohort', 'enrol_database', 'enrol_fee', 'enrol_flatfile', 'enrol_guest', 'enrol_imsenterprise', 'enrol_ldap', 'enrol_lti', 'enrol_manual', 'enrol_meta', 'enrol_mnet', 'enrol_paypal', 'enrol_self', 'factor_admin', 'factor_auth', 'factor_capability', 'factor_cohort', 'factor_email', 'factor_grace', 'factor_iprange', 'factor_nosetup', 'factor_role', 'factor_sms', 'factor_token', 'factor_totp', 'factor_webauthn', 'fileconverter_googledrive', 'fileconverter_unoconv', 'filter_activitynames', 'filter_algebra', 'filter_codehighlighter', 'filter_data', 'filter_displayh5p', 'filter_emailprotect', 'filter_emoticon', 'filter_glossary', 'filter_mathjaxloader', 'filter_mediaplugin', 'filter_multilang', 'filter_tex', 'filter_urltolink', 'folder', 'format_singleactivity', 'format_social', 'format_topics', 'format_weeks', 'forumreport_summary', 'gradeexport_ods', 'gradeexport_txt', 'gradeexport_xls', 'gradeexport_xml', 'gradeimport_csv', 'gradeimport_direct', 'gradeimport_xml', 'gradereport_grader', 'gradereport_history', 'gradereport_outcomes', 'gradereport_overview', 'gradereport_singleview', 'gradereport_summary', 'gradereport_user', 'gradingform_guide', 'gradingform_rubric', 'h5plib_v127', 'imscp', 'label', 'local', 'logstore_database', 'logstore_standard', 'ltiservice_basicoutcomes', 'ltiservice_gradebookservices', 'ltiservice_memberships', 'ltiservice_profile', 'ltiservice_toolproxy', 'ltiservice_toolsettings', 'media_html5audio', 'media_html5video', 'media_videojs', 'media_vimeo', 'media_youtube', 'message', 'message_airnotifier', 'message_email', 'message_popup', 'mlbackend_php', 'mlbackend_python', 'mnetservice_enrol', 'mod_assign', 'mod_bigbluebuttonbn', 'mod_book', 'mod_chat', 'mod_choice', 'mod_data', 'mod_feedback', 'mod_folder', 'mod_forum', 'mod_glossary', 'mod_h5pactivity', 'mod_imscp', 'mod_label', 'mod_lesson', 'mod_lti', 'mod_page', 'mod_quiz', 'mod_resource', 'mod_scorm', 'mod_subsection', 'mod_survey', 'mod_url', 'mod_wiki', 'mod_workshop', 'moodlecourse', 'page', 'paygw_paypal', 'portfolio_download', 'portfolio_flickr', 'portfolio_googledocs', 'portfolio_mahara', 'profilefield_checkbox', 'profilefield_datetime', 'profilefield_menu', 'profilefield_social', 'profilefield_text', 'profilefield_textarea', 'qbank_bulkmove', 'qbank_columnsortorder', 'qbank_comment', 'qbank_customfields', 'qbank_deletequestion', 'qbank_editquestion', 'qbank_exportquestions', 'qbank_exporttoxml', 'qbank_history', 'qbank_importquestions', 'qbank_managecategories', 'qbank_previewquestion', 'qbank_statistics', 'qbank_tagquestion', 'qbank_usage', 'qbank_viewcreator', 'qbank_viewquestionname', 'qbank_viewquestiontext', 'qbank_viewquestiontype', 'qbehaviour_adaptive', 'qbehaviour_adaptivenopenalty', 'qbehaviour_deferredcbm', 'qbehaviour_deferredfeedback', 'qbehaviour_immediatecbm', 'qbehaviour_immediatefeedback', 'qbehaviour_informationitem', 'qbehaviour_interactive', 'qbehaviour_interactivecountback', 'qbehaviour_manualgraded', 'qbehaviour_missing', 'qformat_aiken', 'qformat_blackboard_six', 'qformat_gift', 'qformat_missingword', 'qformat_multianswer', 'qformat_xhtml', 'qformat_xml', 'qtype_calculated', 'qtype_calculatedmulti', 'qtype_calculatedsimple', 'qtype_ddimageortext', 'qtype_ddmarker', 'qtype_ddwtos', 'qtype_description', 'qtype_essay', 'qtype_gapselect', 'qtype_match', 'qtype_missingtype', 'qtype_multianswer', 'qtype_multichoice', 'qtype_numerical', 'qtype_ordering', 'qtype_random', 'qtype_randomsamatch', 'qtype_shortanswer', 'qtype_truefalse', 'question', 'question_preview', 'quiz', 'quiz_grading', 'quiz_overview', 'quiz_responses', 'quiz_statistics', 'quizaccess_delaybetweenattempts', 'quizaccess_ipaddress', 'quizaccess_numattempts', 'quizaccess_offlineattempts', 'quizaccess_openclosedate', 'quizaccess_password', 'quizaccess_seb', 'quizaccess_securewindow', 'quizaccess_timelimit', 'recent', 'report_backups', 'report_competency', 'report_completion', 'report_configlog', 'report_courseoverview', 'report_eventlist', 'report_infectedfiles', 'report_insights', 'report_log', 'report_loglive', 'report_outline', 'report_participation', 'report_performance', 'report_progress', 'report_questioninstances', 'report_security', 'report_stats', 'report_status', 'report_themeusage', 'report_usersessions', 'repository_areafiles', 'repository_contentbank', 'repository_coursefiles', 'repository_dropbox', 'repository_equella', 'repository_filesystem', 'repository_flickr', 'repository_flickr_public', 'repository_googledocs', 'repository_local', 'repository_merlot', 'repository_nextcloud', 'repository_onedrive', 'repository_recent', 'repository_s3', 'repository_upload', 'repository_url', 'repository_user', 'repository_webdav', 'repository_wikimedia', 'repository_youtube', 'resource', 'restore', 'scorm', 'scormreport_basic', 'scormreport_graphs', 'scormreport_interactions', 'scormreport_objectives', 'search_simpledb', 'search_solr', 'smsgateway_aws', 'theme_boost', 'theme_classic', 'tiny_accessibilitychecker', 'tiny_aiplacement', 'tiny_autosave', 'tiny_equation', 'tiny_h5p', 'tiny_html', 'tiny_link', 'tiny_media', 'tiny_noautolink', 'tiny_premium', 'tiny_recordrtc', 'tool_admin_presets', 'tool_analytics', 'tool_availabilityconditions', 'tool_behat', 'tool_brickfield', 'tool_capability', 'tool_cohortroles', 'tool_componentlibrary', 'tool_customlang', 'tool_dataprivacy', 'tool_dbtransfer', 'tool_filetypes', 'tool_generator', 'tool_httpsreplace', 'tool_installaddon', 'tool_langimport', 'tool_licensemanager', 'tool_log', 'tool_lp', 'tool_lpimportcsv', 'tool_lpmigrate', 'tool_messageinbound', 'tool_mfa', 'tool_mobile', 'tool_monitor', 'tool_moodlenet', 'tool_multilangupgrade', 'tool_oauth2', 'tool_phpunit', 'tool_policy', 'tool_profiling', 'tool_recyclebin', 'tool_replace', 'tool_spamcleaner', 'tool_task', 'tool_templatelibrary', 'tool_unsuproles', 'tool_uploadcourse', 'tool_uploaduser', 'tool_usertours', 'tool_xmldb', 'upload', 'url', 'user', 'webservice_rest', 'webservice_soap', 'wikimedia', 'workshop', 'workshopallocation_manual', 'workshopallocation_random', 'workshopallocation_scheduled', 'workshopeval_best', 'workshopform_accumulative', 'workshopform_comments', 'workshopform_numerrors', 'workshopform_rubric'  ) GROUP BY p.plugin ORDER BY p.plugin"

clear_restores_in_progress_list:
	- docker exec -u 0 ${STACK_NAME}_db mariadb -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} -e "DELETE FROM mdl_backup_controllers WHERE interactive = 1;"

bkp_ls_courses_restore:
	- ls ${STACK_VOLUME_COURSES}
	
bkp_courses_restore:
	docker exec -it -u 0 -w / ${STACK_NAME}_web mkdir -p /var/www/backup/courses
	docker exec -it -u 0 -w / ${STACK_NAME}_web chown root:www-data /var/www/backup
	docker  cp ${STACK_VOLUME_COURSES} ${STACK_NAME}_web:/var/www/backup
	ls ${STACK_VOLUME_COURSES} | while IFS= read -r course; do docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web bash -c "echo "$$course"; /usr/bin/php admin/cli/restore_backup.php --file=/var/www/backup/courses/$$course --categoryid=1 & wait;"; done

plugins_purge_missing_dry:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/cli/uninstall_plugins.php --purge-missing

# Example: make plugins=mod_assign,mod_forum plugins_uninstall_dry
plugins_uninstall_dry:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/cli/uninstall_plugins.php  --plugins=$(plugins)

plugins_purge_missing:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/cli/uninstall_plugins.php --purge-missing --run

# Usage: make plugins=mod_assign,mod_forum plugins_install
plugins_install:
	@echo "$(plugins)" | tr ',' '\n' | while read -r plugin; do \
		docker exec -u www-data -w /var/www/html/ $${STACK_NAME}_web bash -c "moosh -v plugin-install $$plugin"; \
	done

# Usage: make plugins=mod_assign,mod_forum plugins_uninstall
plugins_uninstall:
	@echo "$(plugins)" | tr ',' '\n' | while read -r plugin; do \
		docker exec -u www-data -w /var/www/html/ $${STACK_NAME}_web bash -c "moosh plugin-uninstall $$plugin"; \
	done
	@docker exec -u www-data -w /var/www/html/ $${STACK_NAME}_web /usr/bin/php admin/cli/uninstall_plugins.php --plugins="$(plugins)" --run

# Usage: make courses=123,234,456 courses_install
courses_install:
	- docker exec -u 0 -w /var/www/html/ ${STACK_NAME}_web mkdir /var/www/courses_backup
	- docker exec -u 0 -w /var/www/html/ ${STACK_NAME}_web chown www-data:www-data /var/www/courses_backup
	- docker exec -u 0 -w /var/www/html/ ${STACK_NAME}_web chmod 750 /var/www/courses_backup
	@echo "$(courses)" | tr ',' '\n' | while read -r course; do \
		docker exec -u 0 -w /var/www/html/ $${STACK_NAME}_web bash -c "sudo -u www-data moosh course-backup --template -f /var/www/courses_backup/demo_data/backup_$$course.mbz $$course"; \
	done
	docker cp "${STACK_NAME}_web:/var/www/courses_backup/." ${STACK_VOLUME_COURSES}
	docker exec -u 0 -w /var/www/html/ ${STACK_NAME}_web rm -rf /var/www/courses_backup

courses_mkdir:
	- sudo mkdir -p ${STACK_VOLUME_COURSES}
	- sudo chown $$USER:www-data -R ${STACK_VOLUME_COURSES}
	- sudo chmod 0750 ${STACK_VOLUME_COURSES}
	- sudo chmod 0640 ${STACK_VOLUME_COURSES}/*.mbz

checks:
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web php admin/cli/checks.php

task_list:
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web php admin/cli/scheduled_task.php --list;

# Example: make task='core\task\cron_task' task_run
task_exec:
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web php admin/cli/scheduled_task.php --showdebugging --execute='$(task)';

cron_run:
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web php admin/cli/cron.php


bkp_mkdir:
	- sudo mkdir -p ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/html
	- sudo mkdir -p ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/moodledata

bkp_perm:
	- sudo chown $$USER:www-data ${STACK_VOLUME_WEB}/
	- sudo chown $$USER:www-data ${STACK_VOLUME_BKP}/
	- sudo chown $$USER:www-data -R ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}


bkp_plugins_list:
	- cat ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/plugins-list.txt

bkp_plugins_list_save:
	- @docker exec -u 0 ${STACK_NAME}_db mariadb -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} -e "SELECT p.plugin FROM mdl_config_plugins p WHERE p.plugin NOT IN ( 'adminpresets', 'adminpresets', 'aiplacement_courseassist', 'aiplacement_editor', 'aiprovider_azureai', 'aiprovider_openai', 'analytics', 'antivirus', 'antivirus_clamav', 'areafiles', 'assign', 'assignfeedback_comments', 'assignfeedback_editpdf', 'assignfeedback_file', 'assignfeedback_offline', 'assignsubmission_comments', 'assignsubmission_file', 'assignsubmission_onlinetext', 'atto_accessibilitychecker', 'atto_accessibilityhelper', 'atto_align', 'atto_backcolor', 'atto_bold', 'atto_charmap', 'atto_clear', 'atto_collapse', 'atto_emojipicker', 'atto_emoticon', 'atto_equation', 'atto_fontcolor', 'atto_h5p', 'atto_html', 'atto_image', 'atto_indent', 'atto_italic', 'atto_link', 'atto_managefiles', 'atto_media', 'atto_noautolink', 'atto_orderedlist', 'atto_recordrtc', 'atto_rtl', 'atto_strike', 'atto_subscript', 'atto_superscript', 'atto_table', 'atto_title', 'atto_underline', 'atto_undo', 'atto_unorderedlist', 'auth_cas', 'auth_db', 'auth_email', 'auth_ldap', 'auth_lti', 'auth_manual', 'auth_mnet', 'auth_nologin', 'auth_none', 'auth_oauth2', 'auth_shibboleth', 'auth_webservice', 'availability_completion', 'availability_date', 'availability_grade', 'availability_group', 'availability_grouping', 'availability_profile', 'backup', 'block_accessreview', 'block_activity_modules', 'block_activity_results', 'block_admin_bookmarks', 'block_badges', 'block_blog_menu', 'block_blog_recent', 'block_blog_tags', 'block_calendar_month', 'block_calendar_upcoming', 'block_comments', 'block_completionstatus', 'block_course_list', 'block_course_summary', 'block_feedback', 'block_globalsearch', 'block_glossary_random', 'block_html', 'block_login', 'block_lp', 'block_mentees', 'block_mnet_hosts', 'block_myoverview', 'block_myprofile', 'block_navigation', 'block_news_items', 'block_online_users', 'block_private_files', 'block_recent_activity', 'block_recentlyaccessedcourses', 'block_recentlyaccesseditems', 'block_rss_client', 'block_search_forums', 'block_section_links', 'block_selfcompletion', 'block_settings', 'block_site_main_menu', 'block_social_activities', 'block_starredcourses', 'block_tag_flickr', 'block_tag_youtube', 'block_tags', 'block_timeline', 'book', 'booktool_exportimscp', 'booktool_importhtml', 'booktool_print', 'cachelock_file', 'cachestore_apcu', 'cachestore_file', 'cachestore_redis', 'cachestore_session', 'cachestore_static', 'calendartype_gregorian', 'communication_customlink', 'communication_matrix', 'contentbank', 'contenttype_h5p', 'core_admin', 'core_competency', 'core_h5p', 'customfield_checkbox', 'customfield_date', 'customfield_number', 'customfield_select', 'customfield_text', 'customfield_textarea', 'datafield_checkbox', 'datafield_date', 'datafield_file', 'datafield_latlong', 'datafield_menu', 'datafield_multimenu', 'datafield_number', 'datafield_picture', 'datafield_radiobutton', 'datafield_text', 'datafield_textarea', 'datafield_url', 'dataformat_csv', 'dataformat_excel', 'dataformat_html', 'dataformat_json', 'dataformat_ods', 'dataformat_pdf', 'datapreset_imagegallery', 'datapreset_journal', 'datapreset_proposals', 'datapreset_resources', 'editor_atto', 'editor_textarea', 'editor_tiny', 'enrol_category', 'enrol_cohort', 'enrol_database', 'enrol_fee', 'enrol_flatfile', 'enrol_guest', 'enrol_imsenterprise', 'enrol_ldap', 'enrol_lti', 'enrol_manual', 'enrol_meta', 'enrol_mnet', 'enrol_paypal', 'enrol_self', 'factor_admin', 'factor_auth', 'factor_capability', 'factor_cohort', 'factor_email', 'factor_grace', 'factor_iprange', 'factor_nosetup', 'factor_role', 'factor_sms', 'factor_token', 'factor_totp', 'factor_webauthn', 'fileconverter_googledrive', 'fileconverter_unoconv', 'filter_activitynames', 'filter_algebra', 'filter_codehighlighter', 'filter_data', 'filter_displayh5p', 'filter_emailprotect', 'filter_emoticon', 'filter_glossary', 'filter_mathjaxloader', 'filter_mediaplugin', 'filter_multilang', 'filter_tex', 'filter_urltolink', 'folder', 'format_singleactivity', 'format_social', 'format_topics', 'format_weeks', 'forumreport_summary', 'gradeexport_ods', 'gradeexport_txt', 'gradeexport_xls', 'gradeexport_xml', 'gradeimport_csv', 'gradeimport_direct', 'gradeimport_xml', 'gradereport_grader', 'gradereport_history', 'gradereport_outcomes', 'gradereport_overview', 'gradereport_singleview', 'gradereport_summary', 'gradereport_user', 'gradingform_guide', 'gradingform_rubric', 'h5plib_v127', 'imscp', 'label', 'local', 'logstore_database', 'logstore_standard', 'ltiservice_basicoutcomes', 'ltiservice_gradebookservices', 'ltiservice_memberships', 'ltiservice_profile', 'ltiservice_toolproxy', 'ltiservice_toolsettings', 'media_html5audio', 'media_html5video', 'media_videojs', 'media_vimeo', 'media_youtube', 'message', 'message_airnotifier', 'message_email', 'message_popup', 'mlbackend_php', 'mlbackend_python', 'mnetservice_enrol', 'mod_assign', 'mod_bigbluebuttonbn', 'mod_book', 'mod_chat', 'mod_choice', 'mod_data', 'mod_feedback', 'mod_folder', 'mod_forum', 'mod_glossary', 'mod_h5pactivity', 'mod_imscp', 'mod_label', 'mod_lesson', 'mod_lti', 'mod_page', 'mod_quiz', 'mod_resource', 'mod_scorm', 'mod_subsection', 'mod_survey', 'mod_url', 'mod_wiki', 'mod_workshop', 'moodlecourse', 'page', 'paygw_paypal', 'portfolio_download', 'portfolio_flickr', 'portfolio_googledocs', 'portfolio_mahara', 'profilefield_checkbox', 'profilefield_datetime', 'profilefield_menu', 'profilefield_social', 'profilefield_text', 'profilefield_textarea', 'qbank_bulkmove', 'qbank_columnsortorder', 'qbank_comment', 'qbank_customfields', 'qbank_deletequestion', 'qbank_editquestion', 'qbank_exportquestions', 'qbank_exporttoxml', 'qbank_history', 'qbank_importquestions', 'qbank_managecategories', 'qbank_previewquestion', 'qbank_statistics', 'qbank_tagquestion', 'qbank_usage', 'qbank_viewcreator', 'qbank_viewquestionname', 'qbank_viewquestiontext', 'qbank_viewquestiontype', 'qbehaviour_adaptive', 'qbehaviour_adaptivenopenalty', 'qbehaviour_deferredcbm', 'qbehaviour_deferredfeedback', 'qbehaviour_immediatecbm', 'qbehaviour_immediatefeedback', 'qbehaviour_informationitem', 'qbehaviour_interactive', 'qbehaviour_interactivecountback', 'qbehaviour_manualgraded', 'qbehaviour_missing', 'qformat_aiken', 'qformat_blackboard_six', 'qformat_gift', 'qformat_missingword', 'qformat_multianswer', 'qformat_xhtml', 'qformat_xml', 'qtype_calculated', 'qtype_calculatedmulti', 'qtype_calculatedsimple', 'qtype_ddimageortext', 'qtype_ddmarker', 'qtype_ddwtos', 'qtype_description', 'qtype_essay', 'qtype_gapselect', 'qtype_match', 'qtype_missingtype', 'qtype_multianswer', 'qtype_multichoice', 'qtype_numerical', 'qtype_ordering', 'qtype_random', 'qtype_randomsamatch', 'qtype_shortanswer', 'qtype_truefalse', 'question', 'question_preview', 'quiz', 'quiz_grading', 'quiz_overview', 'quiz_responses', 'quiz_statistics', 'quizaccess_delaybetweenattempts', 'quizaccess_ipaddress', 'quizaccess_numattempts', 'quizaccess_offlineattempts', 'quizaccess_openclosedate', 'quizaccess_password', 'quizaccess_seb', 'quizaccess_securewindow', 'quizaccess_timelimit', 'recent', 'report_backups', 'report_competency', 'report_completion', 'report_configlog', 'report_courseoverview', 'report_eventlist', 'report_infectedfiles', 'report_insights', 'report_log', 'report_loglive', 'report_outline', 'report_participation', 'report_performance', 'report_progress', 'report_questioninstances', 'report_security', 'report_stats', 'report_status', 'report_themeusage', 'report_usersessions', 'repository_areafiles', 'repository_contentbank', 'repository_coursefiles', 'repository_dropbox', 'repository_equella', 'repository_filesystem', 'repository_flickr', 'repository_flickr_public', 'repository_googledocs', 'repository_local', 'repository_merlot', 'repository_nextcloud', 'repository_onedrive', 'repository_recent', 'repository_s3', 'repository_upload', 'repository_url', 'repository_user', 'repository_webdav', 'repository_wikimedia', 'repository_youtube', 'resource', 'restore', 'scorm', 'scormreport_basic', 'scormreport_graphs', 'scormreport_interactions', 'scormreport_objectives', 'search_simpledb', 'search_solr', 'smsgateway_aws', 'theme_boost', 'theme_classic', 'tiny_accessibilitychecker', 'tiny_aiplacement', 'tiny_autosave', 'tiny_equation', 'tiny_h5p', 'tiny_html', 'tiny_link', 'tiny_media', 'tiny_noautolink', 'tiny_premium', 'tiny_recordrtc', 'tool_admin_presets', 'tool_analytics', 'tool_availabilityconditions', 'tool_behat', 'tool_brickfield', 'tool_capability', 'tool_cohortroles', 'tool_componentlibrary', 'tool_customlang', 'tool_dataprivacy', 'tool_dbtransfer', 'tool_filetypes', 'tool_generator', 'tool_httpsreplace', 'tool_installaddon', 'tool_langimport', 'tool_licensemanager', 'tool_log', 'tool_lp', 'tool_lpimportcsv', 'tool_lpmigrate', 'tool_messageinbound', 'tool_mfa', 'tool_mobile', 'tool_monitor', 'tool_moodlenet', 'tool_multilangupgrade', 'tool_oauth2', 'tool_phpunit', 'tool_policy', 'tool_profiling', 'tool_recyclebin', 'tool_replace', 'tool_spamcleaner', 'tool_task', 'tool_templatelibrary', 'tool_unsuproles', 'tool_uploadcourse', 'tool_uploaduser', 'tool_usertours', 'tool_xmldb', 'upload', 'url', 'user', 'webservice_rest', 'webservice_soap', 'wikimedia', 'workshop', 'workshopallocation_manual', 'workshopallocation_random', 'workshopallocation_scheduled', 'workshopeval_best', 'workshopform_accumulative', 'workshopform_comments', 'workshopform_numerrors', 'workshopform_rubric'  ) GROUP BY p.plugin ORDER BY p.plugin"  > ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/plugins-list.txt

bkp_plugins_install:
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web bash -c "moosh plugin-list";
	- while IFS= read -r plugin; do docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web bash -c "moosh plugin-install $$plugin"; done < ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/plugins-list.txt

bkp_plugins_uninstall:
	- while IFS= read -r plugin; do docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web bash -c "moosh plugin-uninstall $$plugin"; done < ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/plugins-list.txt


bkp_tar:
	- rm -f ${STACK_VOLUME_BKP}/compressed/${CURRENT_BACKUP_DIR}.tgz
	- find ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR} -printf "%P\n" | tar -czf ${STACK_VOLUME_BKP}/compressed/${CURRENT_BACKUP_DIR}.tgz --no-recursion -C ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR} -T -

bkp_untar:
	- tar -xzf ${STACK_VOLUME_BKP}/compressed/${CURRENT_BACKUP_DIR}.tgz -C ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}


## CAREFUL: this will remove all backup files
bkp_dump:
	make --no-print-directory bkp_rmdir
	make --no-print-directory bkp_rm_tgz
	make --no-print-directory bkp_mkdir
	make --no-print-directory bkp_perm
	- make --no-print-directory bkp_dump_html
	- make --no-print-directory bkp_dump_moodledata
	- make --no-print-directory bkp_dump_${DBTYPE}
	make --no-print-directory bkp_plugins_list_save
	make --no-print-directory bkp_tar

bkp_dump_html:
	- rm -Rf ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/html
	- docker cp ${STACK_NAME}_web:/var/www/html ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/html

bkp_dump_moodledata:
	- rm -Rf ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/moodledata
	- docker cp ${STACK_NAME}_web:/var/www/moodledata ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/moodledata

bkp_dump_mariadb:
	- docker exec -u 0 ${STACK_NAME}_db mariadb-dump -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} > ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/data.sql

# ini - this section needs be tested
bkp_dump_mysql:
	- docker exec -u 0 ${STACK_NAME}_db mysqldump -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/data.sql

bkp_dump_pgsql:
	- docker exec -u 0 ${STACK_NAME}_db bash -c "PGPASSWORD=${POSTGRES_PASSWORD} pg_dump -U ${POSTGRES_USER} -d ${POSTGRES_DB} -F c -f /backup/data.sql"
	- docker cp ${STACK_NAME}_db:/backup/data.sql ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/data.sql
# end - this section needs be tested


## CAREFUL: this will remove all the current installation files
bkp_restore:
	sudo echo "allowing sudo commands not to block the process after"
	make --no-print-directory bkp_restore_body
	make --no-print-directory up
	make --no-print-directory perm
# db needs be the last because the slow server socket connection
	make --no-print-directory bkp_restore_${DBTYPE}

bkp_restore_dev:
	make --no-print-directory bkp_restore_body
	make --no-print-directory up
	make --no-print-directory perm_dev
# db needs be the last because the slow server socket connection
	make --no-print-directory bkp_restore_${DBTYPE}

bkp_restore_body:
	make --no-print-directory rm
	make --no-print-directory mkdir
	make --no-print-directory bkp_mkdir
	make --no-print-directory bkp_perm
	- make --no-print-directory bkp_untar
	make --no-print-directory bkp_restore_html
	make --no-print-directory bkp_restore_moodledata

bkp_restore_html:
	- sudo rsync -a --delete "${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/html/." ${STACK_SRC}/
	make --no-print-directory perm_html

bkp_restore_moodledata:
	- sudo rsync -a --delete "${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/moodledata/." ${STACK_VOLUME_WEB}/moodle/data/
	make --no-print-directory perm_moodledata

bkp_restore_mariadb:
	make --no-print-directory rm
	sleep 1
	make --no-print-directory rmdir_db
	make --no-print-directory mkdir_db
	sleep 1
	make --no-print-directory up

	sleep 35
	make --no-print-directory bkp_restore_mariadb_import

bkp_restore_mariadb_import:
	docker exec -u 0 ${STACK_NAME}_db mkdir -p /backup
	docker cp ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/data.sql ${STACK_NAME}_db:/backup/data.sql

	docker exec -u 0 ${STACK_NAME}_db chown root:root -R /backup
	docker exec -u 0 ${STACK_NAME}_db chmod 640 -R /backup
	sleep 1
	docker exec -u 0 ${STACK_NAME}_db sed 's/\sDEFINER=`[^`]*`@`[^`]*`//g' -i /backup/data.sql
	docker exec -u 0 ${STACK_NAME}_db bash -c "mariadb -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} < /backup/data.sql";
	docker exec -u 0 ${STACK_NAME}_db mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "USE moodle;DELETE FROM mdl_logstore_standard_log WHERE timecreated < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 180 DAY));"
	docker exec -u 0 ${STACK_NAME}_db bash -c "rm /backup/data.sql";

# ini - this section needs be tested
bkp_restore_mysql:
	make --no-print-directory rm
	make --no-print-directory rmdir_db
	make --no-print-directory up
	docker exec -u 0 ${STACK_NAME}_db mkdir -p /backup
	docker cp ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/data.sql ${STACK_NAME}_db:/backup/data.sql
	docker exec -u 0 ${STACK_NAME}_db chown root:root -R /backup
	docker exec -u 0 ${STACK_NAME}_db chmod 640 -R /backup
	sleep 1
	docker exec -u 0 ${STACK_NAME}_db bash -c "mysql -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} < /backup/data.sql"
	- docker exec -u 0 ${STACK_NAME}_db bash -c "rm /backup/data.sql"

bkp_restore_pgsql:
	make --no-print-directory rm
	make --no-print-directory rmdir_db
	make --no-print-directory up
	- docker cp ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/data.sql ${STACK_NAME}_db:/backup/data.sql
	- docker exec -u 0 ${STACK_NAME}_db bash -c "PGPASSWORD=${POSTGRES_PASSWORD} pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DB} --clean /backup/data.sql"
# end - this section needs be tested


bkp_rmdir:
	- sudo rm -Rf ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}

bkp_rm_tgz:
	- sudo rm -Rf ${STACK_VOLUME_BKP}/compressed/${CURRENT_BACKUP_DIR}.tgz


remote_bkp_to_tgz:
	- sudo scp -P ${TO_SSH_PORT} ${STACK_VOLUME_BKP}/compressed/${CURRENT_BACKUP_DIR}.tgz ${TO_SSH_USER}@${TO_SSH_HOST}:${TO_SSH_TGZ_DIR}

remote_bkp_from_tgz:
	- sudo scp -P ${FROM_SSH_PORT} ${FROM_SSH_USER}@${FROM_SSH_HOST}:${FROM_SSH_TGZ_PATH} ${STACK_VOLUME_BKP}/

remote_bkp_from_requirements:
	@make --no-print-directory bkp_mkdir
	@make --no-print-directory bkp_perm

remote_bkp_from_flow:
	@make --no-print-directory remote_bkp_from_requirements
	make --no-print-directory remote_bkp_from_html
	make --no-print-directory remote_bkp_from_moodledata
	@if [ "$(FROM_DB_EXTERNAL_PORT)" = "true" ]; then \
		make --no-print-directory remote_bkp_from_mariadb_external_port; \
	else \
		make --no-print-directory remote_bkp_from_mariadb_ssh; \
	fi

remote_bkp_from_html:
	@make --no-print-directory remote_bkp_from_requirements
	- sudo rsync -avz --delete --progress -e "ssh -p ${FROM_SSH_PORT}" "${FROM_SSH_USER}@${FROM_SSH_HOST}:${FROM_SSH_DIR_HTML}/" ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/html/

remote_bkp_from_moodledata:
	@make --no-print-directory remote_bkp_from_requirements
	- sudo rsync -avz --delete --progress -e "ssh -p ${FROM_SSH_PORT}" "${FROM_SSH_USER}@${FROM_SSH_HOST}:${FROM_SSH_DIR_MOODLEDATA}/" ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/moodledata/

remote_bkp_from_mariadb_external_port:
	@make --no-print-directory remote_bkp_from_requirements
	mysqldump -P ${FROM_DB_MARIADB_PORT} -h ${FROM_DB_MARIADB_HOST} -u${FROM_DB_MARIADB_USER} -p${FROM_DB_MARIADB_PASSWORD} \
	${FROM_DB_MARIADB_DATABASE} > ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/data.sql

remote_bkp_from_mariadb_ssh:
	ssh -p "${FROM_DB_SSH_PORT}" "${FROM_DB_SSH_USER}@${FROM_DB_SSH_HOST}" \
	"mysqldump -P ${FROM_DB_SSH_MARIADB_PORT} --protocol=socket --no-tablespaces -u${FROM_DB_SSH_MARIADB_USER} -p${FROM_DB_SSH_MARIADB_PASSWORD} ${FROM_DB_SSH_MARIADB_DATABASE}" > ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/data.sql
# 	scp -P ${FROM_DB_SSH_PORT} ${FROM_DB_SSH_USER}@${FROM_DB_SSH_HOST}:${FROM_DB_SSH_MARIADB_DATABASE_TEMP_FOLDER}/data.sql ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/data.sql
# 	ssh -p ${FROM_DB_SSH_PORT} ${FROM_DB_SSH_USER}@${FROM_DB_SSH_HOST} "rm ${FROM_DB_SSH_MARIADB_DATABASE_TEMP_FOLDER}/data.sql"

# the url_replace command are for migration from http to https
url_replace_list:
	- docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/tool/httpsreplace/cli/url_replace.php -l

# Do not use confirm on impulse. Give preference to Search and Replace if you have unknown URLs in the listing
url_replace_confirm:
	- docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/tool/httpsreplace/cli/url_replace.php -r --confirm

url_replace_help:
	- docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/tool/httpsreplace/cli/url_replace.php -h


# Example: make search=http://moodle.local replace=http://moodle.prod search_replace
search_replace:
	- docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/tool/replace/cli/replace.php --search=$(search) --replace=$(replace) --shorten --non-interactive


certbot_list:
	- docker exec -it ${STACK_NAME}_certbot certbot certificates

certbot_init_dry:
	- docker exec -it ${STACK_NAME}_certbot certbot certonly --dry-run --webroot --cert-name ${DOMAIN} -w /var/www/certbot  --email ${CERT_EMAIL} -d ${DOMAIN} --rsa-key-size 4096 --agree-tos --force-renewal --debug-challenges -v

# certbot_perm:
# 	- docker exec -u 0 ${STACK_NAME}_web chown -R www-data:www-data /var/www/certbot
# 	- docker exec -u 0 ${STACK_NAME}_web find /var/www/certbot -type d -exec chmod 0750 {} \;
# 	- docker exec -u 0 ${STACK_NAME}_web find /var/www/certbot -type f -exec chmod 0640 {} \;

# certbot_init:
# 	- docker exec -it ${STACK_NAME}_certbot certbot delete --cert-name ${DOMAIN} --non-interactive --quiet
# 	( sleep 3; make --no-print-directory certbot_perm; echo "\n"; ) & \
# 	make --no-print-directory certbot_init_dry 
# 	- make --no-print-directory rm
# 	- make --no-print-directory up

certbot_delete:
	- docker exec -it ${STACK_NAME}_certbot certbot delete --cert-name ${DOMAIN} --non-interactive --quiet

certbot_init:
	- make --no-print-directory certbot_delete
	- docker exec -u 0 ${STACK_NAME}_certbot rm -rf /etc/letsencrypt/live/${DOMAIN}
	- docker exec -u 0 ${STACK_NAME}_certbot rm -rf /etc/letsencrypt/archive/${DOMAIN}
	- docker exec -u 0 ${STACK_NAME}_certbot rm -rf /etc/letsencrypt/renewal/${DOMAIN}.conf
	docker exec -it ${STACK_NAME}_certbot certbot certonly --webroot --cert-name ${DOMAIN} -w /var/www/certbot  --email ${CERT_EMAIL} -d ${DOMAIN} --rsa-key-size 4096 --agree-tos --force-renewal --debug-challenges -v
	- make --no-print-directory certbot_bkp
	- make --no-print-directory rm
	- make --no-print-directory up

certbot_bkp:
	- mkdir -p ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/certbot/live/${DOMAIN}
	- mkdir -p ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/certbot/archive/${DOMAIN}
	- mkdir -p ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/certbot/renewal/
	- docker cp ${STACK_NAME}_certbot:/etc/letsencrypt/live/${DOMAIN} ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/certbot/live/${DOMAIN}
	- docker cp ${STACK_NAME}_certbot:/etc/letsencrypt/archive/${DOMAIN} ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/certbot/archive/${DOMAIN}
	- docker cp ${STACK_NAME}_certbot:/etc/letsencrypt/renewal/${DOMAIN}.conf ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/certbot/renewal/${DOMAIN}.conf
	
maintenance_on:
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web php admin/cli/maintenance.php --enable

maintenance_off:
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web php admin/cli/maintenance.php --disable


# Careful: this will remove all plugins and core changes
git_clean_all:
	docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web git clean -d -fx -e config.php .

update:
	make --no-print-directory maintenance_on
	# Allow Git operations inside the container
	- docker exec -u 0 -w /var/www/html/ ${STACK_NAME}_web git config --global --add safe.directory /var/www/html

	# Stash uncommitted changes, including untracked files
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web git stash push --include-untracked --message "pre-update stash"

	# Perform Git update steps
	docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web git remote update
	docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web git checkout admin/tool/uploaduser/classes/process.php
	docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web git checkout MOODLE_405_STABLE
	docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web git pull

	# Re-apply and drop the stash if it exists
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web sh -c "\
		git stash list | grep 'pre-update stash' && \
		git stash apply stash@{0} && \
		git stash drop stash@{0} || true"

	make --no-print-directory perm_html
	make --no-print-directory upgrade
	make --no-print-directory purge_caches
	make --no-print-directory maintenance_off


mariadb_rebuild_slave:
	make --no-print-directory bkp_mkdir
	make --no-print-directory bkp_perm
	make --no-print-directory maintenance_on
	docker exec -u 0 ${STACK_NAME}_db mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "GRANT RELOAD ON *.* TO '${MARIADB_USER}'@'%'; FLUSH PRIVILEGES;"
	docker exec -u 0 ${STACK_NAME}_db mysqldump --all-databases --single-transaction --master-data=2 --flush-logs --hex-blob --triggers --routines --events -u${MARIADB_USER} -p${MARIADB_PASSWORD} > ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/dump-rebuild-slave.sql
	docker cp ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/dump-rebuild-slave.sql ${STACK_NAME}_db_slave:/dump-rebuild-slave.sql
	rm -f ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/dump-rebuild-slave.sql
	docker exec -u 0 ${STACK_NAME}_db_slave mysql -u root -p${MARIADB_ROOT_PASSWORD} -e "DROP DATABASE IF EXISTS ${MARIADB_DATABASE};"
	docker exec -u 0 ${STACK_NAME}_db_slave bash -c "mysql -u root -p${MARIADB_ROOT_PASSWORD} < /dump-rebuild-slave.sql"
	docker exec -u 0 ${STACK_NAME}_db_slave rm -f /dump-rebuild-slave.sql
	make  --no-print-directory  mariadb_slave_config
	make --no-print-directory maintenance_off

mariadb_slave_config:
	$(eval MASTER_STATUS := $(shell docker exec -u 0 ${STACK_NAME}_db mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "SHOW MASTER STATUS\G"))
	echo $$MASTER_STATUS;
	$(eval MASTER_LOG_FILE := $(shell echo '$(MASTER_STATUS)'   | grep -oP 'File: \K[^ ]+'))
	echo $$MASTER_LOG_FILE;
	$(eval MASTER_LOG_POS := $(shell echo '$(MASTER_STATUS)' | grep -oP 'Position: \K[0-9]+'))
	echo $$MASTER_LOG_POS;
	docker exec -u 0 ${STACK_NAME}_db_slave mysql -u root -p${MARIADB_ROOT_PASSWORD} -e "STOP SLAVE; RESET SLAVE ALL; \
	CHANGE MASTER TO MASTER_HOST='db', MASTER_USER='${MARIADB_USER}', MASTER_PASSWORD='${MARIADB_PASSWORD}', \
	MASTER_LOG_FILE='$(MASTER_LOG_FILE)', MASTER_LOG_POS=$(MASTER_LOG_POS); START SLAVE;"
	docker exec -u 0 ${STACK_NAME}_db_slave mysql -u root -p${MARIADB_ROOT_PASSWORD} -e "SHOW SLAVE STATUS\G"
	docker exec -u 0 ${STACK_NAME}_db mariadb -u root -p${MARIADB_ROOT_PASSWORD} -e "REVOKE RELOAD ON *.* FROM '${MARIADB_USER}'@'%'; FLUSH PRIVILEGES;"

mysql_rebuild_slave:
	make --no-print-directory bkp_mkdir
	make --no-print-directory bkp_perm
	make --no-print-directory maintenance_on
	docker exec -u 0 ${STACK_NAME}_db mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT RELOAD, REPLICATION CLIENT, REPLICATION SLAVE, PROCESS ON *.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;"
	docker exec -u 0 ${STACK_NAME}_db mysqldump --all-databases --single-transaction --source-data=2 --flush-logs --hex-blob --triggers --routines --events -uroot -p${MYSQL_ROOT_PASSWORD} > ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/dump-rebuild-slave.sql
	docker cp ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/dump-rebuild-slave.sql ${STACK_NAME}_db_slave:/dump-rebuild-slave.sql
	rm -f ${STACK_VOLUME_BKP}/uncompressed/${CURRENT_BACKUP_DIR}/dump-rebuild-slave.sql
	docker exec -u 0 ${STACK_NAME}_db_slave mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "DROP DATABASE IF EXISTS ${MYSQL_DATABASE};"
	docker exec -u 0 ${STACK_NAME}_db_slave bash -c "mysql -u root -p${MYSQL_ROOT_PASSWORD} < /dump-rebuild-slave.sql"
	docker exec -u 0 ${STACK_NAME}_db_slave rm -f /dump-rebuild-slave.sql
	make  --no-print-directory  mysql_slave_config
	make --no-print-directory maintenance_off

mysql_slave_config:
	$(eval MASTER_STATUS := $(shell docker exec -u 0 ${STACK_NAME}_db mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW MASTER STATUS\G"))
	echo $$MASTER_STATUS;
	$(eval MASTER_LOG_FILE := $(shell echo '$(MASTER_STATUS)'   | grep -oP 'File: \K[^ ]+'))
	echo $$MASTER_LOG_FILE;
	$(eval MASTER_LOG_POS := $(shell echo '$(MASTER_STATUS)' | grep -oP 'Position: \K[0-9]+'))
	echo $$MASTER_LOG_POS;
	docker exec -u 0 ${STACK_NAME}_db_slave mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "STOP SLAVE; RESET SLAVE ALL; \
	CHANGE MASTER TO MASTER_HOST='db', MASTER_USER='${MYSQL_USER}', MASTER_PASSWORD='${MYSQL_PASSWORD}', \
	MASTER_LOG_FILE='$(MASTER_LOG_FILE)', MASTER_LOG_POS=$(MASTER_LOG_POS); START SLAVE;"
	docker exec -u 0 ${STACK_NAME}_db_slave mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW SLAVE STATUS\G"
	docker exec -u 0 ${STACK_NAME}_db mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "REVOKE RELOAD ON *.* FROM '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;"

make_test_course_XS:
	docker exec -u 0 ${STACK_NAME}_web php admin/tool/generator/cli/maketestcourse.php --shortname=SIZE_XS--size=XS

make_test_course_L:
	docker exec -u 0 ${STACK_NAME}_web php admin/tool/generator/cli/maketestcourse.php --shortname=SIZE_L --size=L

brcli_backup:
	docker exec -u 0 ${STACK_NAME}_web mkdir -p /backup
	docker exec -u 0 ${STACK_NAME}_web chown www-data:www-data /backup
	docker exec -u www-data ${STACK_NAME}_web php admin/tool/brcli/backup.php --categoryid=1 --destination=/backup

brcli_restore:
	docker exec -u www-data ${STACK_NAME}_web php admin/tool/brcli/restore.php --categoryid=1 --destination=/backup


