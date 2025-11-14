<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

// Test route - no authentication needed
Route::get('/hello', function() {
    return response()->json([
        'message' => 'Hello World from Laravel!',
        'status' => 'success',
        'timestamp' => now()
    ]);
});

Route::group(['namespace' => 'Api'], function(){
   
    Route::any('/login','LoginController@login');
    Route::any('/get_profile','LoginController@get_profile')->middleware('UserCheck');
    Route::any('/update_profile','LoginController@update_profile')->middleware('UserCheck');
    Route::any('/bind_fcmtoken','LoginController@bind_fcmtoken')->middleware('UserCheck');
    Route::any('/contact','LoginController@contact')->middleware('UserCheck');
    Route::any('/upload_photo','LoginController@upload_photo')->middleware('UserCheck');
    Route::any('/send_notice','LoginController@send_notice')->middleware('UserCheck');
    Route::any('/send_contact_request_notification','LoginController@send_contact_request_notification')->middleware('UserCheck');
    Route::any('/send_contact_accepted_notification','LoginController@send_contact_accepted_notification')->middleware('UserCheck');
    Route::any('/get_rtc_token','AccessTokenController@get_rtc_token')->middleware('UserCheck');
    Route::any('/send_notice_test','LoginController@send_notice_test'); 
 
});
