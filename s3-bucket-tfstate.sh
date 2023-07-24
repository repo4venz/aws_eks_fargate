S3_BUCKET_NAME=$1
AWS_REGION=$2

  #"suvendu-terraform-state"
  #"eu-west-2"

bucketstatus=$(aws s3api head-bucket --bucket "${S3_BUCKET_NAME}" 2>&1)
if echo "${bucketstatus}" | grep 'Not Found';
then
  echo "S3 Bucket doesn't exist. Creating new bucket: ${S3_BUCKET_NAME}" ;
  aws s3api create-bucket --bucket ${S3_BUCKET_NAME} --create-bucket-configuration LocationConstraint=${AWS_REGION}
elif echo "${bucketstatus}" | grep 'Forbidden';
then
  echo "S3 Bucket exists but not owned."
elif echo "${bucketstatus}" | grep 'Bad Request';
then
  echo "S3 Bucket name specified is less than 3 or greater than 63 characters."
else
  echo "S3 Bucket owned and exists.";
fi

