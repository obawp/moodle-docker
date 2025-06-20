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
STACK_VOLUME := ${VOLUME_DIR}/${STACK_NAME}
STACK_SRC := ./src/${STACK_NAME}

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
	- sudo mkdir -p ${STACK_VOLUME}/moodle/data
	- sudo mkdir -p ${STACK_VOLUME}/moodle/certbot/www
	- sudo mkdir -p ${STACK_VOLUME}/moodle/certbot/conf
	- make --no-print-directory mkdir_db
	- sudo chown $$USER:www-data ${STACK_VOLUME}/
	- sudo chown $$USER:www-data ${STACK_VOLUME}/moodle/
	- sudo chown $$USER:www-data ${STACK_VOLUME}/${DBTYPE}/
	- sudo chown $$USER:www-data ./config/moodle/config.${DBTYPE}.php
	- sudo chmod 640 ./config/moodle/config.${DBTYPE}.php
	- sudo chmod +x ./config/db/${DBTYPE}/custom-docker-entrypoint.sh
	- sudo chown $$USER:www-data ${STACK_VOLUME}/moodle/data
	- sudo chown $$USER:www-data ${STACK_VOLUME}/${DBTYPE}/data
	- make --no-print-directory mkdir_certbot
	- make --no-print-directory cp_aux
	- make --no-print-directory phpu_mkdir

mkdir_db:
	- sudo mkdir -p ${STACK_VOLUME}/${DBTYPE}/data

mkdir_certbot:
	- sudo mkdir -p ${STACK_VOLUME}/moodle/certbot/www/.well-known/acme-challenge/
	- sudo mkdir -p ${STACK_VOLUME}/moodle/certbot/conf
	- sudo chown $$USER:$$USER ${STACK_VOLUME}/moodle/certbot
	- sudo chmod 755 ${STACK_VOLUME}/moodle/certbot
	- sudo chown $$USER:$$USER ${STACK_VOLUME}/moodle/certbot/www
	- sudo chmod 755 ${STACK_VOLUME}/moodle/certbot/www
	- sudo chown $$USER:$$USER ${STACK_VOLUME}/moodle/certbot/conf
	- sudo chmod 755 ${STACK_VOLUME}/moodle/certbot/conf

cp_aux:
	@if docker ps -a --format '{{.Names}}' | grep -q "^${STACK_NAME}_aux$$"; then \
		sudo rm -Rf ${STACK_SRC}; \
		mkdir ./src; \
		docker cp ${STACK_NAME}_aux:/var/www/html ${STACK_SRC}; \
		make --no-print-directory cp_certbot; \
	else \
		echo "Skipping src folder copy of the container ${STACK_NAME}_aux."; \
	fi

cp_certbot:
	sudo rm -Rf ${STACK_VOLUME}/moodle/certbot/conf;
	docker cp ${STACK_NAME}_aux:/etc/letsencrypt ${STACK_VOLUME}/moodle/certbot/conf;
	find ${STACK_VOLUME}/moodle/certbot/conf -type d -exec chmod 0700 {} \;
	find ${STACK_VOLUME}/moodle/certbot/conf -type f -exec chmod 0600 {} \;
	sudo chown -R root:root ${STACK_VOLUME}/moodle/certbot/conf

rmdir:
	- make --no-print-directory rmdir_html
	- make --no-print-directory rmdir_moodledata
	- make --no-print-directory rmdir_db
	- make --no-print-directory rmdir_certbot
	- make --no-print-directory phpu_rmdir

rmdir_html:
	- sudo rm -Rf ${STACK_SRC}/

rmdir_moodledata:
	- sudo rm -Rf ${STACK_VOLUME}/moodle/data/

rmdir_db:
	- sudo rm -Rf ${STACK_VOLUME}/${DBTYPE}/data/

rmdir_certbot:
	- sudo rm -Rf ${STACK_VOLUME}/moodle/certbot/

