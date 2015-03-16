#!/usr/bin/php
<?php
/**
 * @file
 * TODO: this does not work, needs to be rechecked again the docker setup.
 * Reads folder names for sites that are in /var/www/html
 * and passes branch and build id strings to the
 * site-destroy script which deletes all files and databases.
 */
$urlPrefixParam = (isset($argv[1])) ? $argv[1] : NULL;
$dir = '/var/www/html';
$files = scandir($dir);

foreach ($files as $file) {

    // Looks for folders 
    $pieces = explode('.', $file);
    if ('nz' == end($pieces)) {

        // Reset pointer to first item in array
        reset($pieces);
        $siteInfo = explode('-', current($pieces));

        $branch = $siteInfo[0];
        $buildId = $siteInfo[2];

        // Determine whether the current site needs to be deleted.
        $proceed = FALSE;
        $urlPrefix = $urlPrefixParam;

        if (!$urlPrefixParam) {
            $urlPrefix = $pieces[1];
            $proceed = TRUE;
        }
        elseif ($urlPrefixParam == $pieces[1]) {
            $proceed = TRUE;
        }

        if ($proceed) {
            $cmd = __DIR__ . '/site-destroy.sh ' . $branch . ' ' . $buildId . ' ' . $urlPrefix;
            echo $cmd . "\n";
            $output = shell_exec($cmd);
            echo $output;
        }
    }

}
