<?php
//VERSION=0.5
//https://docs.phpmyadmin.net/en/latest/setup.html#signon-authentication-mode
/* vim: set expandtab sw=4 ts=4 sts=4: */
/**
 * Single signon for phpMyAdmin
 *
 * This is just example how to use session based single signon with
 * phpMyAdmin, it is not intended to be perfect code and look, only
 * shows how you can integrate this functionality in your application.
 *
 * @package    PhpMyAdmin
 * @subpackage Example
 */
declare(strict_types=1);

/* Use cookies for session */
ini_set('session.use_cookies', 'true');
/* Change this to true if using phpMyAdmin over https */
$secure_cookie = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] == 'on');
/* Need to have cookie visible from parent directory */
session_set_cookie_params(0, '/', '', $secure_cookie, true);
/* Create signon session */
$session_name = 'SignonSession';
session_name($session_name);
// Uncomment and change the following line to match your $cfg['SessionSavePath']
//session_save_path('/foobar');
@session_start();


if (isset($_POST['token']) || isset($_GET['token']))
{
	$info = get_token_info();

	$user = $info['username'];
	$pass = $info['password'];
	$host = 'localhost';
	$port = '3306';

	/* Store there credentials */
	$_SESSION['PMA_single_signon_user'] = $user;
	$_SESSION['PMA_single_signon_password'] = $pass;
	$_SESSION['PMA_single_signon_host'] = $host;
	$_SESSION['PMA_single_signon_port'] = $port;

	$logout_url = NULL;

	if (isset($_POST['logout_url']) && $_POST['logout_url'] != '')
		$logout_url = $_POST['logout_url'];
	else
	if (isset($_GET['logout_url']) && $_GET['logout_url'] != '')
		$logout_url = $_GET['logout_url'];

	if ($logout_url != NULL && filter_var($logout_url, FILTER_VALIDATE_URL))
		$_SESSION['logout_url'] = $logout_url;

	/* Update another field of server configuration */
	$_SESSION['PMA_single_signon_cfgupdate'] = ['verbose' => 'DA PMA Signon'];
	$id = session_id();

	/* Close that session */
	@session_write_close();

	/* Redirect to phpMyAdmin (should use absolute URL here!) */
	 header('Location: ../index.php');
}

//***************************
// FUNCTIONS

function die_error($str) {
	die($str);
}
function die_rm($str, $file) {
	unlink($file);
	die_error($str);
}
function get_token_info() {
	if (!isset($_POST['token']) && !isset($_GET['token']))
		die_error('Missing token');

	if (isset($_POST['token']))
		$token = $_POST['token'];
	else
		$token = $_GET['token'];
	if (!valid_token($token))
		die_error('Invalid token');

	$dir = dirname($_SERVER['SCRIPT_FILENAME']);
	$token_file = $dir.'/tokens/'.$token;
	if (!file_exists($token_file))
		die_error("Cannot find token file '$token_file'");
	$file_data = parse_ini_file($token_file, false, INI_SCANNER_RAW);
	if ($file_data === false)
		die_rm("parse_ini_file error", $token_file);

	//ensure you're you.
	if (!filter_var($file_data['ip'], FILTER_VALIDATE_IP))
		die_rm("invalid token IP", $token_file);

	//allow only 10 seconds to use the token.
	if ($file_data['created'] + 10 < time())
		die_rm("token has expired", $token_file);
	//delete token_file
	unlink($token_file);
	$info = array();
	$info['username'] = base64_decode($file_data['username']);
	$info['password'] = base64_decode($file_data['password']);
	return $info;
}
function valid_token($t) {
	$len = strlen($t);
	if ($len > 128) return false;
	if ($len < 100) return false;
	return preg_match("/^([a-zA-Z0-9])+$/", $t);
}
?>
