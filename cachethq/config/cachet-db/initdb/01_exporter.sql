-- Optional: create a dedicated MariaDB user for mysqld_exporter
-- Replace exporter_password before first init, or provision manually after boot.
CREATE USER IF NOT EXISTS 'exporter'@'%' IDENTIFIED BY 'exporter_password';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'%';
FLUSH PRIVILEGES;