up:
	make --no-print-directory rm_web
	make --no-print-directory rm_pma
	make --no-print-directory run
	make --no-print-directory cp_certbot
	make --no-print-directory rm_aux
	- docker compose -p ${STACK} --project-directory ./ -f "./docker-compose/docker-compose.${DBTYPE}.yml" up -d

up_force_recreate:
	make --no-print-directory rm_web
	make --no-print-directory rm_pma
	make --no-print-directory run
	make --no-print-directory cp_certbot
	make --no-print-directory rm_aux
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
	- sudo find ${STACK_VOLUME}/moodle/data -type d -exec chmod 0770 {} \;
	- sudo find ${STACK_VOLUME}/moodle/data -type f -exec chmod 0660 {} \;
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
	- sudo mkdir -p ${STACK_VOLUME}/phpunit/moodle/data
	- sudo mkdir -p ${STACK_VOLUME}/phpunit/${DBTYPE}/data
	- sudo chown $$USER:www-data ${STACK_VOLUME}/phpunit/

phpu_perm:
	- sudo chown -R $$USER:www-data ${STACK_VOLUME}/phpunit/moodle/data/
	- sudo chmod 0770 ${STACK_VOLUME}/phpunit/moodle/data/
	- sudo find ${STACK_VOLUME}/phpunit/moodle/data -type d -exec chmod 0770 {} \;
	- sudo find ${STACK_VOLUME}/phpunit/moodle/data -type f -exec chmod 0660 {} \;

phpu_install:
	-  docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web composer install
	-  docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/tool/phpunit/cli/init.php

