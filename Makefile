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

up_limited_resources:
	- docker compose --compatibility -p ${STACK} --project-directory ./ -f "./docker-compose/docker-compose.${DBTYPE}.yml" up -d

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
	- docker exec -u 0 ${STACK}_moodle_web find /var/www/html -not -path '/var/www/html/php.ini' -type f -iname php.ini  -exec chown $$USER:root {} \;

perm_moodledata:
	- docker exec -u 0 ${STACK}_moodle_web chown www-data:www-data -R /var/www/moodledata
	# - docker exec -u 0 ${STACK}_moodle_web chmod 0777 -R /var/www/moodledata
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
	- sudo chown -R $$USER:www-data ${VOLUME_DIR}/phpunit/moodle/data/
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
	-  docker exec -u www-data -w /var/www/html/ ${STACK}_moodle_web /usr/bin/php admin/cli/purge_caches.php

purge_caches_manual:
	-  docker exec -u www-data -w /var/www/moodledata/ ${STACK}_moodle_web rm -rf localcache
	-  docker exec -u www-data -w /var/www/moodledata/ ${STACK}_moodle_web rm -rf cache
	-  docker exec -u www-data -w /var/www/moodledata/ ${STACK}_moodle_web rm -rf temp

upgrade:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK}_moodle_web /usr/bin/php admin/cli/upgrade.php

