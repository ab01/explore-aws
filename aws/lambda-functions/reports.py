import boto3

#region_list = ['eu-west-1', 'eu-central-1', 'us-east-1', 'us-west-1', 'us-west-2', 'ap-southeast-1', 'ap-southeast-2', 'ap-northeast-1', 'sa-east-1']
region_list = ['us-east-1']
owner_id = 'XXXXXXXXXXX'

# import boto3
# client = boto3.client('s3')
# response = client.put_object(Bucket='gameofchess',  Key='reports/report.html')
DataList={}


def send_report():

    client = boto3.client('ses', region_name='us-east-1') #Choose which region you want to use SES
    response = client.send_email(
        Source='XXXXXXXXXX@gmail.com',
        Destination={
            'ToAddresses':  ['XXXXXXXXX@gmail.com'
            ]
        },
        Message={
            'Subject': {
            'Data': 'Testing'
        },
        'Body': {
            'Text': {
                'Data': str(DataList)
            }
        }

        }
    )



def save_cost():
    for region in region_list:
        
        #EIP
        client = boto3.client('ec2', region_name=region)
        response = client.describe_addresses()
        eips=[]
        for address in response['Addresses']:
            if 'InstanceId' not in address:
                eips.append(address['PublicIp'])
        print ("eip-", eips)

        #Volumes
        response=client.describe_volumes()

        volumes = []
        for volume in response['Volumes']:
            if len(volume['Attachments']) == 0:
                volume_dict = {}
                volume_dict['VolumeId'] = volume['VolumeId']
                volume_dict['VolumeType'] = volume['VolumeType']
                volume_dict['VolumeSize'] = volume['Size']
                volumes.append(volume_dict)
        print ("Volumes-", volumes)

        #Snapshots
        response = client.describe_snapshots(OwnerIds=[owner_id])
        snapshots=[]
        for snapshot in response['Snapshots']:
            if 'ami' not in snapshot['Description']:
                snapshots.append(snapshot['SnapshotId'])

        print ("Snapshot-", snapshots )



        #Securit Groups
        response = client.describe_security_groups()
        all_sec_groups = []
        for SecGrp in response['SecurityGroups']:
            all_sec_groups.append(SecGrp['GroupName'])


        sec_groups_in_use = []
        response = client.describe_instances(
            Filters=[
                {
                    'Name': 'instance-state-name',
                    'Values': ['running', 'stopped']
                }
            ])

        for r in response['Reservations']:
            for inst in r['Instances']:
                if inst['SecurityGroups'][0]['GroupName'] not in sec_groups_in_use:
                    sec_groups_in_use.append(inst['SecurityGroups'][0]['GroupName'])

        unused_sec_groups = []

        for groups in all_sec_groups:
            if groups not in sec_groups_in_use:
                unused_sec_groups.append(groups)
        print ("unused_sec_groups-", unused_sec_groups)



        #ELB
        client = boto3.client('elb', region_name=region)
        response = client.describe_load_balancers()
        elbs=[]
        for ELB in response['LoadBalancerDescriptions']:
            if len(ELB['Instances']) == 0:
                elbs.append(ELB['LoadBalancerName'])

        print ("elbs-", elbs)
        value = str(volumes)+'\n'+str(unused_sec_groups)
        DataList[region] = value
    print ("DataDict-", DataList)


    #     #Autoscaling
    #     client = boto3.client('autoscaling', region_name=region)
    #     response = client.describe_launch_configurations()
    #     LC_list=[]
    #     for LC in response['LaunchConfigurations']:
    #         LC_name = LC['LaunchConfigurationName']
    #         LC_list.append(LC_name)
    #     response1 = client.describe_auto_scaling_groups()
    #     for ASG in response1['AutoScalingGroups']:
    #         if ASG['LaunchConfigurationName'] in LC_list:
    #                 LC_list.remove(ASG['LaunchConfigurationName'])
    #     LCs=[]
    #     for LC in LC_list:
    #         LCs.append(LC)

    #     if len(LCs) > 0:
    #         append('<br><table><caption>Unused Launch Configurations</caption><th>Resource</th><th>LC Name</th>')
    #         for lc in LCs:
    #             append('<tr><td>LC</td><td>'+lc+'</td></tr>')
    #     append('</table>')

    #     response = client.describe_auto_scaling_groups()
    #     ASGs=[]
    #     for ASG in response['AutoScalingGroups']:
    #         if ASG['DesiredCapacity'] == 0:
    #             ASGs.append(ASG['AutoScalingGroupName'])

    #     if len(ASGs) > 0:
    #         append('<br><table><caption>Unused Auto Scaling Groups</caption><th>Resource</th><th>ASG Name</th>')
    #         for asg in ASGs:
    #             append('<tr><td>ASG</td><td>'+asg+'</td></tr>')
    #     append('</table>')

    # html = """\
    #           </body>
    #           </html>
    #           """
    # with open(filename, "a") as f:
    #     f.write(html+'\n')
    #     f.close()

def lambda_handler(event, context):
    # TODO implement
    save_cost()
    send_report()
    return 'Hello from Lambda'
    
if __name__ == "__main__":
    try:
        lambda_handler(event, context)
        
    except Exception as err:
        print(err)


