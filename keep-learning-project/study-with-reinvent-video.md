# Keep learning project : AWS <!-- omit in toc -->
It is true that Cloud services are great tools and they can make your life easier as a devops engineer. I would like to understand the tools better and solve challanges efficiently with the tools. AWS has lots of different services and releases new services and features continously. I made a resolution to keep learning AWS services by watching at least two re:invent youtube videos a week.

## Videos <!-- omit in toc -->
- [AWS re:Invent 2019: Whatʼs new with Amazon ElastiCache](#aws-reinvent-2019-what%ca%bcs-new-with-amazon-elasticache)
- [AWS re:Invent 2019: Performing chaos engineering in a serverless world](#aws-reinvent-2019-performing-chaos-engineering-in-a-serverless-world)
- [AWS re:Invent 2019: What's new in Amazon Aurora](#aws-reinvent-2019-whats-new-in-amazon-aurora)
- [AWS re:Invent 2019: Deep Dive on Amazon Aurora with MySQL Compatibility](#aws-reinvent-2019-deep-dive-on-amazon-aurora-with-mysql-compatibility)
- [AWS re:Invent 2019: Amazon Aurora storage demystified: How it all works](#aws-reinvent-2019-amazon-aurora-storage-demystified-how-it-all-works)
- [AWS re:Invent 2019: What's new in AWS CloudFormation](#aws-reinvent-2019-whats-new-in-aws-cloudformation)
- [AWS re:Invent 2019: Building event-driven architectures w/ Amazon EventBridge](#aws-reinvent-2019-building-event-driven-architectures-w-amazon-eventbridge)
- [AWS re:Invent 2018: Become an IAM Policy Master in 60 Minutes or Less](#aws-reinvent-2018-become-an-iam-policy-master-in-60-minutes-or-less)

---

## [AWS re:Invent 2019: Whatʼs new with Amazon ElastiCache](https://youtu.be/SaGW_Bln3qA)

🙃AWS launched [reader endpoint](https://aws.amazon.com/about-aws/whats-new/2019/06/amazon-elasticache-launches-reader-endpoint-for-redis/) in June

### Performance <!-- omit in toc -->

Vanila R4 < Vanila R5(Nitro system) < Tuned R5 < Tuned R5 with enhanced I/O

#### M5 and R5 optimized instances <!-- omit in toc -->

#### Enhanced I/O <!-- omit in toc -->

Redis has single thread architecture
- Simplicity
- No race conditions, no synchronizations
- Easy to understand and extend
- Easy to support rich functionality
- Share-nothing architecture - scale by sharding
- Improves cache coherency

seventy percent of time is spent in the IO layer and communications!

socket communication on separate threads -> enhanced I/O

#### T3 support <!-- omit in toc -->

Ideal for entry-level, small, and medium Amazon ElastiCache workloads that may also experience temporarily spikes in use.

### Security <!-- omit in toc -->
- Customer managed Customer Master Keys for encryption
  - Encryption at rest using customer managed CMKs in AWS Key Management Service
  - ElastiCache for Redis encrypts all data on disk, including service backups stored in S3 with your encryption key
- Modifying Redis Authentication Tokens
  - Before this feature, authentication token was set once only during creation and can't be changed
  - now allows rotation of token and modify authentication tokens without interrupting clients
  - Supported on encryption in-transit enabled clusters Redis 5.0.5 onwards
- Rename Commands
  - Redis 5.0.3 onwards

### Scalability <!-- omit in toc -->
- Online scale up and down
  - Fully online, cluster continues to serve reads and writes
- Reader endpoint for Cluster Model disabled

### fully-managed <!-- omit in toc -->
- Self-service security updates

---

## [AWS re:Invent 2019: Performing chaos engineering in a serverless world](https://youtu.be/vbyjpMeYitA)

😏The idea of building fault injection in Lambda with Lambda layer and Python decorator looks simple and interesting. I think I can apply this into our serverless applications.
- [Injecting Chaos to AWS Lambda functions using Lambda Layers](https://medium.com/@adhorn/injecting-chaos-to-aws-lambda-functions-using-lambda-layers-2963f996e0ba)
- [Injecting Chaos to AWS Lambda functions with Lambda Layers— RELOADED](https://medium.com/@adhorn/failure-injection-gain-confidence-in-your-serverless-application-ce6c0060f586)
🤔one of motiviations for chaos engineering should be better customer experience. I thought we needed to know what makes customers happy and what are the critical parts in our applications for that first. Then, we prioritize chaos experiments based on that.
🤔Sometimes DynamoDB had internal server errors. Applications returned error messages to clients even if it retried several times with exponential backoff in synchronous request response communication. I thought we might need to mock this situation and test applications with it. How can I mock this?
🤔fallbacks!! The application had a problem because a 3rd party tracking service was down. What fallback strategy should we have had for better customer experience?

### What is chaos engineering? <!-- omit in toc -->

> Chaos engineering is about performing controlled experiments to inject failure
> Chaos engineering is about finding the weaknesses in a system and fixing them before they break
> Chaos engineering is about building confidence in your system and in your organization

### Motivations behind chaos engineering <!-- omit in toc -->

- Are your customers getting the experience they should?
- Is downtime or issues costing you money?
- Are you confident in your monitoring and alerting?
- Is your organization ready to handle outages?
- Are you learning from incidents?

### Running chaos experiments <!-- omit in toc -->
1. Define steady state
   - The normal behavior of a system over time
   - System metrics and business metrics
   - Business metrics are usually more useful
   - Steady state is not necessarily continuous
2. Form your hypothesis
   - Use what ifs to find it
   - Chaos can be injected at any layer of the stack
   - Scientific "If... then..." method
   - Always fix known problems first
3. Plan and run your experiment
   - Whiteboard the experiment in detail
   - Contain the blast radius
   - Notify the organization
   - Have a "stop" button ready
4. Measure and learn
   - Use metrics to prove or disprove the hypothesis
   - Was the system resilient to the injected failure?
   - did anything unexpected happen?
   - Share your progress and success
5. Scale up or abort and fix
   - Use the learnings to improve
   - With confidence you can scale up
   - Increased scope can reveal new effects

### Common serverless weakness <!-- omit in toc -->
- Error handling
  - DLQ -> we don't have to handle errors in our code
- Timeout values
  - What if there is issue, not in steady status?
- Events
  - Do we handle events correctly? 
  - Do we queue events correctly?
  - What happens to events in case of service failures?
- Fallbacks
  - 3rd party service we use have problem?
- Failovers
  - Region outrages?
  - ISP abnormal latency?

---

## AWS re:Invent 2019: What's new in Amazon Aurora

- Aurora Global Database
    - subsecond data replication cross-Region
- Fast cross-account database cloining
- Aurora Serverless For PostgreSQL and MySQL
- RDS Proxy
  - Supports a large number of application connections
  - Deployed across multiple AZs and fails over without losing a connection
  - Integrates with AWS Secrets Manager and IAM
- Performance Insight
- Database Activity Streams
  - Available for Aurora PostgreSQL
- Aurora MySQL multi-master
- Federated Query For Amazon Athena(preview)
- Amazon Redshift federated query(preivew)
  - when your data ends up in different places and you don't want to always copy and ETL data back and forth all the time
  - Really old data in S3, little old data in Redshift and recent data in Aurora
  - At the moment, RDS and Aurora PostgreSQl support it

---

## AWS re:Invent 2019: Deep Dive on Amazon Aurora with MySQL Compatibility

🤔[proxysql](https://www.proxysql.com/) vs RDS proxy
- [proxysql: Aurora failover without losing connection](https://www.proxysql.com/blog/aurora-failover-without-losing-transactions)
- [proxysql: single endpoint for write and read](https://aws.amazon.com/blogs/database/how-to-use-proxysql-with-open-source-platforms-to-split-sql-reads-and-writes-on-amazon-aurora-clusters/)
- [pgpool: single endpoint for write and read](https://aws.amazon.com/blogs/database/a-single-pgpool-endpoint-for-reads-and-writes-with-amazon-aurora-postgresql/)

### Write quorum and Local tracking in action <!-- omit in toc -->

> database nodes have durability and commit tracker to make sure that everything has to achieve quorum before it acknowledge commit.

parallel flush but acknowledge in the order. (T1 4 out of 6, T2 3 out of 6, T3 4 out of 6 => After T2 achieves quorum and acknowledges commit back to client, T3 can be acknowledged)

### Read scale out <!-- omit in toc -->

| MysqL                         | Aurora                 |
| ----------------------------- | ---------------------- |
| Separate logical stream       | Reuses redo log stream |
| binlog apply                  | page cache update      |
| Same with workload on replica | No writes on replica   |
| Independent storage           | Shared storage         |

### Aurora Multi-Master Architecture page <!-- omit in toc -->

**Optimistic Conflict Resolution**

#### conflicting writes originating on different masters on the same table <!-- omit in toc -->

case 1 \
If two clients update the same row in the same table at the same time, one of clients who get a majority vote from storage nodes will commit and the other client will be rejected and rollback. The rejected client needs to retry.

case 2 \
If one client updates the row first and the other client tries to update the same row before being committed, it immediately fails and rollbacks. (MVCC)

### Parallel Query <!-- omit in toc -->

**parallel query is only available in the Aurora compatible with MySQL 5.6.**

rather bringing the entire table into the memory and then running a filter, it just gets filtered data back from distributed storage nodes.

reduce buffer pool pollution!

### Aurora read replica & Global database <!-- omit in toc -->

availiability zone fail => one of (upto 15) replicas across multiple AZ will be promoted

whole region fail => aurora global database
- Multi-Mirror support
- 5.7 support
- In-place upgrade support
- Extended to All Aurora regions

### Aurora ML integration <!-- omit in toc -->
1. select and train the ML models
2. Run a SQL query to invoke the ML service
3. Process the result in the application

### Amazon RDS Proxy(Preview) <!-- omit in toc -->
- pool and share connections for scaling applications with unpredictable workloads, high connection open rates, or idling connections
- Transparently tolerate transient failures without complex failure
    - If master goes down RDS proxy will hold the connection and redirect to the new master. Client side doesn't need to handle this kind of failure, just get higher lantency.
    - Recovery is fast but DNS propagation itself takes several tens seconds. This is actually a bottleneck in Aurora.
- Centralized credentials management with AWS Secrets Manager and optionally IAM authentication

### Customer success part <!-- omit in toc -->

- write scalability is top concern
- Horizontall partition user data

---

## AWS re:Invent 2019: Amazon Aurora storage demystified: How it all works

### Log is the database <!-- omit in toc -->

🤔Let's use Aurora clone to test services on beta environment.

Traditional MySQL needs much more I/O operations than Aurora because it needs operations such as transaction logging, doublewrite buffer and flushing. Aurora can construct any version of a database page with the log stream. Aurora just writes log records to the distributed storage and the distributed storage does the continuous checkpointing.

Read replicas have their own buffer pools. If something changes it need to update the buffer pools.

### leveraged other services <!-- omit in toc -->

Aurora leveraged serveral services in AWS. DynamoDB to store metadatas, Route53 for naming, EC2 instance and Amazon S3 for storing backups.

### I/O flow in Amazon Aurora storage node <!-- omit in toc -->
- All steps are asynchronous
- Only steps 1 and 2 are in the foreground latency path

1. Receiving log records and add to in-memory queue and durably persist log records(Hot log)
2. ACK to the database (1 and 2 are synchronous process. Database instance needs 4 ACK out of 6 storage nodes)
3. Organize records and identify gaps in log
4. Gossip with peers to fill in holes
5. Collesce log records into new page versions
6. Periodically stage log and new page versions to S3
7. Periodically garbage collect old versions
8. Periodically validate CRC (checksum validation) codes on blocks

### tolerance & write quorum of 4/6 <!-- omit in toc -->

There are copies in 6 storage nodes. each pair of storage nodes are in three different AZs. If an AZ fails, there are still 4 copies and it maintains write availability. If an AZ fails and one node fails in different AZ, there are 3 copies. It reconstructure remaing copy and recover write availability.

### 10GB protection group <!-- omit in toc -->

Replicate each segment 6 ways into a protection group.

> When the cluster is created, it consumes very little storage. As the volume of data increases and exceeds the currently allocated storage, Aurora seamlessly expands the volume to meet the demand and adds new protection groups, as necessary. Amazon Aurora continues to scale in this way until it reaches its current limit of 64 TB.

### Global database <!-- omit in toc -->

binlog replication doesn't scale well. Lag increases dramatically when it exceed specific QPS.

### Fast database cloning <!-- omit in toc -->

Creation of a clone is instantaneous because it doesn't require deep copy

### Database backtrack <!-- omit in toc -->

Backtrack is a quick way to bring the database to a particular point in time without having to restore from backups

---

## AWS re:Invent 2019: What's new in AWS CloudFormation

🤔[taskcat](https://github.com/aws-quickstart/taskcat) was not introduced in this session.
🤔I struggled to change a logical resource name without deleting the resource. I also can't refer to exisiting resources which are not in a stack like I did with Terraform data source. Resource import feature can be very helpful!
🤔Would I have a situation to use custom resources?

### Resource import <!-- omit in toc -->

Add resources to stacks without recreating them

#### refactoring resources in stacks <!-- omit in toc -->

Move a resource from Stack A to Stack B, non-destructively
- Update Stack A with a deletion policy = retain
- Remove resource from Stack A
- Import resource to Stack B

#### remediating drift <!-- omit in toc -->

If a resource's properties changed significantly outside of AWS CloudFormation
- Update deletion policy = retain
- Remove resource safely
- Import resource back, with all current states/properties

#### additional uses <!-- omit in toc -->
- Change a logical resource name when renaming requires replacement
- Import a single (non-nested) stack into another stack

[AWS News Blog about new feature resource import on the 13th of November 2019](https://aws.amazon.com/blogs/aws/new-import-existing-resources-into-a-cloudformation-stack/)

### StackSets enhancements <!-- omit in toc -->

- New drift detection for StackSets
- Increased limits
    - 20 -> 100 StackSets per admin account
    - 500 -> 2000 stack instances per StackSets

#### Integration with AWS Organizations (not launched yet but comming soon) <!-- omit in toc -->

Automation of multi-account and multi-region permissions management and deployment through AWS Organizations

**Permission Model** \
You had to create all necessary roles for cross-account deployment. new service-managed permissions can be used for accounts inside full service AWS Organization.

**Deployments to organization's root or oganization units**
You can deploy a stack to organization's root or stacks per OU.

**automatic deployments** \
If you add or remove an account in OU, It deploy or destroy automatically the stack to that account. The goal is to make the management of your multi accounts and multi region deployments as effortless as possible

### Programming scenarios <!-- omit in toc -->

**Core YAML/JSON**\
other transformations result in this format

**Macro/transform**\
AWS SAM, AWS Cloudformation, macros

**High-level language**\
AWS CDK

**custom resources**\
Call remote APIs, resources not supported yet, proxies to external resource

### [Linter](https://github.com/aws-cloudformation/cfn-python-lint) <!-- omit in toc -->
- supports AWS SAM
- supports linting as a GitHub action

**you can customize your linter**
- Require specific tags
- Blacklist of resource type (Can't create X resource type)
- Enforce/require a property
- Forbid a property value (Don't allow the creation of public buckets)

### AWS CDK <!-- omit in toc -->

Constructs(Source code) <-excuete- CDK CLI(Compiler) -synthesize-> Template -deploy-> Cloudformation(Processor) -provision-> Cloud

### native features <!-- omit in toc -->

**rollback trigger**\
You can specify the alarms and the thresholds you want AWS CloudFormation to monitor, and if any of the alarms are breached, CloudFormation rolls back the entire stack operation to the previous deployed state.

**change set**\

**stabilization**

### Nested stack <!-- omit in toc -->

As your infrastructure grows, common patterns can emerge in which you declare the same components in multiple templates. You can separate out these common components and create dedicated templates for them. Then use the resource in your template to reference other templates, creating nested stacks.

### AWS CloudFormation Registry & Cloudoformation CLI <!-- omit in toc -->

The CloudFormation Command Line Interface (CLI) is an open-source tool that enables you to develop and test AWS and third-party resources, and register them for use in AWS CloudFormation. 

---

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

---

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