plugins_list:
	- docker exec -u 0 ${STACK}_moodle_db mariadb -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} -e "SELECT p.plugin FROM mdl_config_plugins p WHERE p.plugin NOT IN ( 'adminpresets', 'adminpresets', 'aiplacement_courseassist', 'aiplacement_editor', 'aiprovider_azureai', 'aiprovider_openai', 'analytics', 'antivirus', 'antivirus_clamav', 'areafiles', 'assign', 'assignfeedback_comments', 'assignfeedback_editpdf', 'assignfeedback_file', 'assignfeedback_offline', 'assignsubmission_comments', 'assignsubmission_file', 'assignsubmission_onlinetext', 'atto_accessibilitychecker', 'atto_accessibilityhelper', 'atto_align', 'atto_backcolor', 'atto_bold', 'atto_charmap', 'atto_clear', 'atto_collapse', 'atto_emojipicker', 'atto_emoticon', 'atto_equation', 'atto_fontcolor', 'atto_h5p', 'atto_html', 'atto_image', 'atto_indent', 'atto_italic', 'atto_link', 'atto_managefiles', 'atto_media', 'atto_noautolink', 'atto_orderedlist', 'atto_recordrtc', 'atto_rtl', 'atto_strike', 'atto_subscript', 'atto_superscript', 'atto_table', 'atto_title', 'atto_underline', 'atto_undo', 'atto_unorderedlist', 'auth_cas', 'auth_db', 'auth_email', 'auth_ldap', 'auth_lti', 'auth_manual', 'auth_mnet', 'auth_nologin', 'auth_none', 'auth_oauth2', 'auth_shibboleth', 'auth_webservice', 'availability_completion', 'availability_date', 'availability_grade', 'availability_group', 'availability_grouping', 'availability_profile', 'backup', 'block_accessreview', 'block_activity_modules', 'block_activity_results', 'block_admin_bookmarks', 'block_badges', 'block_blog_menu', 'block_blog_recent', 'block_blog_tags', 'block_calendar_month', 'block_calendar_upcoming', 'block_comments', 'block_completionstatus', 'block_course_list', 'block_course_summary', 'block_feedback', 'block_globalsearch', 'block_glossary_random', 'block_html', 'block_login', 'block_lp', 'block_mentees', 'block_mnet_hosts', 'block_myoverview', 'block_myprofile', 'block_navigation', 'block_news_items', 'block_online_users', 'block_private_files', 'block_recent_activity', 'block_recentlyaccessedcourses', 'block_recentlyaccesseditems', 'block_rss_client', 'block_search_forums', 'block_section_links', 'block_selfcompletion', 'block_settings', 'block_site_main_menu', 'block_social_activities', 'block_starredcourses', 'block_tag_flickr', 'block_tag_youtube', 'block_tags', 'block_timeline', 'book', 'booktool_exportimscp', 'booktool_importhtml', 'booktool_print', 'cachelock_file', 'cachestore_apcu', 'cachestore_file', 'cachestore_redis', 'cachestore_session', 'cachestore_static', 'calendartype_gregorian', 'communication_customlink', 'communication_matrix', 'contentbank', 'contenttype_h5p', 'core_admin', 'core_competency', 'core_h5p', 'customfield_checkbox', 'customfield_date', 'customfield_number', 'customfield_select', 'customfield_text', 'customfield_textarea', 'datafield_checkbox', 'datafield_date', 'datafield_file', 'datafield_latlong', 'datafield_menu', 'datafield_multimenu', 'datafield_number', 'datafield_picture', 'datafield_radiobutton', 'datafield_text', 'datafield_textarea', 'datafield_url', 'dataformat_csv', 'dataformat_excel', 'dataformat_html', 'dataformat_json', 'dataformat_ods', 'dataformat_pdf', 'datapreset_imagegallery', 'datapreset_journal', 'datapreset_proposals', 'datapreset_resources', 'editor_atto', 'editor_textarea', 'editor_tiny', 'enrol_category', 'enrol_cohort', 'enrol_database', 'enrol_fee', 'enrol_flatfile', 'enrol_guest', 'enrol_imsenterprise', 'enrol_ldap', 'enrol_lti', 'enrol_manual', 'enrol_meta', 'enrol_mnet', 'enrol_paypal', 'enrol_self', 'factor_admin', 'factor_auth', 'factor_capability', 'factor_cohort', 'factor_email', 'factor_grace', 'factor_iprange', 'factor_nosetup', 'factor_role', 'factor_sms', 'factor_token', 'factor_totp', 'factor_webauthn', 'fileconverter_googledrive', 'fileconverter_unoconv', 'filter_activitynames', 'filter_algebra', 'filter_codehighlighter', 'filter_data', 'filter_displayh5p', 'filter_emailprotect', 'filter_emoticon', 'filter_glossary', 'filter_mathjaxloader', 'filter_mediaplugin', 'filter_multilang', 'filter_tex', 'filter_urltolink', 'folder', 'format_singleactivity', 'format_social', 'format_topics', 'format_weeks', 'forumreport_summary', 'gradeexport_ods', 'gradeexport_txt', 'gradeexport_xls', 'gradeexport_xml', 'gradeimport_csv', 'gradeimport_direct', 'gradeimport_xml', 'gradereport_grader', 'gradereport_history', 'gradereport_outcomes', 'gradereport_overview', 'gradereport_singleview', 'gradereport_summary', 'gradereport_user', 'gradingform_guide', 'gradingform_rubric', 'h5plib_v127', 'imscp', 'label', 'local', 'logstore_database', 'logstore_standard', 'ltiservice_basicoutcomes', 'ltiservice_gradebookservices', 'ltiservice_memberships', 'ltiservice_profile', 'ltiservice_toolproxy', 'ltiservice_toolsettings', 'media_html5audio', 'media_html5video', 'media_videojs', 'media_vimeo', 'media_youtube', 'message', 'message_airnotifier', 'message_email', 'message_popup', 'mlbackend_php', 'mlbackend_python', 'mnetservice_enrol', 'mod_assign', 'mod_bigbluebuttonbn', 'mod_book', 'mod_chat', 'mod_choice', 'mod_data', 'mod_feedback', 'mod_folder', 'mod_forum', 'mod_glossary', 'mod_h5pactivity', 'mod_imscp', 'mod_label', 'mod_lesson', 'mod_lti', 'mod_page', 'mod_quiz', 'mod_resource', 'mod_scorm', 'mod_subsection', 'mod_survey', 'mod_url', 'mod_wiki', 'mod_workshop', 'moodlecourse', 'page', 'paygw_paypal', 'portfolio_download', 'portfolio_flickr', 'portfolio_googledocs', 'portfolio_mahara', 'profilefield_checkbox', 'profilefield_datetime', 'profilefield_menu', 'profilefield_social', 'profilefield_text', 'profilefield_textarea', 'qbank_bulkmove', 'qbank_columnsortorder', 'qbank_comment', 'qbank_customfields', 'qbank_deletequestion', 'qbank_editquestion', 'qbank_exportquestions', 'qbank_exporttoxml', 'qbank_history', 'qbank_importquestions', 'qbank_managecategories', 'qbank_previewquestion', 'qbank_statistics', 'qbank_tagquestion', 'qbank_usage', 'qbank_viewcreator', 'qbank_viewquestionname', 'qbank_viewquestiontext', 'qbank_viewquestiontype', 'qbehaviour_adaptive', 'qbehaviour_adaptivenopenalty', 'qbehaviour_deferredcbm', 'qbehaviour_deferredfeedback', 'qbehaviour_immediatecbm', 'qbehaviour_immediatefeedback', 'qbehaviour_informationitem', 'qbehaviour_interactive', 'qbehaviour_interactivecountback', 'qbehaviour_manualgraded', 'qbehaviour_missing', 'qformat_aiken', 'qformat_blackboard_six', 'qformat_gift', 'qformat_missingword', 'qformat_multianswer', 'qformat_xhtml', 'qformat_xml', 'qtype_calculated', 'qtype_calculatedmulti', 'qtype_calculatedsimple', 'qtype_ddimageortext', 'qtype_ddmarker', 'qtype_ddwtos', 'qtype_description', 'qtype_essay', 'qtype_gapselect', 'qtype_match', 'qtype_missingtype', 'qtype_multianswer', 'qtype_multichoice', 'qtype_numerical', 'qtype_ordering', 'qtype_random', 'qtype_randomsamatch', 'qtype_shortanswer', 'qtype_truefalse', 'question', 'question_preview', 'quiz', 'quiz_grading', 'quiz_overview', 'quiz_responses', 'quiz_statistics', 'quizaccess_delaybetweenattempts', 'quizaccess_ipaddress', 'quizaccess_numattempts', 'quizaccess_offlineattempts', 'quizaccess_openclosedate', 'quizaccess_password', 'quizaccess_seb', 'quizaccess_securewindow', 'quizaccess_timelimit', 'recent', 'report_backups', 'report_competency', 'report_completion', 'report_configlog', 'report_courseoverview', 'report_eventlist', 'report_infectedfiles', 'report_insights', 'report_log', 'report_loglive', 'report_outline', 'report_participation', 'report_performance', 'report_progress', 'report_questioninstances', 'report_security', 'report_stats', 'report_status', 'report_themeusage', 'report_usersessions', 'repository_areafiles', 'repository_contentbank', 'repository_coursefiles', 'repository_dropbox', 'repository_equella', 'repository_filesystem', 'repository_flickr', 'repository_flickr_public', 'repository_googledocs', 'repository_local', 'repository_merlot', 'repository_nextcloud', 'repository_onedrive', 'repository_recent', 'repository_s3', 'repository_upload', 'repository_url', 'repository_user', 'repository_webdav', 'repository_wikimedia', 'repository_youtube', 'resource', 'restore', 'scorm', 'scormreport_basic', 'scormreport_graphs', 'scormreport_interactions', 'scormreport_objectives', 'search_simpledb', 'search_solr', 'smsgateway_aws', 'theme_boost', 'theme_classic', 'tiny_accessibilitychecker', 'tiny_aiplacement', 'tiny_autosave', 'tiny_equation', 'tiny_h5p', 'tiny_html', 'tiny_link', 'tiny_media', 'tiny_noautolink', 'tiny_premium', 'tiny_recordrtc', 'tool_admin_presets', 'tool_analytics', 'tool_availabilityconditions', 'tool_behat', 'tool_brickfield', 'tool_capability', 'tool_cohortroles', 'tool_componentlibrary', 'tool_customlang', 'tool_dataprivacy', 'tool_dbtransfer', 'tool_filetypes', 'tool_generator', 'tool_httpsreplace', 'tool_installaddon', 'tool_langimport', 'tool_licensemanager', 'tool_log', 'tool_lp', 'tool_lpimportcsv', 'tool_lpmigrate', 'tool_messageinbound', 'tool_mfa', 'tool_mobile', 'tool_monitor', 'tool_moodlenet', 'tool_multilangupgrade', 'tool_oauth2', 'tool_phpunit', 'tool_policy', 'tool_profiling', 'tool_recyclebin', 'tool_replace', 'tool_spamcleaner', 'tool_task', 'tool_templatelibrary', 'tool_unsuproles', 'tool_uploadcourse', 'tool_uploaduser', 'tool_usertours', 'tool_xmldb', 'upload', 'url', 'user', 'webservice_rest', 'webservice_soap', 'wikimedia', 'workshop', 'workshopallocation_manual', 'workshopallocation_random', 'workshopallocation_scheduled', 'workshopeval_best', 'workshopform_accumulative', 'workshopform_comments', 'workshopform_numerrors', 'workshopform_rubric'  ) GROUP BY p.plugin ORDER BY p.plugin"

