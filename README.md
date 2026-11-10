
# AWS – Novatrix AB

**Namn:** Farideh Dehghan

**Kurs:** Amazon Web Services

## Uppgift 1 (v42) – Compute och kom igång
Provisionering av en EC2-instans med Amazon Linux och driftsättning av en enkel webbserver för Novatrix AB.

## Uppgift 2 (v43) – IAM och identitet
Användare, grupper, policies och roller för Novatrix AB enligt least privilege, inklusive en IAM-roll som ger EC2-instansen läsbehörighet till en S3-bucket.
## Uppgift 3 (v44) – Nätverk och säkerhet
Ett eget VPC för Novatrix AB med publikt och privat subnät, route tables och internet gateway. Defense in depth med security groups och NACL:er. Webbservern ligger i det publika subnätet och det privata subnätet är förberett för databasen.
## Uppgift 4 (v45) – Storage och databas
WordPress för Novatrix AB med en hanterad databas (Amazon RDS, MariaDB) i privata subnät, delad lagring (Amazon EFS) för WordPress-filerna och objektlagring (Amazon S3) för backup. Databasen nås bara från webbservern och backuper i S3 tas bort automatiskt efter 14 dagar.
