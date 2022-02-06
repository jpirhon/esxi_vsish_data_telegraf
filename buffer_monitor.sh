#!/bin/sh
buffer_monitor(){
    fullpath=$1
    # Loop through the net-stats table, while getting all interfaces for "test-vm" and ouputting only specific data
    for row in $(net-stats -l | grep "test-vm" | awk '{print $1","$4","$6","$5}');
    do
        # Get all the parameters into variables
        vmName=$(echo $row|awk -F"," '{print $3}');
        portNum=$(echo $row|awk -F"," '{print $1}');
        switchName=$(echo $row|awk -F"," '{print $2}');
        macAddr=$(echo $row|awk -F"," '{print $4}');
        
        # Get the data from counters using the vsish commands and parsing the output data
        droppedRx=$(vsish -e cat /net/portsets/$switchName/ports/$portNum/clientStats | grep "droppedRx:" | awk -F":" '{print $2}');
        outOfBuf=$(vsish -e cat /net/portsets/$switchName/ports/$portNum/vmxnet3/rxSummary | grep "running out of buffers:" | awk -F":" '{print $2}');
        ring1Full=$(vsish -e cat /net/portsets/$switchName/ports/$portNum/vmxnet3/rxSummary | grep "1st ring is full:" | awk -F":" '{print $2}');
        ring2Full=$(vsish -e cat /net/portsets/$switchName/ports/$portNum/vmxnet3/rxSummary | grep "2nd ring is full:" | awk -F":" '{print $2}');
        burstDrop=$(vsish -e cat /net/portsets/$switchName/ports/$portNum/vmxnet3/rxSummary | grep "dropped by burst queue:" | awk -F":" '{print $2}');
        burstDelivered=$(vsish -e cat /net/portsets/$switchName/ports/$portNum/vmxnet3/rxSummary | grep "delivered by burst queue:" | awk -F":" '{print $2}');
    
        # Get current time
        time_now=$(date '+%Y-%m-%dT%H:%M:%SZ');

        # Output the parsed data to CSV
        echo vsish,$time_now,$vmName,$portNum,$macAddr,$droppedRx,$outOfBuf,$ring1Full,$ring2Full,$burstDrop,$burstDelivered >> $fullpath;
        echo -ne #
    done
}

# Take the output and vmfs name as parameters
output_file=$1
vmfs=$2

# Output the header row
echo measurement,time,vm,portnum,macaddress,droppedrx,runoutofbuf,1stringfull,2ndringfull,burstdrop,burstdelivered > /vmfs/volumes/$vmfs/buf_log/$output_file

# Run buffer_monitor function with whole output path as a parameter
buffer_monitor /vmfs/volumes/$vmfs/buf_log/$output_file;