clear_restores_in_progress_list:
	- docker exec -u 0 ${STACK}_moodle_db mariadb -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} -e "DELETE FROM mdl_backup_controllers WHERE interactive = 1;"

bkp_courses_restore:
	- docker exec -it -u www-data -w / ${STACK}_moodle_web mkdir -p /backup/courses
	- docker  cp ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/courses ${STACK}_moodle_web:/backup/courses
	- ls ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/courses | while IFS= read -r course; do docker exec -u www-data -w /var/www/html/ ${STACK}_moodle_web bash -c "echo "$$course"; /usr/bin/php admin/cli/restore_backup.php --file=/backup/courses/$$course --categoryid=1 "; done

plugins_purge_missing_dry:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK}_moodle_web /usr/bin/php admin/cli/uninstall_plugins.php --purge-missing

# Example: make plugins=mod_assign,mod_forum plugins_uninstall_dry
plugins_uninstall_dry:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK}_moodle_web /usr/bin/php admin/cli/uninstall_plugins.php  --plugins=$(plugins)

plugins_purge_missing:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK}_moodle_web /usr/bin/php admin/cli/uninstall_plugins.php --purge-missing --run

# Example: make plugins=mod_assign,mod_forum plugins_uninstall
plugins_uninstall:
	-  docker exec -it -u www-data -w /var/www/html/ ${STACK}_moodle_web /usr/bin/php admin/cli/uninstall_plugins.php  --plugins=$(plugins) --run

