<?php
require_once __DIR__ . '/vendor/autoload.php';


use Adapterman\Adapterman;
use Workerman\Worker;
use Workerman\Timer;

Adapterman::init();

$http_worker                = new Worker('http://0.0.0.0:8080');
$http_worker->count         = (int) shell_exec('nproc') * 4;
$http_worker->reusePort     = true;
$http_worker->name          = 'AdapterMan-Laravel';
$http_worker->onWorkerStart = static function () {
    Header::$date = gmdate(DATE_RFC7231);
    Timer::add(1, function() {
         Header::$date = gmdate(DATE_RFC7231);
    });
    //init();
    require __DIR__.'/start.php';
};

$http_worker->onMessage = static function ($connection) {

    $connection->send(run());
};

Worker::runAll();

class Header {
     public static $date;
}