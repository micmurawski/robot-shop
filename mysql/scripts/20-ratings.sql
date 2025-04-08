CREATE DATABASE IF NOT EXISTS ratings
DEFAULT CHARACTER SET 'utf8';

USE ratings;

CREATE TABLE IF NOT EXISTS ratings (
    sku varchar(80) NOT NULL,
    avg_rating DECIMAL(3, 2) NOT NULL,
    rating_count INT NOT NULL,
    PRIMARY KEY (sku)
) ENGINE=InnoDB;

-- Create user and grant privileges using modern MySQL syntax
CREATE USER IF NOT EXISTS 'ratings'@'%' IDENTIFIED BY 'iloveit';
GRANT ALL PRIVILEGES ON ratings.* TO 'ratings'@'%';

