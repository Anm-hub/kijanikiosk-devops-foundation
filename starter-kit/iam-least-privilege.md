# Least Privilege IAM Policy Design

## Application Task Context

The KijaniKiosk platform allows vendors to upload product images that are displayed in the online marketplace. A dedicated **Product Image Processor & Catalog Service** automatically downloads uploaded images, generates thumbnail versions, and reads product information from the catalog database. Because this service performs only one specific task, it should receive only the permissions necessary to complete that responsibility.

Applying the **least privilege principle** reduces the impact of security breaches. If this service were compromised, an attacker would only have access to the limited resources defined in its IAM policy rather than the entire cloud environment.

## IAM Policy

\`\`\`json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3KijaniKioskMediaReadOnly",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::kijanikiosk-media-bucket",
        "arn:aws:s3:::kijanikiosk-media-bucket/products/*"
      ]
    },
    {
      "Sid": "S3KijaniKioskThumbnailsWrite",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::kijanikiosk-media-bucket/thumbnails/*"
      ]
    },
    {
      "Sid": "DynamoDBCatalogReadAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:BatchGetItem",
        "dynamodb:Query"
      ],
      "Resource": "arn:aws:dynamodb:af-south-1:123456789012:table/KijaniKiosk_Catalog"
    }
  ]
}
\`\`\`

## Why this policy follows least privilege

This policy grants only three categories of permissions. The service can **read product images** from the S3 media bucket, **write newly generated thumbnails** into the thumbnails folder, and **read catalog records** from the DynamoDB table. It cannot delete files, modify other database tables, manage IAM users, or administer cloud resources. Restricting permissions in this way improves security while allowing the application to perform its intended function.
