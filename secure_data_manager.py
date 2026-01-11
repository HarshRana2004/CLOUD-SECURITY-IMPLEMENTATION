import boto3
import json
from botocore.exceptions import ClientError

class SecureDataManager:
    def __init__(self, bucket_name, kms_key_id, region='us-east-1'):
        self.bucket_name = bucket_name
        self.kms_key_id = kms_key_id
        self.s3_client = boto3.client('s3', region_name=region)
        self.kms_client = boto3.client('kms', region_name=region)
    
    def upload_encrypted_file(self, file_path, s3_key):
        """Upload file with KMS encryption"""
        try:
            self.s3_client.upload_file(
                file_path, 
                self.bucket_name, 
                s3_key,
                ExtraArgs={
                    'ServerSideEncryption': 'aws:kms',
                    'SSEKMSKeyId': self.kms_key_id
                }
            )
            print(f"File {file_path} uploaded successfully with encryption")
        except ClientError as e:
            print(f"Error uploading file: {e}")
    
    def download_encrypted_file(self, s3_key, local_path):
        """Download and decrypt file"""
        try:
            self.s3_client.download_file(self.bucket_name, s3_key, local_path)
            print(f"File {s3_key} downloaded successfully")
        except ClientError as e:
            print(f"Error downloading file: {e}")
    
    def encrypt_data(self, plaintext_data):
        """Encrypt data using KMS"""
        try:
            response = self.kms_client.encrypt(
                KeyId=self.kms_key_id,
                Plaintext=plaintext_data
            )
            return response['CiphertextBlob']
        except ClientError as e:
            print(f"Error encrypting data: {e}")
            return None
    
    def decrypt_data(self, encrypted_data):
        """Decrypt data using KMS"""
        try:
            response = self.kms_client.decrypt(CiphertextBlob=encrypted_data)
            return response['Plaintext']
        except ClientError as e:
            print(f"Error decrypting data: {e}")
            return None

if __name__ == "__main__":
    # Example usage
    bucket_name = "secure-data-bucket-example"
    kms_key_id = "alias/s3-encryption-key"
    
    manager = SecureDataManager(bucket_name, kms_key_id)
    
    # Example: Encrypt sensitive data
    sensitive_data = "This is sensitive information"
    encrypted = manager.encrypt_data(sensitive_data.encode())
    
    if encrypted:
        print("Data encrypted successfully")
        decrypted = manager.decrypt_data(encrypted)
        print(f"Decrypted data: {decrypted.decode()}")