bkp_mkdir:
	- sudo mkdir -p ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/html
	- sudo mkdir -p ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/data
	- sudo mkdir -p ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/plugins
	- sudo mkdir -p ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/courses

bkp_perm:
	- sudo chown $$USER:www-data ${VOLUME_DIR}/
	- sudo chown $$USER:www-data -R ${VOLUME_DIR}/backup/

bkp_make_plugins_list:
	- docker exec -u 0 ${STACK}_moodle_db mariadb -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} -e "SELECT p.plugin FROM mdl_config_plugins p WHERE p.plugin NOT IN ( 'adminpresets', 'adminpresets', 'aiplacement_courseassist', 'aiplacement_editor', 'aiprovider_azureai', 'aiprovider_openai', 'analytics', 'antivirus', 'antivirus_clamav', 'areafiles', 'assign', 'assignfeedback_comments', 'assignfeedback_editpdf', 'assignfeedback_file', 'assignfeedback_offline', 'assignsubmission_comments', 'assignsubmission_file', 'assignsubmission_onlinetext', 'atto_accessibilitychecker', 'atto_accessibilityhelper', 'atto_align', 'atto_backcolor', 'atto_bold', 'atto_charmap', 'atto_clear', 'atto_collapse', 'atto_emojipicker', 'atto_emoticon', 'atto_equation', 'atto_fontcolor', 'atto_h5p', 'atto_html', 'atto_image', 'atto_indent', 'atto_italic', 'atto_link', 'atto_managefiles', 'atto_media', 'atto_noautolink', 'atto_orderedlist', 'atto_recordrtc', 'atto_rtl', 'atto_strike', 'atto_subscript', 'atto_superscript', 'atto_table', 'atto_title', 'atto_underline', 'atto_undo', 'atto_unorderedlist', 'auth_cas', 'auth_db', 'auth_email', 'auth_ldap', 'auth_lti', 'auth_manual', 'auth_mnet', 'auth_nologin', 'auth_none', 'auth_oauth2', 'auth_shibboleth', 'auth_webservice', 'availability_completion', 'availability_date', 'availability_grade', 'availability_group', 'availability_grouping', 'availability_profile', 'backup', 'block_accessreview', 'block_activity_modules', 'block_activity_results', 'block_admin_bookmarks', 'block_badges', 'block_blog_menu', 'block_blog_recent', 'block_blog_tags', 'block_calendar_month', 'block_calendar_upcoming', 'block_comments', 'block_completionstatus', 'block_course_list', 'block_course_summary', 'block_feedback', 'block_globalsearch', 'block_glossary_random', 'block_html', 'block_login', 'block_lp', 'block_mentees', 'block_mnet_hosts', 'block_myoverview', 'block_myprofile', 'block_navigation', 'block_news_items', 'block_online_users', 'block_private_files', 'block_recent_activity', 'block_recentlyaccessedcourses', 'block_recentlyaccesseditems', 'block_rss_client', 'block_search_forums', 'block_section_links', 'block_selfcompletion', 'block_settings', 'block_site_main_menu', 'block_social_activities', 'block_starredcourses', 'block_tag_flickr', 'block_tag_youtube', 'block_tags', 'block_timeline', 'book', 'booktool_exportimscp', 'booktool_importhtml', 'booktool_print', 'cachelock_file', 'cachestore_apcu', 'cachestore_file', 'cachestore_redis', 'cachestore_session', 'cachestore_static', 'calendartype_gregorian', 'communication_customlink', 'communication_matrix', 'contentbank', 'contenttype_h5p', 'core_admin', 'core_competency', 'core_h5p', 'customfield_checkbox', 'customfield_date', 'customfield_number', 'customfield_select', 'customfield_text', 'customfield_textarea', 'datafield_checkbox', 'datafield_date', 'datafield_file', 'datafield_latlong', 'datafield_menu', 'datafield_multimenu', 'datafield_number', 'datafield_picture', 'datafield_radiobutton', 'datafield_text', 'datafield_textarea', 'datafield_url', 'dataformat_csv', 'dataformat_excel', 'dataformat_html', 'dataformat_json', 'dataformat_ods', 'dataformat_pdf', 'datapreset_imagegallery', 'datapreset_journal', 'datapreset_proposals', 'datapreset_resources', 'editor_atto', 'editor_textarea', 'editor_tiny', 'enrol_category', 'enrol_cohort', 'enrol_database', 'enrol_fee', 'enrol_flatfile', 'enrol_guest', 'enrol_imsenterprise', 'enrol_ldap', 'enrol_lti', 'enrol_manual', 'enrol_meta', 'enrol_mnet', 'enrol_paypal', 'enrol_self', 'factor_admin', 'factor_auth', 'factor_capability', 'factor_cohort', 'factor_email', 'factor_grace', 'factor_iprange', 'factor_nosetup', 'factor_role', 'factor_sms', 'factor_token', 'factor_totp', 'factor_webauthn', 'fileconverter_googledrive', 'fileconverter_unoconv', 'filter_activitynames', 'filter_algebra', 'filter_codehighlighter', 'filter_data', 'filter_displayh5p', 'filter_emailprotect', 'filter_emoticon', 'filter_glossary', 'filter_mathjaxloader', 'filter_mediaplugin', 'filter_multilang', 'filter_tex', 'filter_urltolink', 'folder', 'format_singleactivity', 'format_social', 'format_topics', 'format_weeks', 'forumreport_summary', 'gradeexport_ods', 'gradeexport_txt', 'gradeexport_xls', 'gradeexport_xml', 'gradeimport_csv', 'gradeimport_direct', 'gradeimport_xml', 'gradereport_grader', 'gradereport_history', 'gradereport_outcomes', 'gradereport_overview', 'gradereport_singleview', 'gradereport_summary', 'gradereport_user', 'gradingform_guide', 'gradingform_rubric', 'h5plib_v127', 'imscp', 'label', 'local', 'logstore_database', 'logstore_standard', 'ltiservice_basicoutcomes', 'ltiservice_gradebookservices', 'ltiservice_memberships', 'ltiservice_profile', 'ltiservice_toolproxy', 'ltiservice_toolsettings', 'media_html5audio', 'media_html5video', 'media_videojs', 'media_vimeo', 'media_youtube', 'message', 'message_airnotifier', 'message_email', 'message_popup', 'mlbackend_php', 'mlbackend_python', 'mnetservice_enrol', 'mod_assign', 'mod_bigbluebuttonbn', 'mod_book', 'mod_chat', 'mod_choice', 'mod_data', 'mod_feedback', 'mod_folder', 'mod_forum', 'mod_glossary', 'mod_h5pactivity', 'mod_imscp', 'mod_label', 'mod_lesson', 'mod_lti', 'mod_page', 'mod_quiz', 'mod_resource', 'mod_scorm', 'mod_subsection', 'mod_survey', 'mod_url', 'mod_wiki', 'mod_workshop', 'moodlecourse', 'page', 'paygw_paypal', 'portfolio_download', 'portfolio_flickr', 'portfolio_googledocs', 'portfolio_mahara', 'profilefield_checkbox', 'profilefield_datetime', 'profilefield_menu', 'profilefield_social', 'profilefield_text', 'profilefield_textarea', 'qbank_bulkmove', 'qbank_columnsortorder', 'qbank_comment', 'qbank_customfields', 'qbank_deletequestion', 'qbank_editquestion', 'qbank_exportquestions', 'qbank_exporttoxml', 'qbank_history', 'qbank_importquestions', 'qbank_managecategories', 'qbank_previewquestion', 'qbank_statistics', 'qbank_tagquestion', 'qbank_usage', 'qbank_viewcreator', 'qbank_viewquestionname', 'qbank_viewquestiontext', 'qbank_viewquestiontype', 'qbehaviour_adaptive', 'qbehaviour_adaptivenopenalty', 'qbehaviour_deferredcbm', 'qbehaviour_deferredfeedback', 'qbehaviour_immediatecbm', 'qbehaviour_immediatefeedback', 'qbehaviour_informationitem', 'qbehaviour_interactive', 'qbehaviour_interactivecountback', 'qbehaviour_manualgraded', 'qbehaviour_missing', 'qformat_aiken', 'qformat_blackboard_six', 'qformat_gift', 'qformat_missingword', 'qformat_multianswer', 'qformat_xhtml', 'qformat_xml', 'qtype_calculated', 'qtype_calculatedmulti', 'qtype_calculatedsimple', 'qtype_ddimageortext', 'qtype_ddmarker', 'qtype_ddwtos', 'qtype_description', 'qtype_essay', 'qtype_gapselect', 'qtype_match', 'qtype_missingtype', 'qtype_multianswer', 'qtype_multichoice', 'qtype_numerical', 'qtype_ordering', 'qtype_random', 'qtype_randomsamatch', 'qtype_shortanswer', 'qtype_truefalse', 'question', 'question_preview', 'quiz', 'quiz_grading', 'quiz_overview', 'quiz_responses', 'quiz_statistics', 'quizaccess_delaybetweenattempts', 'quizaccess_ipaddress', 'quizaccess_numattempts', 'quizaccess_offlineattempts', 'quizaccess_openclosedate', 'quizaccess_password', 'quizaccess_seb', 'quizaccess_securewindow', 'quizaccess_timelimit', 'recent', 'report_backups', 'report_competency', 'report_completion', 'report_configlog', 'report_courseoverview', 'report_eventlist', 'report_infectedfiles', 'report_insights', 'report_log', 'report_loglive', 'report_outline', 'report_participation', 'report_performance', 'report_progress', 'report_questioninstances', 'report_security', 'report_stats', 'report_status', 'report_themeusage', 'report_usersessions', 'repository_areafiles', 'repository_contentbank', 'repository_coursefiles', 'repository_dropbox', 'repository_equella', 'repository_filesystem', 'repository_flickr', 'repository_flickr_public', 'repository_googledocs', 'repository_local', 'repository_merlot', 'repository_nextcloud', 'repository_onedrive', 'repository_recent', 'repository_s3', 'repository_upload', 'repository_url', 'repository_user', 'repository_webdav', 'repository_wikimedia', 'repository_youtube', 'resource', 'restore', 'scorm', 'scormreport_basic', 'scormreport_graphs', 'scormreport_interactions', 'scormreport_objectives', 'search_simpledb', 'search_solr', 'smsgateway_aws', 'theme_boost', 'theme_classic', 'tiny_accessibilitychecker', 'tiny_aiplacement', 'tiny_autosave', 'tiny_equation', 'tiny_h5p', 'tiny_html', 'tiny_link', 'tiny_media', 'tiny_noautolink', 'tiny_premium', 'tiny_recordrtc', 'tool_admin_presets', 'tool_analytics', 'tool_availabilityconditions', 'tool_behat', 'tool_brickfield', 'tool_capability', 'tool_cohortroles', 'tool_componentlibrary', 'tool_customlang', 'tool_dataprivacy', 'tool_dbtransfer', 'tool_filetypes', 'tool_generator', 'tool_httpsreplace', 'tool_installaddon', 'tool_langimport', 'tool_licensemanager', 'tool_log', 'tool_lp', 'tool_lpimportcsv', 'tool_lpmigrate', 'tool_messageinbound', 'tool_mfa', 'tool_mobile', 'tool_monitor', 'tool_moodlenet', 'tool_multilangupgrade', 'tool_oauth2', 'tool_phpunit', 'tool_policy', 'tool_profiling', 'tool_recyclebin', 'tool_replace', 'tool_spamcleaner', 'tool_task', 'tool_templatelibrary', 'tool_unsuproles', 'tool_uploadcourse', 'tool_uploaduser', 'tool_usertours', 'tool_xmldb', 'upload', 'url', 'user', 'webservice_rest', 'webservice_soap', 'wikimedia', 'workshop', 'workshopallocation_manual', 'workshopallocation_random', 'workshopallocation_scheduled', 'workshopeval_best', 'workshopform_accumulative', 'workshopform_comments', 'workshopform_numerrors', 'workshopform_rubric'  ) GROUP BY p.plugin ORDER BY p.plugin"  > ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/plugins/plugins-list.txt

