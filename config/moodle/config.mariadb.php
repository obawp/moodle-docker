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

// $CFG->block_configurable_reports_enable_sql_execution = 0;

// Database settings
$CFG->dbtype    =  'mariadb';
$CFG->dblibrary =  'native';
// $CFG->dbhost    = 'db';
$CFG->dbhost    = getenv_docker('MARIADB_HOST', 'db');
$CFG->dbname    = getenv_docker('MARIADB_DATABASE', 'moodle');
$CFG->dbuser    = getenv_docker('MARIADB_USER', 'moodleuser');
$CFG->dbpass    = getenv_docker('MARIADB_PASSWORD', 'meeF9av3geegh9');
$CFG->prefix    = getenv_docker('MARIADB_PREFIX', 'mdl_');
$CFG->dbport    = getenv_docker('MARIADB_PORT', '3306');


// $CFG->dboptions = array(
//     'dbpersist' => false,
//     'dbsocket'  => false,
//     'dbport'    => $CFG->dbport,
//     'dbhandlesoptions' => false,
//     'dbcollation' => 'utf8mb4_unicode_ci'
// );
$CFG->dboptions = array(
    'dbcollation' => 'utf8mb4_unicode_ci',
    'dbpersist' => false,
    'dbsocket'  => false,
    'dbport'    => $CFG->dbport,
    'dbhandlesoptions' => false,
    // 'readonly' => array(
    //     'instance' => [
    //         // [
    //         //     'dbhost' => 'db_slave',
    //         //     'dbname' => $CFG->dbname,
    //         //     'dbuser' => $CFG->dbuser,
    //         //     'dbpass' => $CFG->dbpass,
    //         //     'prefix' => $CFG->prefix,
    //         //     'dbport' => $CFG->dbport,
    //         // ]
    //     ]
    // ),
    'readonlyrandom' => true,
    'readonlyrole' => null,
    'connecttimeout' => 2,
);


// Moodle's webroot and dataroot
$CFG->serverurl = getenv_docker('SERVERURL', 'https://moodle.local'). ':'.getenv_docker('WEBS_PORT', '443');
$CFG->wwwroot   = getenv_docker('WWWROOT', 'https://moodle.local'). ':'.getenv_docker('WEBS_PORT', '443');
$CFG->dataroot  = '/var/www/moodledata';
$CFG->dirroot   = '/var/www/html';
$CFG->themedir  = $CFG->dirroot . '/theme';
$CFG->directorypermissions = 02770;

// When not configured on the web server it must be accessed via https://example.com/moodle/r.php
// When configured the on the web server the 'r.php' may be removed.
$CFG->routerconfigured = false; 

$CFG->admin = "admin";

// Moodle's cookie settings
$CFG->cookiepath    = $CFG->dataroot .'/sessions/';
$CFG->cookiesecure  = false;
$CFG->cookiehttponly = true;
// $CFG->cookiehttponly = false;
$CFG->slasharguments = true; // if PATH_INFO is not enabled
$CFG->overridetossl = false;
// define('CACHE_DISABLE_ALL', true);

// Moodle language settings
// $CFG->lang = 'en';

// Security settings
$CFG->passwordsaltmain =  getenv_docker('SALT','geiTheiz4yo7tanaeyoo9KohwohdAeyuaxohp3hon3');

// Timezone settings
$CFG->timezone =  getenv_docker('TZ','America/Sao_Paulo');
// $CFG->timezone = 'America/Sao_Paulo';
// Proxy settings (optional)
// $CFG->proxyhost  = '';
// $CFG->proxyport  = 0;

$webserver = getenv_docker('WEBSERVER', false);
if($webserver == 'nginx'){	
	// X-Sendfile settings (Nginx only)
	$CFG->xsendfile = 'X-Accel-Redirect';
	$CFG->xsendfilealiases = array(
		'/dataroot/' => $CFG->dataroot
	);
}

// Debugging settings (not for production use)
$debug = getenv_docker('FORCE_DEBUG', false);
if($debug == 'true'){	
	@error_reporting(E_ALL | E_STRICT);
	@ini_set('display_errors', '1');
	$CFG->debug = (E_ALL | E_STRICT);
	$CFG->debugdisplay = 1;
}

$phpu_enabled = getenv_docker('PHPUNIT_ENABLED', false);
if($phpu_enabled == 'true'){	
	$CFG->phpunit_prefix =    getenv_docker('PHPU_MARIADB_PREFIX','phpu_');
	$CFG->phpunit_dataroot =  '/var/www/phpu_moodledata';
	$CFG->phpunit_dbtype    = 'mariadb';
	$CFG->phpunit_dblibrary = 'native';
	$CFG->phpunit_dbhost    = 'db_phpunit';
	$CFG->phpunit_dbname    = getenv_docker('PHPU_MARIADB_DATABASE','phpu');
	$CFG->phpunit_dbuser    = getenv_docker('PHPU_MARIADB_USER','phpu');
	$CFG->phpunit_dbpass    = getenv_docker('PHPU_MARIADB_PASSWORD','aecaathah9heiP');
}


// Include Moodle's setup function
require_once(__DIR__ . '/lib/setup.php');
