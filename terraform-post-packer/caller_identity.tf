# Use aws_caller_identity with the default provider (Images account)
# so we can provide the Images account ID below
data "aws_caller_identity" "images" {
}
