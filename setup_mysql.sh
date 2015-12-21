#!/bin/bash

pkgs=(
        'libncursesw5-dev'
        'mysql-client'
        'cmake'
        'libnagios-plugin-perl'
        'g++'
        'libncurses5-dev'
        'bison'
)

mysql_dir_name='mysql-5.7.9'
mysql_dl_file=$mysql_dir_name'.tar.gz'
mysql_dl_url='http://dev.mysql.com/get/Downloads/MySQL-5.7/'$mysql_dl_file'/from/http://ftp.iij.ad.jp/pub/db/mysql/'
mysql_src_path='/usr/local/src'
mysql_install_path='/usr/local/mysql'

db_user=''
db_name=''

if [ "$#" -eq "0" ];then
  echo "usage: $0 --init"
  exit 0
fi

if [ "$1" = '--init' ]; then
  for (( i=0; i<${#pkgs[@]}; i++ ))
  do
    apt-get -y install ${pkgs[$i]}
  done

  # ここにmy.cnfがあると設定がうまくいかないので削除
  rm /etc/mysql/my.cnf

  wget $mysql_dl_url -O $mysql_src_path/$mysql_dl_file
  cd $mysql_src_path
  tar xfz $mysql_src_path/$mysql_dl_file
  cd $mysql_dir_name
  cmake -DCMAKE_INSTALL_PREFIX=$mysql_install_path -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_INNOBASE_STORAGE_ENGINE=1 -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/tmp/boost
  make
  make install
        
  if [ $? -ne 0 ];then
    echo "Install failed!!"
    exit 1
  fi

  # add unix user
  useradd mysql -s /bin/false
  chown -R mysql:mysql $mysql_install_path

  cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
  chmod 744 /etc/init.d/mysqld
  $mysql_install_path/bin/mysqld --datadir=/usr/local/mysql/data --basedir=/usr/local/mysql --user=mysql --log-error-verbosity=3 --initialize-insecure

  # 自動起動登録
  systemctl enable mysql
  systemctl start mysql

fi
