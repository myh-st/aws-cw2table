#!/bin/bash

# Enable debug mode
# set -x

if [ $# -ne 1 ]; then
  echo "Usage: aws-cw2table.sh AWSprofileName "
  echo "./aws-cw2table.sh AWSprofileName"
  exit 1
fi

AWS_PROFILE=$1
FILENAME="$AWS_PROFILE-ec2list.txt"
OUTPUT_FILE="$AWS_PROFILE-metrics.csv"
CW_CUSTOM_NAMESPACE="CWAgent"

aws ec2 describe-instances --profile $AWS_PROFILE --query 'Reservations[*].Instances[*].[InstanceId]' --output text > $FILENAME

#Write Header to a CSV file
echo "instanceState,instanceName,%CPUUtilization,%MemUsed,DiskUsed/GB,DiskFree/GB,DiskTotal/GB,NetworkIn/Bytes,NetworkOut/Bytes" > $OUTPUT_FILE

while read -r line
do

# Set the instance ID and output file name
INSTANCE_ID="$line"
echo $INSTANCE_ID

# Get the average CPU utilization for the instance over the past 30 Days
CPU_UTILIZATION=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 86400 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
    | grep -i average \
    | cut -f2 -d":" \
    | tr -d -c .0-9 \
    | cut -b 1-5)

# Get the average Memory used percent for the instance over the past 30 Days
MEM_USED=$(aws cloudwatch get-metric-statistics \
    --namespace $CW_CUSTOM_NAMESPACE \
    --metric-name mem_used_percent \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 86400 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
    | grep -i average \
    | cut -f2 -d":" \
    | tr -d -c .0-9 \
    | cut -b 1-5)

# Get the average Disk used for the instance over the past 30 Days
DISK_USED=$(aws cloudwatch get-metric-statistics \
    --namespace $CW_CUSTOM_NAMESPACE \
    --metric-name disk_used \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 86400 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
    | grep -i average \
    | cut -f2 -d":" \
    | head -n 1 \
    | tr -d -c .0-9)

# Get the average Disk Free for the instance over the past 30 Days
DISK_FREE=$(aws cloudwatch get-metric-statistics \
    --namespace $CW_CUSTOM_NAMESPACE \
    --metric-name disk_free \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 86400 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
    | grep -i average \
    | cut -f2 -d":" \
    | head -n 1 \
    | tr -d -c .0-9)

# Get the average Disk total for the instance over the past 30 Days
DISK_TOTAL=$(aws cloudwatch get-metric-statistics \
    --namespace $CW_CUSTOM_NAMESPACE \
    --metric-name disk_total \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 86400 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
    | grep -i average \
    | cut -f2 -d":" \
    | head -n 1 \
    | tr -d -c .0-9)

# Get the average NetworkIn for the instance over the past 30 Days
NETWORK_IN=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name NetworkIn \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 86400 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
    | grep -i average \
    | cut -f2 -d":" \
    | head -n 1 \
    | tr -d -c .0-9)

# Get the average NetworkOut for the instance over the past 30 Days
NETWORK_OUT=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name NetworkOut \
    --start-time $(date -u -d '30 day ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 86400 \
    --statistics Average \
    --dimensions Name=InstanceId,Value=$INSTANCE_ID \
    --profile $AWS_PROFILE \
    | grep -i average \
    | cut -f2 -d":" \
    | head -n 1 \
    | tr -d -c .0-9)

# Get the instance name
INSTANCE_NAME=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value, State.Name]" \
    --profile $AWS_PROFILE \
    --output text \
    | tr '\n' ',')

# Get EC2 instances with name and status
# INSTANCE_STATE=$(aws ec2 describe-instances \
#     --query "Reservations[*].Instances[*].[State.Name]" \
#     --profile ${AWS_PROFILE} \
#     --output text)

# Convert bytes to gigabytes
DISK_USED_GB=$(echo "scale=2; $DISK_USED/1024/1024/1024" | bc)
DISK_FREE_GB=$(echo "scale=2; $DISK_FREE/1024/1024/1024" | bc)
DISK_TOTAL_GB=$(echo "scale=2; $DISK_TOTAL/1024/1024/1024" | bc)

# Write the results to a CSV file
echo "${INSTANCE_NAME%?},$CPU_UTILIZATION,$MEM_USED,$DISK_USED_GB,$DISK_FREE_GB,$DISK_TOTAL_GB,$NETWORK_IN,$NETWORK_OUT" >> $OUTPUT_FILE

# Print a message indicating the results were written to the file
echo "Metrics for instance $INSTANCE_ID ($INSTANCE_NAME) written to $OUTPUT_FILE"

done < "$FILENAME"

# Write Header to a CSV file
# sed -i '1i instanceState,instanceName,%CPUUtilization,%MemUsed,DiskUsed/GB,DiskFree/GB,DiskTotal/GB,NetworkIn/Bytes,NetworkOut/Bytes' $OUTPUT_FILE
