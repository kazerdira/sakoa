<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class AddChatFieldsToUsersTable extends Migration
{
    public function up()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('avatar')->nullable();
            $table->text('description')->nullable();
            $table->integer('type')->nullable();
            $table->string('token')->nullable();
            $table->string('access_token')->nullable();
            $table->integer('online')->default(1);
            $table->string('open_id')->nullable();
            $table->string('phone', 30)->nullable();
            $table->text('fcmtoken')->nullable();
            $table->timestamp('expire_date')->nullable();
        });
    }

    public function down()
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['avatar', 'description', 'type', 'token', 'access_token', 'online', 'open_id', 'phone', 'fcmtoken', 'expire_date']);
        });
    }
}
