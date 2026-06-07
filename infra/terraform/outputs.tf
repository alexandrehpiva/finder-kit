output "bucket_name" {
  value = aws_s3_bucket.releases.bucket
}

output "github_release_role_arn" {
  value = aws_iam_role.github_release.arn
}
