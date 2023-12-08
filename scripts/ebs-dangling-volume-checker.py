# This is a lambda handler which we use to monitor for dangling ebs volumes (created when sts PVCs
# are deleted). It's not deployed through automation yet, just pasted into lambda :)
import boto3
import os

def check_volumes(region_name):
    ec2 = boto3.client('ec2', region_name=region_name)
    print(f"Querying available volumes in {region_name}")
    response = ec2.describe_volumes(Filters=[{'Name': 'status', 'Values': ['available']}])

    available_volumes = response['Volumes']
    print(f"Found {len(available_volumes)} available volumes in {region_name}. Writing to cloudwatch...")
    if not available_volumes:
        return

    cloudwatch = boto3.client('cloudwatch', region_name=region_name)

    volume_ids = []
    for v in available_volumes:
        volume_ids.append(v['VolumeId'])

    cloudwatch.put_metric_data(
        Namespace='FI/EBS',
        MetricData=[
            {
                'MetricName': 'AvailableVolumes',
                'Dimensions': [
                    {
                        'Name': 'VolumeId',
                        'Value': vid
                    }
                    # Region dimension can be added if we publish in a central
                    # cloudwatch for all regions
                    # {
                    #     'Name': 'Region',
                    #     'Value': region_name
                    # },
                ],
                'Value': 1,
                'Unit': 'Count'
            }
            for vid in volume_ids
        ]
    )

def lambda_handler(event, context):
    regions = os.environ.get("PL_REGIONS")
    if regions:
        regions.replace(" ", "").split(",")
    else:
        regions = ['us-east-1', 'ap-southeast-1']

    for region in regions:
        check_volumes(region)
