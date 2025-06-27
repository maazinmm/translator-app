# Translator App using Amazon Translate

This serverless project automatically translates text between languages using **Amazon S3**, **AWS Lambda**, and **Amazon Translate**, all deployed using **Terraform**.

---

## Architecture Diagram

![Amazon_Translate (1)](https://github.com/user-attachments/assets/aff9fab4-6e9d-44ab-bb47-2749606e0644)

---

## How It Works

1. User uploads a `.json` file with original text and source/target languages to the **input S3 bucket**.
2. The upload **triggers a Lambda function**, which:
   - Parses the file
   - Uses **Amazon Translate** to translate the text
   - Uploads the translated result to an **output S3 bucket**
3. The result is stored in the format:
```json
{
    "original": "Hello world",
    "translated": "Bonjour le monde",
    "source": "en",
    "target": "fr"
}
```

---

## 📁 Project Structure

```
translator-app/
├── lambda/
│   └── handler.py           # Python Lambda function (Boto3 + Translate)
├── main.tf                  # Terraform config (S3, Lambda, IAM)
├── README.md                # Project documentation
```

---

## Requirements

- Terraform ≥ 1.12.2
- AWS CLI configured (`aws configure`)
- Python 3.13.3 + Boto3 (for local testing, optional)

---

## Deploy with Terraform

```bash
cd translator-app
terraform init
terraform plan
terraform apply
```

This will create:

- Input S3 bucket
- Output S3 bucket
- Lambda function with trigger
- Required IAM permissions

---

## Sample Lambda (handler.py)

```python
import boto3
import json

translate = boto3.client('translate')
s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    obj = s3.get_object(Bucket=bucket, Key=key)
    data = json.loads(obj['Body'].read())

    result = translate.translate_text(
        Text=data['text'],
        SourceLanguageCode=data['source'],
        TargetLanguageCode=data['target']
    )

    output = {
        "translated": result['TranslatedText']
    }

    output_bucket = "your-output-bucket-name"
    output_key = key.replace(".json", "-translated.json")
    s3.put_object(
        Bucket=output_bucket,
        Key=output_key,
        Body=json.dumps(output).encode("utf-8")
    )

    return { "status": "done", "output_key": output_key }
```

---

## Example Input File (upload to input bucket)

```json
{
  "text": "Hello world",
  "source": "en",
  "target": "fr"
}
```

---

## License

MIT License
