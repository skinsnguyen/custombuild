<?php
$session_name = 'SignonSession';
session_name($session_name);
session_start();

$logout_url = '';
if (isset($_SESSION['logout_url']))
        $logout_url = $_SESSION['logout_url'];

if (isset($_COOKIE[session_name()]))
	setcookie(session_name(), '', time()-3600, '/');

$_SESSION = array();
session_destroy();


if ($logout_url != '')
	header('Location: '.$logout_url);

echo "Logged Out";

exit(0);
?>
