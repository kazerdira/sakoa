# 重新生成秘钥
php artisan key:generate
# 执行启动命令
php artisan serve
# 创建模型model （Article 为表名称）
php artisan make:model Models/Article
# 根据模型创建控制器（Article 为模型名称）
php artisan admin:make ArticleController --model=App\\Admin\\Models\\Article

#清除配置缓存
php artisan optimize:clear //Remove the cached bootstrap files
php artisan view:clear 
php artisan config:clear 
php artisan cache:clear  
php artisan route:clear 

####网站部署正式环境之前步骤：

>1.php artisan config:clear

>2.php artisan view:clear

>3.php artisan cache:clear

>4.php artisan optimize

>5.删除 bootstrap/cache 里面的文件

# 后台账户密码
账户 admin
密码 123456

