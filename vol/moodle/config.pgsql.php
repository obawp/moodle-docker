<?php  // Moodle configuration file

unset($CFG);
global $CFG;
$CFG = new stdClass();

// a helper function to lookup "env_FILE", "env", then fallback
if (!function_exists('getenv_docker')) {
	// https://github.com/docker-library/wordpress/issues/588 (WP-CLI will load this file 2x)
	function getenv_docker($env, $default) {
		if ($fileEnv = getenv($env . '_FILE')) {
			return rtrim(file_get_contents($fileEnv), "\r\n");
		}
		else if (($val = getenv($env)) !== false) {
			return $val;
		}
		else {
			return $default;
		}
	}
}

// Database settings
$CFG->dbtype    =  'pgsql';
$CFG->dblibrary =  'native';
$CFG->dbhost    = 'db';
$CFG->dbname    = getenv_docker('MYSQL_DATABASE', 'moodle');
$CFG->dbuser    = getenv_docker('MYSQL_USER', 'moodleuser');
$CFG->dbpass    = getenv_docker('MYSQL_PASSWORD', 'meeF9av3geegh9');
$CFG->prefix    = getenv_docker('MYSQL_PREFIX', 'mdl_');
$CFG->dbport    = getenv_docker('MYSQL_PORT', '5432');

$CFG->dboptions = array(
    'dbpersist' => false,
    'dbsocket'  => false,
    'dbport'    => getenv_docker('MYSQL_PORT', '5432'),
    'dbhandlesoptions' => false,
    'dbcollation' => 'utf8mb4_unicode_ci'
);


// Moodle's webroot and dataroot
$CFG->serverurl = getenv_docker('SERVERURL', 'http://moodle.local:80');
$CFG->wwwroot   = getenv_docker('WWWROOT', 'http://moodle.local:80');
$CFG->dataroot  = '/var/www/moodledata';
$CFG->dirroot   = '/var/www/html';
$CFG->themedir  = $CFG->dirroot . '/theme';

$CFG->admin = "admin";

// Moodle's cookie settings
$CFG->cookiepath    = '/var/www/moodledata/sessions/';
$CFG->cookiesecure  = false;
$CFG->cookiehttponly = true;

// Moodle language settings
// $CFG->lang = 'en';

// Security settings
$CFG->passwordsaltmain =  getenv_docker('SALT','geiTheiz4yo7tanaeyoo9KohwohdAeyuaxohp3hon3');

// Timezone settings
$CFG->timezone =  getenv_docker('MOODLE_TZ','America/Sao_Paulo');

// Proxy settings (optional)
// $CFG->proxyhost  = '';
// $CFG->proxyport  = 0;

// X-Sendfile settings (Nginx only)
$CFG->xsendfile = 'X-Accel-Redirect';
$CFG->xsendfilealiases = array(
    '/dataroot/' => $CFG->dataroot
);

// Debugging settings (not for production use)
@error_reporting(E_ALL | E_STRICT);
@ini_set('display_errors', '1');
$CFG->debug = (E_ALL | E_STRICT);
$CFG->debugdisplay = 1;


$CFG->phpunit_prefix =    getenv_docker('PHPU_MYSQL_PREFIX','phpu_');
$CFG->phpunit_dataroot =  '/var/www/phpu_moodledata';
$CFG->phpunit_dbtype    = 'mariadb';
$CFG->phpunit_dblibrary = 'native';
$CFG->phpunit_dbhost    = 'phpu_db';
$CFG->phpunit_dbname    = getenv_docker('PHPU_MYSQL_DATABASE','phpu');
$CFG->phpunit_dbuser    = getenv_docker('PHPU_MYSQL_USER','phpu');
$CFG->phpunit_dbpass    = getenv_docker('PHPU_MYSQL_PASSWORD','aecaathah9heiP');


// Include Moodle's setup function
require_once(__DIR__ . '/lib/setup.php');
