# aws-cw2table
Get cloudwatch stats write to csv file

# Usage

Download script then execute command below:

    chmod -x aws-cw2table.sh
    ./aws-cw2table.sh AWSprofileName
   
Parse argument AWSprofileName to your AWS Profile name (in this case switch role)

# How it works
1.Script get all EC2 instance profile from argument 1 write to xxx.txt file

2.Loop run aws cloudwatch get-metric-statistics from CW_CUSTOM_NAMESPACE and get some metrics from default name space AWS/EC2
and write to xxx.csv file

# Noted
Get metrics 30 days ago and period 86400 (1 month) = respond result = 1 data point

# Example CSV result
![image](https://user-images.githubusercontent.com/37788058/219356565-f4b8cffe-74bc-45ca-b9f5-c9e2993fbab5.png)
