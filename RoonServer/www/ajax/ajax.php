<?php
defined('DOCROOT');
if ( basename(__FILE__) == basename($_SERVER["SCRIPT_FILENAME"]) ) {
    include_once("../__include.php");
    include_once("../__functions.php");
}
$strNoDir = 'etc';

if (isset($_GET['a'])) { $strVarAction = htmlentities($_GET['a']);}
if (isset($_GET['t'])) { $strVarTree = htmlentities($_GET['t']);}
if (isset($_GET['c'])) { $strModalContent = htmlentities($_GET['c']);}

$WEBSTATUS = '/tmp/web-status';

if ($strVarAction == 'gettree') {
    $arr = getFoldersAt($strVarTree);
    print $arr;
    flush();
    exit();
}

if ($strVarAction == 'checkHelperScript') {
    if (file_exists('/tmp/.RoonServer-webui.lock') or file_exists('/tmp/web-status')) {
        $running = true;
    } else { 
        $running = false;
    }

    header('Content-Type: application/json');
    if ($running) {
        echo json_encode(array(
            'success' => true
        ));
    } else {
        echo json_encode(array(
            'success' => false
        ));
    }

    return true;
}

if ($strVarAction == 'dbPathIsSet') {
    $roon_conf = (object) parse_ini_file('/usr/local/AppCentral/RoonServer/etc/RoonServer.conf', 1, INI_SCANNER_RAW);
    $roon_conf_object = json_decode(json_encode($roon_conf), FALSE);
    header('Content-Type: application/json');
    if (property_exists($roon_conf, 'DB_Path')) {
        echo json_encode(array(
            'success' => true
        ));
    } else {
        echo json_encode(array(
            'success' => false
        ));
    }
    return true;
}

if ($strVarAction == 'updateformfield') {
    set_db_path($strVarTree);
    flush();
    exit();
}

if ($strVarAction == 'redownload') {
    $bash_cmd = "echo redownload > $WEBSTATUS";
    $output = shell_exec($bash_cmd);
    return $output;
}

if ($strVarAction == 'downloadlogs') {
    $createLogDate = date('Ymd_His');
    $bash_cmd = "echo logs $createLogDate > $WEBSTATUS";
    $output = shell_exec($bash_cmd);
    echo json_encode(array(
        'success' => true,
        'logFile' => $createLogDate,
        'output' => $output
    ));
}

if ($strVarAction == 'startRoonServer') {
    $bash_cmd = "echo start > $WEBSTATUS";
    shell_exec($bash_cmd);
}

if ($strVarAction == 'restartRoonServer') {
    $bash_cmd = "echo restart > $WEBSTATUS";
    shell_exec($bash_cmd);
}
