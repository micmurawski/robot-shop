#!/bin/sh

# Convert cities CSV file to SQL

if [ -z "$1" ]
then
    echo "File required as first arg"
    exit 1
fi

# \x27 is a single quote
# \x60 is back tick
awk '
    BEGIN {
        FS=","
        format = "INSERT INTO cities(country_code, city, name, region, latitude, longitude) VALUES(\'\'%s\'\', \'\'%s\'\', \'\'%s\'\', \'\'%s\'\', %s, %s);\n"
        getline
    }
    {
      gsub(/\x27/, "\x60", $2)
      gsub(/\x27/, "\x60", $3)
      gsub(/\x27/, "\x60", $4)
      if(NF == 6) printf format, $1, $2, $3, $4, $5, $6
      else printf format, $1, $2, $3, $4, $4, $5
    }
    ' $1

