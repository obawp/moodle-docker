<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

// Database settings
$CFG->dbtype    = 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'db';
$CFG->dbname    = 'moodle';
$CFG->dbuser    = 'moodleuser';
$CFG->dbpass    = 'meeF9av3geegh9';
$CFG->prefix    = 'mdl_';
$CFG->dbport    = '5432';

$CFG->dboptions = array(
    'dbpersist' => false,
    'dbsocket'  => false,
    'dbport'    => '5432',
    'dbhandlesoptions' => false,
    'dbcollation' => 'utf8mb4_unicode_ci'
);

// Moodle's webroot and dataroot
// $CFG->serverurl = 'http://172.18.0.4:80';
// $CFG->wwwroot   = 'http://172.18.0.4:80';
$CFG->serverurl = 'http://moodle.local:80';
$CFG->wwwroot   = 'http://moodle.local:80';
$CFG->dataroot  = '/var/www/moodledata';
$CFG->dirroot   = '/var/www/html';
$CFG->themedir  = $CFG->dirroot . '/theme';

$CFG->admin = "admin";

// Moodle's cookie settings
$CFG->cookiepath    = '/var/www/moodledata/sessions/';
$CFG->cookiesecure  = false;
$CFG->cookiehttponly = true;

// Moodle language settings
$CFG->lang = 'en';

// Security settings
$CFG->passwordsaltmain = 'geiTheiz4yo7tanaeyoo9KohwohdAeyuaxohp3hon3';

// Timezone settings
$CFG->timezone = 'America/Sao_Paulo';

// Proxy settings (optional)
// $CFG->proxyhost  = '';
// $CFG->proxyport  = 0;

// Debugging settings (not for production use)
@error_reporting(E_ALL | E_STRICT);
@ini_set('display_errors', '1');
$CFG->debug = (E_ALL | E_STRICT);
$CFG->debugdisplay = 1;

// Include Moodle's setup function
require_once(__DIR__ . '/lib/setup.php');
