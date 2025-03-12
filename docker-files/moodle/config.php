<?php  // Moodle configuration file

unset($CFG);  // Ignore this line
global $CFG;  // This is necessary here for PHPUnit execution
$CFG = new stdClass();

// Database settings
$CFG->dbtype    = getenv('MOODLE_DB_TYPE');  // Database type (e.g., "pgsql")
$CFG->dbhost    = getenv('MOODLE_DB_HOST');  // Database host (e.g., "db")
$CFG->dbname    = getenv('MOODLE_DB_NAME');  // Database name (e.g., "moodle")
$CFG->dbuser    = getenv('MOODLE_DB_USER');  // Database user (e.g., "moodleuser")
$CFG->dbpass    = getenv('MOODLE_DB_PASSWORD');  // Database password
$CFG->prefix    = getenv('MOODLE_DB_PREFIX');;  
$CFG->dboptions = array(
    'dbpersist' => false,
    'dbsocket'  => false,
    'dbport'    => '',
    'dbhandlesoptions' => false,
    'dbcollation' => 'utf8mb4_unicode_ci'
);

// Moodle's webroot and dataroot (set in environment variables)
$CFG->wwwroot   = getenv('MOODLE_WWWROOT');   // e.g., "http://localhost:8080"
$CFG->dataroot  = getenv('MOODLE_DATAROOT');  // e.g., "/var/www/html/moodledata"
$CFG->admin     = getenv('MOODLE_ADMIN');     // e.g., "admin"

// Moodle's cookie settings (optional, customize if needed)
$CFG->cookiepath   = '/';
$CFG->cookiesecure = false;  // Set to true if you are using https
$CFG->cookiehttponly = true;  // Helps mitigate XSS attacks

// Server settings
$CFG->serverurl   = getenv('MOODLE_WWWROOT');  // Same as wwwroot if using same URL
$CFG->wwwroot     = getenv('MOODLE_WWWROOT');
$CFG->dataroot    = getenv('MOODLE_DATAROOT');

// Moodle language settings (optional)
$CFG->lang        = 'en';  // Default language for Moodle

// Security settings - get password salt from environment variable
$CFG->passwordsaltmain = getenv('MOODLE_PASSWORD_SALT');  // Get salt from environment

// Moodle will automatically detect the PHP timezone setting, but you can also define it here:
$CFG->timezone   = getenv('MOODLE_TIMEZONE');  // You can change it to your preferred timezone, e.g., 'America/New_York'

// Proxy settings (optional)
$CFG->proxyhost  = '';
$CFG->proxyport  = 0;

// Include Moodle's setup function
require_once(__DIR__ . '/lib/setup.php');
