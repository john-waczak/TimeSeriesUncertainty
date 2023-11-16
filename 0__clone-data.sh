# base_path=/scratch/jwaczak/data

base_path=/media/jwaczak/Data


rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_1 $base_path/aq-data/raw/IPS7100/Central_Hub_1 --include "*IPS7100*.csv" -P
rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_1 $base_path/aq-data/raw/BME680/Central_Hub_1 --include "*BME680*.csv" -P
rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_1 $base_path/aq-data/raw/BME280/Central_Hub_1 --include "*BME280*.csv" -P

rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_10 $base_path/aq-data/raw/IPS7100/Central_Hub_10 --include "*IPS7100*.csv" -P
rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_10 $base_path/aq-data/raw/BME680/Central_Hub_10 --include "*BME680*.csv" -P
rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_10 $base_path/aq-data/raw/BME280/Central_Hub_10 --include "*BME280*.csv" -P

rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_2 $base_path/aq-data/raw/IPS7100/Central_Hub_2 --include "*IPS7100*.csv" -P
rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_2 $base_path/aq-data/raw/BME680/Central_Hub_2 --include "*BME680*.csv" -P
rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_2 $base_path/aq-data/raw/BME280/Central_Hub_2 --include "*BME280*.csv" -P

rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_4 $base_path/aq-data/raw/IPS7100/Central_Hub_4 --include "*IPS7100*.csv" -P
rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_4 $base_path/aq-data/raw/BME680/Central_Hub_4 --include "*BME680*.csv" -P
rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_4 $base_path/aq-data/raw/BME280/Central_Hub_4 --include "*BME280*.csv" -P

rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_8 $base_path/aq-data/raw/IPS7100/Central_Hub_8 --include "*IPS7100*.csv" -P
rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_8 $base_path/aq-data/raw/BME680/Central_Hub_8 --include "*BME680*.csv" -P
rclone copyto OSN:ees230012-bucket01/AirQualityNetwork/data/raw/Central_Hub_8 $base_path/aq-data/raw/BME280/Central_Hub_8 --include "*BME280*.csv" -P