phpu_rmdir:
	- sudo rm -Rf ${STACK_VOLUME}/phpunit/moodle/data/*
	- sudo rm -Rf ${STACK_VOLUME}/phpunit/${DBTYPE}/data/*

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
	- ls ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/courses
	
bkp_courses_restore:
	docker exec -it -u 0 -w / ${STACK_NAME}_web mkdir -p /var/www/backup/courses
	docker exec -it -u 0 -w / ${STACK_NAME}_web chown root:www-data /var/www/backup
	docker  cp ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/courses ${STACK_NAME}_web:/var/www/backup
	ls ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/courses | while IFS= read -r course; do docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web bash -c "echo "$$course"; /usr/bin/php admin/cli/restore_backup.php --file=/var/www/backup/courses/$$course --categoryid=1 & wait;"; done

plugins_purge_missing_dry:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/cli/uninstall_plugins.php --purge-missing

# Example: make plugins=mod_assign,mod_forum plugins_uninstall_dry
plugins_uninstall_dry:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/cli/uninstall_plugins.php  --plugins=$(plugins)

plugins_purge_missing:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/cli/uninstall_plugins.php --purge-missing --run

# Example: make plugins=mod_assign,mod_forum plugins_install
plugins_install:
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web bash -c "moosh plugin-list";
	- echo "$(plugins)" | while IFS= read -r plugin; do docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web bash -c "moosh plugin-install $$plugin"; done


# Example: make plugins=mod_assign,mod_forum plugins_uninstall
plugins_uninstall:
	- echo "$(plugins)" | while IFS= read -r plugin; do docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web bash -c "moosh plugin-uninstall $$plugin"; done
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web /usr/bin/php admin/cli/uninstall_plugins.php  --plugins=$(plugins) --run

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
	- sudo mkdir -p ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/html
	- sudo mkdir -p ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/moodledata
	- sudo mkdir -p ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/courses

bkp_perm:
	- sudo chown $$USER:www-data ${STACK_VOLUME}/
	- sudo chown $$USER:www-data -R ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}


bkp_cat_plugins_list:
	- cat ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/plugins-list.txt

bkp_make_plugins_list:
	- docker exec -u 0 ${STACK_NAME}_db mariadb -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} -e "SELECT p.plugin FROM mdl_config_plugins p WHERE p.plugin NOT IN ( 'adminpresets', 'adminpresets', 'aiplacement_courseassist', 'aiplacement_editor', 'aiprovider_azureai', 'aiprovider_openai', 'analytics', 'antivirus', 'antivirus_clamav', 'areafiles', 'assign', 'assignfeedback_comments', 'assignfeedback_editpdf', 'assignfeedback_file', 'assignfeedback_offline', 'assignsubmission_comments', 'assignsubmission_file', 'assignsubmission_onlinetext', 'atto_accessibilitychecker', 'atto_accessibilityhelper', 'atto_align', 'atto_backcolor', 'atto_bold', 'atto_charmap', 'atto_clear', 'atto_collapse', 'atto_emojipicker', 'atto_emoticon', 'atto_equation', 'atto_fontcolor', 'atto_h5p', 'atto_html', 'atto_image', 'atto_indent', 'atto_italic', 'atto_link', 'atto_managefiles', 'atto_media', 'atto_noautolink', 'atto_orderedlist', 'atto_recordrtc', 'atto_rtl', 'atto_strike', 'atto_subscript', 'atto_superscript', 'atto_table', 'atto_title', 'atto_underline', 'atto_undo', 'atto_unorderedlist', 'auth_cas', 'auth_db', 'auth_email', 'auth_ldap', 'auth_lti', 'auth_manual', 'auth_mnet', 'auth_nologin', 'auth_none', 'auth_oauth2', 'auth_shibboleth', 'auth_webservice', 'availability_completion', 'availability_date', 'availability_grade', 'availability_group', 'availability_grouping', 'availability_profile', 'backup', 'block_accessreview', 'block_activity_modules', 'block_activity_results', 'block_admin_bookmarks', 'block_badges', 'block_blog_menu', 'block_blog_recent', 'block_blog_tags', 'block_calendar_month', 'block_calendar_upcoming', 'block_comments', 'block_completionstatus', 'block_course_list', 'block_course_summary', 'block_feedback', 'block_globalsearch', 'block_glossary_random', 'block_html', 'block_login', 'block_lp', 'block_mentees', 'block_mnet_hosts', 'block_myoverview', 'block_myprofile', 'block_navigation', 'block_news_items', 'block_online_users', 'block_private_files', 'block_recent_activity', 'block_recentlyaccessedcourses', 'block_recentlyaccesseditems', 'block_rss_client', 'block_search_forums', 'block_section_links', 'block_selfcompletion', 'block_settings', 'block_site_main_menu', 'block_social_activities', 'block_starredcourses', 'block_tag_flickr', 'block_tag_youtube', 'block_tags', 'block_timeline', 'book', 'booktool_exportimscp', 'booktool_importhtml', 'booktool_print', 'cachelock_file', 'cachestore_apcu', 'cachestore_file', 'cachestore_redis', 'cachestore_session', 'cachestore_static', 'calendartype_gregorian', 'communication_customlink', 'communication_matrix', 'contentbank', 'contenttype_h5p', 'core_admin', 'core_competency', 'core_h5p', 'customfield_checkbox', 'customfield_date', 'customfield_number', 'customfield_select', 'customfield_text', 'customfield_textarea', 'datafield_checkbox', 'datafield_date', 'datafield_file', 'datafield_latlong', 'datafield_menu', 'datafield_multimenu', 'datafield_number', 'datafield_picture', 'datafield_radiobutton', 'datafield_text', 'datafield_textarea', 'datafield_url', 'dataformat_csv', 'dataformat_excel', 'dataformat_html', 'dataformat_json', 'dataformat_ods', 'dataformat_pdf', 'datapreset_imagegallery', 'datapreset_journal', 'datapreset_proposals', 'datapreset_resources', 'editor_atto', 'editor_textarea', 'editor_tiny', 'enrol_category', 'enrol_cohort', 'enrol_database', 'enrol_fee', 'enrol_flatfile', 'enrol_guest', 'enrol_imsenterprise', 'enrol_ldap', 'enrol_lti', 'enrol_manual', 'enrol_meta', 'enrol_mnet', 'enrol_paypal', 'enrol_self', 'factor_admin', 'factor_auth', 'factor_capability', 'factor_cohort', 'factor_email', 'factor_grace', 'factor_iprange', 'factor_nosetup', 'factor_role', 'factor_sms', 'factor_token', 'factor_totp', 'factor_webauthn', 'fileconverter_googledrive', 'fileconverter_unoconv', 'filter_activitynames', 'filter_algebra', 'filter_codehighlighter', 'filter_data', 'filter_displayh5p', 'filter_emailprotect', 'filter_emoticon', 'filter_glossary', 'filter_mathjaxloader', 'filter_mediaplugin', 'filter_multilang', 'filter_tex', 'filter_urltolink', 'folder', 'format_singleactivity', 'format_social', 'format_topics', 'format_weeks', 'forumreport_summary', 'gradeexport_ods', 'gradeexport_txt', 'gradeexport_xls', 'gradeexport_xml', 'gradeimport_csv', 'gradeimport_direct', 'gradeimport_xml', 'gradereport_grader', 'gradereport_history', 'gradereport_outcomes', 'gradereport_overview', 'gradereport_singleview', 'gradereport_summary', 'gradereport_user', 'gradingform_guide', 'gradingform_rubric', 'h5plib_v127', 'imscp', 'label', 'local', 'logstore_database', 'logstore_standard', 'ltiservice_basicoutcomes', 'ltiservice_gradebookservices', 'ltiservice_memberships', 'ltiservice_profile', 'ltiservice_toolproxy', 'ltiservice_toolsettings', 'media_html5audio', 'media_html5video', 'media_videojs', 'media_vimeo', 'media_youtube', 'message', 'message_airnotifier', 'message_email', 'message_popup', 'mlbackend_php', 'mlbackend_python', 'mnetservice_enrol', 'mod_assign', 'mod_bigbluebuttonbn', 'mod_book', 'mod_chat', 'mod_choice', 'mod_data', 'mod_feedback', 'mod_folder', 'mod_forum', 'mod_glossary', 'mod_h5pactivity', 'mod_imscp', 'mod_label', 'mod_lesson', 'mod_lti', 'mod_page', 'mod_quiz', 'mod_resource', 'mod_scorm', 'mod_subsection', 'mod_survey', 'mod_url', 'mod_wiki', 'mod_workshop', 'moodlecourse', 'page', 'paygw_paypal', 'portfolio_download', 'portfolio_flickr', 'portfolio_googledocs', 'portfolio_mahara', 'profilefield_checkbox', 'profilefield_datetime', 'profilefield_menu', 'profilefield_social', 'profilefield_text', 'profilefield_textarea', 'qbank_bulkmove', 'qbank_columnsortorder', 'qbank_comment', 'qbank_customfields', 'qbank_deletequestion', 'qbank_editquestion', 'qbank_exportquestions', 'qbank_exporttoxml', 'qbank_history', 'qbank_importquestions', 'qbank_managecategories', 'qbank_previewquestion', 'qbank_statistics', 'qbank_tagquestion', 'qbank_usage', 'qbank_viewcreator', 'qbank_viewquestionname', 'qbank_viewquestiontext', 'qbank_viewquestiontype', 'qbehaviour_adaptive', 'qbehaviour_adaptivenopenalty', 'qbehaviour_deferredcbm', 'qbehaviour_deferredfeedback', 'qbehaviour_immediatecbm', 'qbehaviour_immediatefeedback', 'qbehaviour_informationitem', 'qbehaviour_interactive', 'qbehaviour_interactivecountback', 'qbehaviour_manualgraded', 'qbehaviour_missing', 'qformat_aiken', 'qformat_blackboard_six', 'qformat_gift', 'qformat_missingword', 'qformat_multianswer', 'qformat_xhtml', 'qformat_xml', 'qtype_calculated', 'qtype_calculatedmulti', 'qtype_calculatedsimple', 'qtype_ddimageortext', 'qtype_ddmarker', 'qtype_ddwtos', 'qtype_description', 'qtype_essay', 'qtype_gapselect', 'qtype_match', 'qtype_missingtype', 'qtype_multianswer', 'qtype_multichoice', 'qtype_numerical', 'qtype_ordering', 'qtype_random', 'qtype_randomsamatch', 'qtype_shortanswer', 'qtype_truefalse', 'question', 'question_preview', 'quiz', 'quiz_grading', 'quiz_overview', 'quiz_responses', 'quiz_statistics', 'quizaccess_delaybetweenattempts', 'quizaccess_ipaddress', 'quizaccess_numattempts', 'quizaccess_offlineattempts', 'quizaccess_openclosedate', 'quizaccess_password', 'quizaccess_seb', 'quizaccess_securewindow', 'quizaccess_timelimit', 'recent', 'report_backups', 'report_competency', 'report_completion', 'report_configlog', 'report_courseoverview', 'report_eventlist', 'report_infectedfiles', 'report_insights', 'report_log', 'report_loglive', 'report_outline', 'report_participation', 'report_performance', 'report_progress', 'report_questioninstances', 'report_security', 'report_stats', 'report_status', 'report_themeusage', 'report_usersessions', 'repository_areafiles', 'repository_contentbank', 'repository_coursefiles', 'repository_dropbox', 'repository_equella', 'repository_filesystem', 'repository_flickr', 'repository_flickr_public', 'repository_googledocs', 'repository_local', 'repository_merlot', 'repository_nextcloud', 'repository_onedrive', 'repository_recent', 'repository_s3', 'repository_upload', 'repository_url', 'repository_user', 'repository_webdav', 'repository_wikimedia', 'repository_youtube', 'resource', 'restore', 'scorm', 'scormreport_basic', 'scormreport_graphs', 'scormreport_interactions', 'scormreport_objectives', 'search_simpledb', 'search_solr', 'smsgateway_aws', 'theme_boost', 'theme_classic', 'tiny_accessibilitychecker', 'tiny_aiplacement', 'tiny_autosave', 'tiny_equation', 'tiny_h5p', 'tiny_html', 'tiny_link', 'tiny_media', 'tiny_noautolink', 'tiny_premium', 'tiny_recordrtc', 'tool_admin_presets', 'tool_analytics', 'tool_availabilityconditions', 'tool_behat', 'tool_brickfield', 'tool_capability', 'tool_cohortroles', 'tool_componentlibrary', 'tool_customlang', 'tool_dataprivacy', 'tool_dbtransfer', 'tool_filetypes', 'tool_generator', 'tool_httpsreplace', 'tool_installaddon', 'tool_langimport', 'tool_licensemanager', 'tool_log', 'tool_lp', 'tool_lpimportcsv', 'tool_lpmigrate', 'tool_messageinbound', 'tool_mfa', 'tool_mobile', 'tool_monitor', 'tool_moodlenet', 'tool_multilangupgrade', 'tool_oauth2', 'tool_phpunit', 'tool_policy', 'tool_profiling', 'tool_recyclebin', 'tool_replace', 'tool_spamcleaner', 'tool_task', 'tool_templatelibrary', 'tool_unsuproles', 'tool_uploadcourse', 'tool_uploaduser', 'tool_usertours', 'tool_xmldb', 'upload', 'url', 'user', 'webservice_rest', 'webservice_soap', 'wikimedia', 'workshop', 'workshopallocation_manual', 'workshopallocation_random', 'workshopallocation_scheduled', 'workshopeval_best', 'workshopform_accumulative', 'workshopform_comments', 'workshopform_numerrors', 'workshopform_rubric'  ) GROUP BY p.plugin ORDER BY p.plugin"  > ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/plugins-list.txt

bkp_install_plugins:
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web bash -c "moosh plugin-list";
	- while IFS= read -r plugin; do docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web bash -c "moosh plugin-install $$plugin"; done < ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/plugins-list.txt

bkp_uninstall_plugins:
	- while IFS= read -r plugin; do docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web bash -c "moosh plugin-uninstall $$plugin"; done < ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/plugins-list.txt


bkp_tar:
	- find ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR} -printf "%P\n" | tar -czf ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}.tgz --no-recursion -C ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR} -T -

bkp_untar:
	- tar -xzf ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}.tgz -C ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}


## CAREFUL: this will remove all the backup files
bkp_dump:
	make --no-print-directory bkp_mkdir
	make --no-print-directory bkp_perm
	- make --no-print-directory bkp_dump_html
	- make --no-print-directory bkp_dump_moodledata
	- make --no-print-directory bkp_dump_${DBTYPE}
	make --no-print-directory bkp_make_plugins_list
	make --no-print-directory bkp_tar

bkp_dump_html:
	- rm -Rf ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/html
	- docker cp ${STACK_NAME}_web:/var/www/html ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/html

bkp_dump_moodledata:
	- rm -Rf ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/moodledata
	- docker cp ${STACK_NAME}_web:/var/www/moodledata ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/moodledata

bkp_dump_mariadb:
	- docker exec -u 0 ${STACK_NAME}_db mariadb-dump -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} > ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/data.sql

# ini - this section needs be tested
bkp_dump_mysql:
	- docker exec -u 0 ${STACK_NAME}_db mysqldump -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/data.sql

bkp_dump_pgsql:
	- docker exec -u 0 ${STACK_NAME}_db bash -c "PGPASSWORD=${POSTGRES_PASSWORD} pg_dump -U ${POSTGRES_USER} -d ${POSTGRES_DB} -F c -f /backup/data.sql"
	- docker cp ${STACK_NAME}_db:/backup/data.sql ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/data.sql
# end - this section needs be tested


## CAREFUL: this will remove all the current installation files
bkp_restore:
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
	make --no-print-directory rmdir_html
	- sudo cp -Rp ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/html ${STACK_SRC}

bkp_restore_moodledata:
	make --no-print-directory rmdir_moodledata
	- sudo cp -Rp ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/moodledata ${STACK_VOLUME}/moodle/data

bkp_restore_mariadb:
	make --no-print-directory rm
	sleep 1
	make --no-print-directory rmdir_db
	make --no-print-directory mkdir_db
	sleep 1
	make --no-print-directory up
	sleep 10
	make --no-print-directory bkp_restore_mariadb_import

bkp_restore_mariadb_import:
	docker exec -u 0 ${STACK_NAME}_db mkdir -p /backup
	docker cp ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/data.sql ${STACK_NAME}_db:/backup/data.sql
	docker exec -u 0 ${STACK_NAME}_db chown root:root -R /backup
	docker exec -u 0 ${STACK_NAME}_db chmod 640 -R /backup
	docker exec -u 0 ${STACK_NAME}_db bash -c "mariadb -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} < /backup/data.sql";
	docker exec -u 0 ${STACK_NAME}_db bash -c "rm /backup/data.sql";

# ini - this section needs be tested
bkp_restore_mysql:
	make --no-print-directory rm
	make --no-print-directory rmdir_db
	make --no-print-directory up
	- docker exec -u 0 ${STACK_NAME}_db mkdir -p /backup
	- docker cp ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/data.sql ${STACK_NAME}_db:/backup/data.sql
	- docker exec -u 0 ${STACK_NAME}_db chown root:root -R /backup
	- docker exec -u 0 ${STACK_NAME}_db chmod 640 -R /backup

	- docker exec -u 0 ${STACK_NAME}_db bash -c "mysql -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} < /backup/data.sql"
	- docker exec -u 0 ${STACK_NAME}_db bash -c "rm /backup/data.sql"

bkp_restore_pgsql:
	make --no-print-directory rm
	make --no-print-directory rmdir_db
	make --no-print-directory up
	- docker cp ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/data.sql ${STACK_NAME}_db:/backup/data.sql
	- docker exec -u 0 ${STACK_NAME}_db bash -c "PGPASSWORD=${POSTGRES_PASSWORD} pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DB} --clean /backup/data.sql"
# end - this section needs be tested


bkp_rmdir:
	- sudo rm -Rf ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}

bkp_rm_tgz:
	- sudo rm -Rf ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}.tgz


bkp_to_remote_tgz:
	- sudo scp -P ${SSH_PORT} ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}.tgz ${SSH_USER}@${SSH_HOST}:${SSH_VOLUME_DIR}/backup/

bkp_from_remote_tgz:
	- sudo scp -P ${SSH_PORT} ${SSH_USER}@${SSH_HOST}:${SSH_VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}.tgz ${STACK_VOLUME}/backup/

bkp_from_remote:
	- make --no-print-directory bkp_mkdir
	- make --no-print-directory bkp_perm
	- make --no-print-directory bkp_from_remote_html
	- make --no-print-directory bkp_from_remote_moodledata
	- make --no-print-directory bkp_from_remote_db

bkp_from_remote_html:
	- sudo scp -r -P ${SSH_PORT} ${SSH_USER}@${SSH_HOST}:${SSH_HTML_DIR}/. ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/html

bkp_from_remote_moodledata:
	- sudo scp -r -P ${SSH_PORT} ${SSH_USER}@${SSH_HOST}:${SSH_MOODLEDATA_DIR}/. ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/moodledata

bkp_from_remote_db:
	mysqldump --skip-ssl -P ${REMOTE_MYSQL_PORT} -h ${REMOTE_MYSQL_HOST} -u${REMOTE_MYSQL_USER} -p${REMOTE_MYSQL_PASSWORD} \
	${REMOTE_MYSQL_DATABASE} > ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/data.sql
	# ssh -p "${REMOTE_MYSQL_SSH_PORT}" "${REMOTE_MYSQL_SSH_USER}@${REMOTE_MYSQL_SSH_HOST}" \
	# "mysqldump -P '${REMOTE_MYSQL_PORT}' -h 127.0.0.1 -u'${REMOTE_MYSQL_USER}' -p${REMOTE_MYSQL_PASSWORD} '${REMOTE_MYSQL_DATABASE}' > /root/data.sql"
	# sudo scp -P ${REMOTE_MYSQL_SSH_PORT} ${REMOTE_MYSQL_SSH_USER}@${REMOTE_MYSQL_SSH_HOST}:/root/data.sql ${STACK_VOLUME}/backup/${CURRENT_BACKUP_DIR}/data.sql
	# ssh -p ${REMOTE_MYSQL_SSH_PORT} ${REMOTE_MYSQL_SSH_USER}@${REMOTE_MYSQL_SSH_HOST} bash -c "rm /root/data.sql"

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

certbot_init:
	- docker exec -it ${STACK_NAME}_certbot certbot delete --cert-name ${DOMAIN} --non-interactive --quiet
	docker exec -it ${STACK_NAME}_certbot certbot certonly --webroot --cert-name ${DOMAIN} -w /var/www/certbot  --email ${CERT_EMAIL} -d ${DOMAIN} --rsa-key-size 4096 --agree-tos --force-renewal --debug-challenges -v
	- make --no-print-directory rm
	- make --no-print-directory up
# after test it here: https://www.ssllabs.com/ssltest/index.html


maintenance_on:
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web php admin/cli/maintenance.php --enable

maintenance_off:
	- docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web php admin/cli/maintenance.php --disable

update:
	make --no-print-directory maintenance_on
	- docker exec -u 0 -w /var/www/html/ ${STACK_NAME}_web git config --global --add safe.directory /var/www/html
	docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web git remote update
	docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web git checkout MOODLE_405_STABLE
	docker exec -u www-data -w /var/www/html/ ${STACK_NAME}_web git pull
	docker exec -it -u www-data -w /var/www/html/ ${STACK_NAME}_web php admin/cli/upgrade.php
	make --no-print-directory perm
	make --no-print-directory purge_caches
	make --no-print-directory maintenance_off
	