# Keep learning project : AWS <!-- omit in toc -->
It is true that Cloud services are great tools and it can make your life easier as a devops engineer. I would like to understand the tools better and solve challanges in better way with it. AWS has lots of different services and releases new services and features continously. I made a resolution to keep learning AWS services by watching at least two re:invent youtube videos a week.

## Videos <!-- omit in toc -->
- [AWS re:Invent 2019: Building event-driven architectures w/ Amazon EventBridge](#aws-reinvent-2019-building-event-driven-architectures-w-amazon-eventbridge)
- [AWS re:Invent 2018: Become an IAM Policy Master in 60 Minutes or Less](#aws-reinvent-2018-become-an-iam-policy-master-in-60-minutes-or-less)

## AWS re:Invent 2019: Building event-driven architectures w/ Amazon EventBridge

### Event-driven benefits <!-- omit in toc -->
- Scale and fail independently
- Develope with agility
- Audit with ease
- Cut costs (when you use something like Lambda)

### Building Event-driven <!-- omit in toc -->

🤔Demo was quite interesting. Integration with EventBridge, Zendesk and amazon comprehend looked simple and helpful to manage negative costomer's reactions.\
🤔Schema Registry and Discovery is what we need.\
🤔Let's consider of seprating eventbus per domains. 

#### start with the domain <!-- omit in toc -->

> modeling applications themselves around the events that you need to handle so try to understand what the events that exists within the business context that you're trying to solve not just thinking about event from an infrastructure perspective.

😀The presenter introduced Event storming. 

#### pick an event router <!-- omit in toc -->

You should pick the right one in consideration of operational responsibility, event ordering, pricing and integration.

**Event ordering** \
Well-ordered: Kinesis Data Streams, Amazon MSK, Amazon MQ
No ordering: Amazon EventBridge, Amazon SNS

**Pricing** \
Amazon EventBridge: $1/M events \
Amazon Kinesis Data Streams: $0.015/shard hour & 0.014/M PUT payload units

 | Load                    | EventBridge | Kinesis |
 | :---------------------- | :---------: | ------: |
 | 1 TPS 100KB payloads    |     $3      |    $ 11 |
 | 40 TPS 100KB payloads   |    $105     |     $50 |
 | 1,000 TPS 5 KB payloads |     $50     |     $92 |

**Integration** 

event source
- AWS services
- SaaS apps
- custom apps

Lambda, AWS step functions => business process

Amazon EventBridge - Amazon Cloudwatch logs => operational logging

Amazon Kinesis Data Firehose - Amazon S3 bucket - Amazon Athena => archive and analytics

### how many custom event buses should I have? <!-- omit in toc -->

- Avoid routing in the producer
- Event bus domain alignment

**Create rules inside consumers**

### Structuring events <!-- omit in toc -->

**events vs full state descriptions** \
you should make sure whether consumers need to know the latest status before acting on the event. Delivery of events can be delayed or failed by errors. You also need to understand how many consumers need to query to get detail from events.

### managing event types <!-- omit in toc -->

Schema Registry and Discovery

## AWS re:Invent 2018: Become an IAM Policy Master in 60 Minutes or Less

🤔I can let each team leader assign policy to their team members with a permission boundaries and tag-based access control. 

- AWS Organizations(Service control policies), IAM(Permission policies and Permission boundaries), AWS STS(Scoped-down policies), Specific AWS services(Resource-based policies), VPC endpoints(Endpoint Policies) 
- **within an account**: Service control policies AND (IAM policies OR Resource-based policies) 
**across accounts**: Service control policies AND (IAM policies AND Resource-based policies)
- **Organization units**: You can use organizational units (OUs) to group accounts together to administer as a single unit. This greatly simplifies the management of your accounts. For example, you can attach a policy-based control to an OU, and all accounts within the OU automatically inherit the policy. You can create multiple OUs within a single organization, and you can create OUs within other OUs. Each OU can contain multiple accounts, and you can move accounts from one OU to another. 

### Permission bundaries <!-- omit in toc -->

create a region restricted policy \
arn:aws:iam:xxxxxxxxxxxx:policy/region-restriction
```
{
    "Effect": "Allow",
    "Action": [
        "secretmanager:*",
        "lambda:*",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
    ],
    "Resource": "*",
    "Condition": {
        "StringEquals": {
            "aws:RequestedRegion": [
                "us-west-1",
                "us-west-2"
            ]
        }
    }
}
```

create a policy to allow developers to create roles only with specific prefix name.
```
{
    "Effect": "Allow",
    "Action": [
        "iam:CreatePolicy",
        "iam:CreatePolicyVersion",
        "iam:DeletePolicyVersion"
    ],
    "Resource": "arn:aws:iam::xxxxxxxxxxxx:policy/project-a-*"
}
```

set a permission boundary condition to allow developers to manage policies in the boundary.
```
{
    "Effect": "Allow",
    "Action": [
        "iam:DetachRolePolicy",
        "iam:CreateRole",
        "iam:AttachRolePolicy"
    ],
    "Resource": "arn:aws:iam::xxxxxxxxxxxx:role/project-a-*",
    "Condition": {
        "StringEquals": {
            "iam:permissionBoundary": "arn:aws:iam:xxxxxxxxxxxx:policy/region-restriction"
        }
    }
}
```

### tag-based access control <!-- omit in toc -->

create a region restricted policy for developers
```
{
    "Effect": "Allow",
    "Action": [
        "ec2:RunInstances"
    ],
    "Resource": [
        "arn:aws:ec2:*:*:subnet/*",
        "arn:aws:ec2:*:*:key-pair/*",
        ...
    ],
    "Condition": {
        "StringEquals": {
            "aws:RequestedRegion": [
                "us-west-1",
                "us-west-2"
            ]
        }
    }
}
```

Allow for creation of tags when creating new resources
```
{
    "Effect": "Allow",
    "Action": "ec2:CreateTags",
    "Resource": "*",
    "Condition": {
        "StringEquals": {
            "ec2:CreateAction": "RunInstances"
        }
    }
}
```

force to set specific tags when developers create new resources
```
{
    "Effect": "Allow",
    "Action": "ec2:RunInstances",
    "Resource": "arn:aws:ec2:*:*:instance/*",
    "Condition": {
        "ForAllValues:StringEquals": {
            "aws:TagKeys": ["project", "name"]
        },
        "StringEquals": {
            "aws:RequestTag/project": ["dorky"],
            "aws:RequestedRegion": ["us-west-1", "us-west-2"]
        }
    }
}
```

control which existing resources and values developers can tag
```
{
    "Effect": "Allow",
    "Action": "ec2:CreateTags",
    "Resource": "*",
    "Condition": {
        "StringEquals": {
            "ec2:ResourceTag/project": ["dorky"]
        },
        "ForAllValues:StringEquals": {
            "aws:TagKeys": ["project", "name"]
        },
        "StringEqualsIfExists": {
            "aws:RequestTag/project": ["dorky"]
        }
    }
}
```

Control resources users can manage based on tag values
```
{
    "Effect": "Allow",
    "Action": [
        "ec2:StartInstances",
        "ec2:StopInstances"
    ],
    "Resource": "*",
    "Condition": {
        "StringEquals": {
            "aws:ResourceTag/project": "dorky"
        }
    }
}
```

#### you can tag IAM users and roles <!-- omit in toc -->

You can tag IAM users for the project and change policies `"aws:RequestTag/project": ["dorky"]` to `"aws:RequestTag/project": ["${aws:PrincipalTag/project}"]!

