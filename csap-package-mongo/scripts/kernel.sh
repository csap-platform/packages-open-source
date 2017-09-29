#!/bin/bash


# https://docs.mongodb.com/manual/reference/ulimit/


#http://stackoverflow.com/questions/28911634/how-to-avoid-transparent-hugepage-defrag-warning-from-mongodb
#default is 65530
echo 2048000 > /proc/sys/vm/max_map_count