bkp_install_plugins:
	- docker exec -u www-data -w /var/www/html/ ${STACK}_moodle_web bash -c "moosh plugin-list";
	- while IFS= read -r plugin; do docker exec -u www-data -w /var/www/html/ ${STACK}_moodle_web bash -c "moosh plugin-install $$plugin"; done < ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/plugins/plugins-list.txt

bkp_uninstall_plugins:
	- while IFS= read -r plugin; do docker exec -u www-data -w /var/www/html/ ${STACK}_moodle_web bash -c "moosh plugin-uninstall $$plugin"; done < ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/plugins/plugins-list.txt

bkp_src_dump:
	- docker cp ${STACK}_moodle_web:/var/www/html ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/src

bkp_moodledata_dump:
	- docker cp ${STACK}_moodle_web:/var/www/moodledata ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/moodledata

bkp_mariadb_dump:
	- docker exec -u 0 ${STACK}_moodle_db mariadb-dump -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} > ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/data.sql

# ini - this section need be tested
bkp_mysql_dump:
	- docker exec -u 0 ${STACK}_moodle_db mysqldump -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} > ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/data.sql

bkp_pgsql_dump:
	- docker exec -u 0 ${STACK}_moodle_db bash -c "PGPASSWORD=${POSTGRES_PASSWORD} pg_dump -U ${POSTGRES_USER} -d ${POSTGRES_DB} -F c -f /backup/data.dump"
	- docker cp ${STACK}_moodle_db:/backup/data.dump ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/data.dump
# end - this section need be tested


bkp_src_restore:
	[ -d "src" ] && echo "Error: src directory already exists" & exit 1 || sudo cp -Rp ${VOLUME_DIR}/backup/html ./src

bkp_moodledata_restore:
	- sudo rm -Rp src
	- sudo cp -Rp ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/moodledata ${VOLUME_DIR}/backup/moodle/data

bkp_mariadb_restore:
	- docker exec -u 0 ${STACK}_moodle_db mariadb -u ${MARIADB_USER} -p${MARIADB_PASSWORD} ${MARIADB_DATABASE} < ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/data.sql

# ini - this section need be tested
bkp_mysql_restore:
	- docker exec -u 0 ${STACK}_moodle_db mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/data.sql

bkp_pgsql_restore:
	- docker cp ${VOLUME_DIR}/backup/${CURRENT_BACKUP_DIR}/data.dump ${STACK}_moodle_db:/backup/data.dump
	- docker exec -u 0 ${STACK}_moodle_db bash -c "PGPASSWORD=${POSTGRES_PASSWORD} pg_restore -U ${POSTGRES_USER} -d ${POSTGRES_DB} --clean /backup/data.dump"
# end - this section need be tested


