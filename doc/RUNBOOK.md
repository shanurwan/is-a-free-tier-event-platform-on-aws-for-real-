## Prerequisite
1. Remote Terraform state (S3) with locking (DynamoDB)

S3 bucket holds the state file, DynamoDB table prevents two applies at once (locking).

2. AWS OIDC deploy role (no long-lived keys)

This is for our CI/CD authentication to automate terraform later 

3. Set a budget alert, a Free Tier alert, and plan to keep log retention short (7 days)

Prevent bill shock and log bloat while you learn. 


## Repo Layout

1. 