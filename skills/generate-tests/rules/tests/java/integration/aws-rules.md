---
title: AWS Services Test Rules (S3, DynamoDB, SQS)
impact: HIGH
impactDescription: ensures proper testing of AWS services with LocalStack containers
tags: java, tests, integration, aws, s3, dynamodb, sqs, testcontainers, localstack
---

## AWS Services Test Rules

Use Testcontainers with LocalStackContainer for testing AWS services. Never mock AWS clients.

### Rules

- **MUST NOT** use `@SpringBootTest` or `MockitoExtension`
- **MUST** use `@Testcontainers` with `LocalStackContainer`
- Use `@Container` for static instance of container
- Isolate data per test using cleanup in `@AfterEach`
- Configure AWS clients to use LocalStack endpoint

**Incorrect:**

```java
// Mocking AWS clients - wrong!
@ExtendWith(MockitoExtension.class)
class S3ServiceTest {
    @Mock
    private S3Client s3Client;
}

// Using @SpringBootTest - too heavy
@SpringBootTest
class S3ServiceIT {
    // ...
}
```

**Correct:**

### S3 Test Template

```java
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.localstack.LocalStackContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.CreateBucketRequest;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Request;

import static org.assertj.core.api.Assertions.assertThat;
import static org.testcontainers.containers.localstack.LocalStackContainer.Service.S3;

@Testcontainers
class S3ServiceIT {

    @Container
    static final LocalStackContainer localstack = new LocalStackContainer(
            DockerImageName.parse("localstack/localstack:3.0"))
            .withServices(S3);

    private S3Client s3Client;
    private S3Service s3Service;

    @BeforeEach
    void setUp() {
        s3Client = S3Client.builder()
                .endpointOverride(localstack.getEndpointOverride(S3))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(localstack.getAccessKey(), localstack.getSecretKey())))
                .region(Region.of(localstack.getRegion()))
                .build();

        s3Client.createBucket(CreateBucketRequest.builder().bucket("test-bucket").build());
        s3Service = new S3Service(s3Client, "test-bucket");
    }

    @AfterEach
    void tearDown() {
        // Clean up all objects
        var objects = s3Client.listObjectsV2(ListObjectsV2Request.builder()
                .bucket("test-bucket").build());
        objects.contents().forEach(obj ->
                s3Client.deleteObject(DeleteObjectRequest.builder()
                        .bucket("test-bucket")
                        .key(obj.key())
                        .build()));
    }

    @Test
    void uploadFile_validContent_uploadsSuccessfully() {
        // When
        s3Service.uploadFile("test-key", "test content");

        // Then
        var objects = s3Client.listObjectsV2(ListObjectsV2Request.builder()
                .bucket("test-bucket").build());
        assertThat(objects.contents()).hasSize(1);
        assertThat(objects.contents().get(0).key()).isEqualTo("test-key");
    }

    @Test
    void downloadFile_existingKey_returnsContent() {
        // Given
        s3Service.uploadFile("test-key", "test content");

        // When
        String content = s3Service.downloadFile("test-key");

        // Then
        assertThat(content).isEqualTo("test content");
    }
}
```

### DynamoDB Test Template

```java
import org.testcontainers.containers.localstack.LocalStackContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.*;

import static org.testcontainers.containers.localstack.LocalStackContainer.Service.DYNAMODB;

@Testcontainers
class DynamoDbServiceIT {

    @Container
    static final LocalStackContainer localstack = new LocalStackContainer(
            DockerImageName.parse("localstack/localstack:3.0"))
            .withServices(DYNAMODB);

    private DynamoDbClient dynamoDbClient;
    private DynamoDbService dynamoDbService;

    @BeforeEach
    void setUp() {
        dynamoDbClient = DynamoDbClient.builder()
                .endpointOverride(localstack.getEndpointOverride(DYNAMODB))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(localstack.getAccessKey(), localstack.getSecretKey())))
                .region(Region.of(localstack.getRegion()))
                .build();

        // Create table
        dynamoDbClient.createTable(CreateTableRequest.builder()
                .tableName("test-table")
                .keySchema(KeySchemaElement.builder()
                        .attributeName("id")
                        .keyType(KeyType.HASH)
                        .build())
                .attributeDefinitions(AttributeDefinition.builder()
                        .attributeName("id")
                        .attributeType(ScalarAttributeType.S)
                        .build())
                .billingMode(BillingMode.PAY_PER_REQUEST)
                .build());

        dynamoDbService = new DynamoDbService(dynamoDbClient, "test-table");
    }

    @Test
    void putItem_validItem_savesSuccessfully() {
        // When
        dynamoDbService.putItem("item-1", "test value");

        // Then
        var result = dynamoDbClient.getItem(GetItemRequest.builder()
                .tableName("test-table")
                .key(Map.of("id", AttributeValue.builder().s("item-1").build()))
                .build());
        assertThat(result.item()).isNotEmpty();
    }
}
```

### SQS Test Template

```java
import org.testcontainers.containers.localstack.LocalStackContainer;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.*;

import static org.testcontainers.containers.localstack.LocalStackContainer.Service.SQS;

@Testcontainers
class SqsServiceIT {

    @Container
    static final LocalStackContainer localstack = new LocalStackContainer(
            DockerImageName.parse("localstack/localstack:3.0"))
            .withServices(SQS);

    private SqsClient sqsClient;
    private String queueUrl;
    private SqsService sqsService;

    @BeforeEach
    void setUp() {
        sqsClient = SqsClient.builder()
                .endpointOverride(localstack.getEndpointOverride(SQS))
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(localstack.getAccessKey(), localstack.getSecretKey())))
                .region(Region.of(localstack.getRegion()))
                .build();

        queueUrl = sqsClient.createQueue(CreateQueueRequest.builder()
                .queueName("test-queue")
                .build()).queueUrl();

        sqsService = new SqsService(sqsClient, queueUrl);
    }

    @Test
    void sendMessage_validMessage_sendsSuccessfully() {
        // When
        sqsService.sendMessage("test message");

        // Then
        var messages = sqsClient.receiveMessage(ReceiveMessageRequest.builder()
                .queueUrl(queueUrl)
                .maxNumberOfMessages(1)
                .build()).messages();
        assertThat(messages).hasSize(1);
        assertThat(messages.get(0).body()).isEqualTo("test message");
    }
}
```

### Key Points

1. Use `LocalStackContainer` with appropriate services
2. Configure AWS clients with LocalStack endpoint and credentials
3. Create resources (buckets, tables, queues) in `@BeforeEach`
4. Clean up data in `@AfterEach`
5. Use AWS SDK v2 for cleaner API